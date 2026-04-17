import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/client_profile.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.sessionController});

  final SessionController sessionController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _emailController;
  late final FocusNode _emailFocusNode;

  bool _isSaving = false;
  bool _isEditingEmail = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.sessionController.client?.email ?? '',
    );
    _emailFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    if (value.trim().isEmpty) {
      return true;
    }

    final RegExp regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value.trim());
  }

  String _extractErrorMessage(Object error, String fallback) {
    if (error is DioException) {
      final dynamic data = error.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
    }
    return fallback;
  }

  void _startEditingEmail() {
    final String currentEmail = widget.sessionController.client?.email ?? '';

    setState(() {
      _isEditingEmail = true;
      _emailError = null;
      _emailController.text = currentEmail;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _emailFocusNode.requestFocus();
    });
  }

  void _cancelEditingEmail() {
    _emailFocusNode.unfocus();

    setState(() {
      _isEditingEmail = false;
      _emailError = null;
      _emailController.text = widget.sessionController.client?.email ?? '';
    });
  }

  Future<void> _saveEmail() async {
    _emailFocusNode.unfocus();

    final String email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Введите корректный email';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _emailError = null;
    });

    try {
      await widget.sessionController.updateEmail(email.isEmpty ? null : email);

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditingEmail = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email сохранён')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _emailError = _extractErrorMessage(error, 'Не удалось сохранить email');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showInfoMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _statusText(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return 'Активен';
      case 'blocked':
        return 'Заблокирован';
      case 'deleted':
        return 'Удалён';
      default:
        return AppFormatters.fallback(status);
    }
  }

  String _createdViaText(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'telegram':
        return 'Telegram';
      case 'email':
        return 'Email';
      case 'merged':
        return 'Telegram + email';
      case 'admin':
        return 'Администратор';
      default:
        return AppFormatters.fallback(value);
    }
  }

  String _languageText(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return AppFormatters.fallback(value);
    }
  }

  String _heroTitle(ClientProfile? client) {
    if (client?.isActive == true && client?.isPaid == true) {
      return 'Личный кабинет Freeth';
    }
    if (client?.isActive == true) {
      return 'Доступ активен';
    }
    return 'Профиль Freeth';
  }

  String _heroSubtitle(ClientProfile? client) {
    if (client?.isActive == true && client?.isPaid == true) {
      return 'Управляйте аккаунтом, устройствами и подпиской из одного места.';
    }
    if (client?.isActive == true) {
      return 'Аккаунт уже активен. Проверьте устройства, подписку и контактные данные.';
    }
    return 'Здесь собраны ваши данные аккаунта, контактные настройки и управление доступом.';
  }

  @override
  Widget build(BuildContext context) {
    final ClientProfile? client = widget.sessionController.client;

    final String fullName = (client?.fullName?.trim().isNotEmpty == true)
        ? client!.fullName!
        : 'Пользователь';

    final String telegramId = AppFormatters.fallback(client?.telegramId);
    final String accessId = AppFormatters.fallback(
      client?.login,
      empty: 'не указан',
    );
    final String currentEmail = client?.email?.trim() ?? '';
    final bool hasEmail = currentEmail.isNotEmpty;

    final bool isActive = client?.isActive == true;
    final bool isPaid = client?.isPaid == true;
    final String paidUntil = AppFormatters.dateTime(client?.paidUntil);
    final String statusText = _statusText(client?.status);
    final String createdVia = _createdViaText(client?.createdVia);
    final String language = _languageText(client?.defaultLanguage);
    final String publicId = AppFormatters.fallback(client?.publicId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Подписка',
            onPressed: () => context.go('/subscription'),
            icon: const Icon(Icons.workspace_premium_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              _HeroCard(
                title: _heroTitle(client),
                subtitle: _heroSubtitle(client),
                isActive: isActive,
                isPaid: isPaid,
                onDevices: () => context.go('/devices'),
                onSubscription: () => context.go('/subscription'),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Аккаунт',
                subtitle:
                    'Основная информация о вашем профиле Freeth и текущем статусе доступа.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          StatusBadge(
                            label: isActive
                                ? 'Аккаунт активен'
                                : 'Аккаунт не активен',
                            isPositive: isActive,
                          ),
                          StatusBadge(
                            label: isPaid
                                ? 'Подписка оплачена'
                                : isActive
                                ? 'Доступ без оплаты'
                                : 'Подписка не активна',
                            isPositive: isPaid || isActive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: 'Имя', value: fullName),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Telegram ID', value: telegramId),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'ID доступа', value: accessId),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Public ID', value: publicId),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Статус', value: statusText),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Доступ до', value: paidUntil),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Язык', value: language),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Создан через', value: createdVia),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Контактные данные',
                subtitle:
                    'Email используется для входа в приложение, восстановления доступа и уведомлений.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!_isEditingEmail) ...<Widget>[
                        Text(
                          hasEmail
                              ? 'Сейчас используется: $currentEmail'
                              : 'Email пока не привязан. Добавьте его, чтобы использовать альтернативный вход и получать уведомления.',
                          style: const TextStyle(height: 1.45),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: _startEditingEmail,
                              icon: const Icon(Icons.alternate_email_rounded),
                              label: Text(
                                hasEmail ? 'Изменить email' : 'Привязать email',
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showInfoMessage(
                                'Позже здесь можно добавить подтверждение email и дополнительные уведомления.',
                              ),
                              child: const Text('Подробнее'),
                            ),
                          ],
                        ),
                      ] else ...<Widget>[
                        const Text(
                          'Введите новый email и сохраните изменения.',
                          style: TextStyle(height: 1.45),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'name@example.com',
                            errorText: _emailError,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            FilledButton(
                              onPressed: _isSaving ? null : _saveEmail,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Сохранить'),
                            ),
                            TextButton(
                              onPressed: _isSaving ? null : _cancelEditingEmail,
                              child: const Text('Отмена'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Управление доступом',
                subtitle:
                    'Быстрые действия по подписке, устройствам и состоянию аккаунта.',
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool compact = constraints.maxWidth < 560;

                  return GridView.count(
                    crossAxisCount: compact ? 1 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: compact ? 2.4 : 1.9,
                    children: <Widget>[
                      _ActionCard(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Подписка',
                        subtitle:
                            'Посмотреть срок действия и перейти к продлению доступа.',
                        onTap: () => context.go('/subscription'),
                      ),
                      _ActionCard(
                        icon: Icons.devices_other_rounded,
                        title: 'Устройства',
                        subtitle:
                            'Управление подключёнными устройствами и лимитами.',
                        onTap: () => context.go('/devices'),
                      ),
                      _ActionCard(
                        icon: Icons.shield_outlined,
                        title: 'Доступ',
                        subtitle:
                            'Открыть экран подключения и посмотреть локации.',
                        onTap: () => context.go('/access'),
                      ),
                      _ActionCard(
                        icon: Icons.logout_rounded,
                        title: 'Выйти',
                        subtitle: 'Завершить сессию на этом устройстве.',
                        onTap: () => widget.sessionController.logout(),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Бонусы Freeth',
                subtitle:
                    'Рефералы, бонусные дни и промокоды можно развивать как отдельную часть продукта.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Преимущества аккаунта',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _BulletLine(
                        text:
                            'Реферальная программа уже поддерживается в экосистеме Freeth и может быть вынесена в приложение отдельным экраном.',
                      ),
                      const SizedBox(height: 8),
                      const _BulletLine(
                        text:
                            'Бонусные дни, промокоды и персональные предложения логично показывать здесь, не смешивая их с настройками подключения.',
                      ),
                      const SizedBox(height: 8),
                      const _BulletLine(
                        text:
                            'Этот раздел можно развивать как “преимущества аккаунта”, а не как копию чужого VPN-приложения.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Поддержка и документы',
                subtitle:
                    'Важные ссылки и базовые действия, которые не должны теряться в интерфейсе.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _SettingsLikeTile(
                        icon: Icons.support_agent_rounded,
                        title: 'Поддержка',
                        subtitle:
                            'Связь с поддержкой Freeth и помощь по подключению.',
                        onTap: () => _showInfoMessage(
                          'Позже здесь можно открыть Telegram-поддержку или встроенный канал связи.',
                        ),
                      ),
                      const Divider(height: 24),
                      _SettingsLikeTile(
                        icon: Icons.description_outlined,
                        title: 'Пользовательское соглашение',
                        subtitle: 'Открыть юридический документ.',
                        onTap: () => context.push('/legal/user-agreement'),
                      ),
                      const Divider(height: 24),
                      _SettingsLikeTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Политика конфиденциальности',
                        subtitle: 'Посмотреть политику обработки данных.',
                        onTap: () => context.push('/legal/privacy'),
                      ),
                      const Divider(height: 24),
                      _SettingsLikeTile(
                        icon: Icons.payments_outlined,
                        title: 'Политика возвратов',
                        subtitle: 'Правила возврата и условий оплаты.',
                        onTap: () => context.push('/legal/refund'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => widget.sessionController.logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Выйти из аккаунта'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isPaid,
    required this.onDevices,
    required this.onSubscription,
  });

  final String title;
  final String subtitle;
  final bool isActive;
  final bool isPaid;
  final VoidCallback onDevices;
  final VoidCallback onSubscription;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            scheme.primaryContainer,
            scheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              StatusBadge(
                label: isActive ? 'Аккаунт активен' : 'Нужна активация',
                isPositive: isActive,
              ),
              StatusBadge(
                label: isPaid ? 'Подписка оплачена' : 'Проверьте подписку',
                isPositive: isPaid || isActive,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(subtitle, style: const TextStyle(fontSize: 16, height: 1.45)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.icon(
                onPressed: onSubscription,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Подписка'),
              ),
              OutlinedButton.icon(
                onPressed: onDevices,
                icon: const Icon(Icons.devices_other_rounded),
                label: const Text('Устройства'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: TextStyle(
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsLikeTile extends StatelessWidget {
  const _SettingsLikeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    height: 1.35,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('• '),
        Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
