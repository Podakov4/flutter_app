import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/client_profile.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.sessionController});

  final SessionController sessionController;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _smartModeEnabled = true;
  bool _autoSwitchOnNetworkChange = true;
  bool _fallbackEnabled = true;
  bool _showDetailedLogs = true;

  void _showInfo(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

  @override
  Widget build(BuildContext context) {
    final ClientProfile? client = widget.sessionController.client;

    final bool isActive = client?.isActive == true;
    final bool isPaid = client?.isPaid == true;

    final String email = AppFormatters.fallback(
      client?.email,
      empty: 'не указан',
    );
    final String telegramId = AppFormatters.fallback(client?.telegramId);
    final String publicId = AppFormatters.fallback(client?.publicId);
    final String accessId = AppFormatters.fallback(
      client?.login,
      empty: 'не указан',
    );
    final String paidUntil = AppFormatters.dateTime(client?.paidUntil);
    final String language = _languageText(client?.defaultLanguage);
    final String status = _statusText(client?.status);
    final String createdVia = _createdViaText(client?.createdVia);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              _HeroCard(
                isActive: isActive,
                isPaid: isPaid,
                onOpenProfile: () => context.go('/profile'),
                onOpenSubscription: () => context.go('/subscription'),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Поведение подключения',
                subtitle:
                    'Настройки будущего “умного” режима Freeth. Уже сейчас можно заложить правильную структуру экрана, а логику подключить постепенно.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: <Widget>[
                    SwitchListTile.adaptive(
                      title: const Text('Умный режим Freeth'),
                      subtitle: const Text(
                        'Приложение сможет само выбирать лучший маршрут и помогать при нестабильной сети.',
                      ),
                      value: _smartModeEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _smartModeEnabled = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      title: const Text('Автопереключение при смене сети'),
                      subtitle: const Text(
                        'Подготовка к реакции на Wi-Fi / мобильную сеть без лишних действий со стороны пользователя.',
                      ),
                      value: _autoSwitchOnNetworkChange,
                      onChanged: (bool value) {
                        setState(() {
                          _autoSwitchOnNetworkChange = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      title: const Text('Разрешить резервный маршрут'),
                      subtitle: const Text(
                        'Если основной канал деградирует, Freeth сможет переключиться на запасной сценарий.',
                      ),
                      value: _fallbackEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _fallbackEnabled = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      title: const Text('Показывать подробный журнал'),
                      subtitle: const Text(
                        'Полезно для диагностики и поддержки. Позже можно будет открыть отдельный экран журнала.',
                      ),
                      value: _showDetailedLogs,
                      onChanged: (bool value) {
                        setState(() {
                          _showDetailedLogs = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Аккаунт и доступ',
                subtitle:
                    'Здесь собраны ключевые параметры вашего профиля и состояние Freeth-аккаунта.',
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
                                : 'Подписка не активна',
                            isPositive: isPaid || isActive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: 'Email', value: email),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Telegram ID', value: telegramId),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Public ID', value: publicId),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'ID доступа', value: accessId),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Статус', value: status),
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
                title: 'Быстрые разделы',
                subtitle:
                    'Переходы к важным частям приложения без перегруженного интерфейса.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _NavTile(
                        icon: Icons.person_outline_rounded,
                        title: 'Профиль',
                        subtitle:
                            'Email, данные аккаунта и личный кабинет Freeth.',
                        onTap: () => context.go('/profile'),
                      ),
                      const Divider(height: 24),
                      _NavTile(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Подписка',
                        subtitle: 'Статус доступа, срок действия и продление.',
                        onTap: () => context.go('/subscription'),
                      ),
                      const Divider(height: 24),
                      _NavTile(
                        icon: Icons.devices_other_rounded,
                        title: 'Устройства',
                        subtitle:
                            'Управление подключёнными устройствами и лимитами.',
                        onTap: () => context.go('/devices'),
                      ),
                      const Divider(height: 24),
                      _NavTile(
                        icon: Icons.public_rounded,
                        title: 'Подключение',
                        subtitle:
                            'Локации, доступ и технические данные подключения.',
                        onTap: () => context.go('/access'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Поддержка и прозрачность',
                subtitle:
                    'Freeth должен быть не только удобным, но и понятным пользователю.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _NavTile(
                        icon: Icons.support_agent_rounded,
                        title: 'Поддержка',
                        subtitle:
                            'Позже здесь можно открыть Telegram-поддержку или встроенный канал связи.',
                        onTap: () => _showInfo(
                          'Здесь можно будет открыть поддержку Freeth.',
                        ),
                      ),
                      const Divider(height: 24),
                      _NavTile(
                        icon: Icons.article_outlined,
                        title: 'Журнал подключения',
                        subtitle:
                            'Следующий логичный шаг — отдельный экран журнала с событиями подключения.',
                        onTap: () => _showInfo(
                          'Журнал подключения лучше вынести в отдельный экран следующим этапом.',
                        ),
                      ),
                      const Divider(height: 24),
                      _NavTile(
                        icon: Icons.copy_all_outlined,
                        title: 'Скопировать сведения о профиле',
                        subtitle:
                            'Удобно для поддержки и диагностики без лишнего шума.',
                        onTap: () {
                          final String summary =
                              '''
Freeth profile
Public ID: $publicId
Telegram ID: $telegramId
Access ID: $accessId
Email: $email
Status: $status
Paid until: $paidUntil
Language: $language
Created via: $createdVia
''';
                          _showInfo('Сводка профиля готова для копирования');
                          Clipboard.setData(ClipboardData(text: summary));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionTitle(
                title: 'Документы',
                subtitle:
                    'Юридические материалы должны быть доступны из настроек, а не спрятаны глубоко в приложении.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _NavTile(
                        icon: Icons.description_outlined,
                        title: 'Пользовательское соглашение',
                        subtitle: 'Открыть документ.',
                        onTap: () => context.push('/legal/user-agreement'),
                      ),
                      const Divider(height: 24),
                      _NavTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Политика конфиденциальности',
                        subtitle: 'Открыть документ.',
                        onTap: () => context.push('/legal/privacy'),
                      ),
                      const Divider(height: 24),
                      _NavTile(
                        icon: Icons.payments_outlined,
                        title: 'Политика возвратов',
                        subtitle: 'Открыть документ.',
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
    required this.isActive,
    required this.isPaid,
    required this.onOpenProfile,
    required this.onOpenSubscription,
  });

  final bool isActive;
  final bool isPaid;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSubscription;

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
                label: isActive ? 'Freeth готов' : 'Нужна активация',
                isPositive: isActive,
              ),
              StatusBadge(
                label: isPaid ? 'Подписка активна' : 'Проверьте подписку',
                isPositive: isPaid || isActive,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Настройки Freeth',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Здесь можно управлять поведением приложения, открыть ключевые разделы и подготовить Freeth к более “умному” сценарию работы без копирования чужих клиентов.',
            style: TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.icon(
                onPressed: onOpenProfile,
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('Профиль'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenSubscription,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: const Text('Подписка'),
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

class _NavTile extends StatelessWidget {
  const _NavTile({
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
