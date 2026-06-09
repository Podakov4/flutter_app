import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/client_profile.dart';
import '../../../core/models/connection_mode.dart';
import '../../../core/models/connection_state.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/freeth_hero_card.dart';
import '../../../shared/widgets/freeth_info_row.dart';
import '../../../shared/widgets/freeth_section_title.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../access/application/connection_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.sessionController,
    required this.connectionController,
  });

  final SessionController sessionController;
  final ConnectionController connectionController;

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

  Future<void> _copyProfileSummary(
    BuildContext context,
    ClientProfile? client,
  ) async {
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

    await Clipboard.setData(ClipboardData(text: summary));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Сводка профиля скопирована')));
  }

  void _showInfo(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        sessionController,
        connectionController,
      ]),
      builder: (BuildContext context, _) {
        final ClientProfile? client = sessionController.client;

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
                  FreethHeroCard(
                    title: 'Настройки Freeth',
                    subtitle:
                        'Основные настройки подключения, профиля и поддержки.',
                    badges: <Widget>[
                      StatusBadge(
                        label: isActive ? 'Freeth готов' : 'Нужна активация',
                        isPositive: isActive,
                      ),
                      StatusBadge(
                        label: isPaid
                            ? 'Подписка активна'
                            : 'Проверьте подписку',
                        isPositive: isPaid || isActive,
                      ),
                      StatusBadge(
                        label: connectionController.mode.label,
                        isPositive: true,
                      ),
                    ],
                    actions: <Widget>[
                      FilledButton.icon(
                        onPressed: () => context.go('/profile'),
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Профиль'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/subscription'),
                        icon: const Icon(Icons.workspace_premium_outlined),
                        label: const Text('Подписка'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const FreethSectionTitle(
                    title: 'Подключение',
                    subtitle:
                        'Настройте, как Freeth ведёт себя при смене сети и ошибках.',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: <Widget>[
                        SwitchListTile.adaptive(
                          title: const Text('Умный режим Freeth'),
                          subtitle: const Text(
                            'Freeth сам выбирает подходящий маршрут. При отключении локация выбирается вручную.',
                          ),
                          value:
                              connectionController.mode == ConnectionMode.smart,
                          onChanged: (bool value) {
                            if (value) {
                              connectionController.setSmartMode();
                            } else {
                              connectionController.setManualMode();
                            }
                          },
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          title: const Text('Автопереключение при смене сети'),
                          subtitle: const Text(
                            'Если сеть меняется во время активного подключения, Freeth сможет мягко переподключиться.',
                          ),
                          value: connectionController.autoSwitchOnNetworkChange,
                          onChanged:
                              connectionController.setAutoSwitchOnNetworkChange,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          title: const Text('Разрешить резервный маршрут'),
                          subtitle: const Text(
                            'Freeth сможет попробовать запасной маршрут, если основной недоступен.',
                          ),
                          value: connectionController.fallbackEnabled,
                          onChanged: connectionController.setFallbackEnabled,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          title: const Text('Подробный журнал'),
                          subtitle: const Text(
                            'Сохранять и показывать более подробные события подключения.',
                          ),
                          value: connectionController.showDetailedLogs,
                          onChanged: connectionController.setShowDetailedLogs,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FreethSectionTitle(
                    title: 'Текущее состояние',
                    subtitle:
                        'Короткая инженерная сводка по тому, что сейчас делает Freeth.',
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
                                label: connectionController.status.label,
                                isPositive:
                                    connectionController.status.isPositive,
                              ),
                              StatusBadge(
                                label: connectionController.canConnect
                                    ? 'Доступ готов'
                                    : 'Нужна активация',
                                isPositive: connectionController.canConnect,
                              ),
                              StatusBadge(
                                label: connectionController.subscriptionActive
                                    ? 'Подписка активна'
                                    : 'Проверьте подписку',
                                isPositive:
                                    connectionController.subscriptionActive ||
                                    connectionController.canConnect,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FreethInfoRow(
                            label: 'Локация',
                            value: connectionController.currentLocationTitle,
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Маршрут',
                            value: connectionController.currentLocationSubtitle,
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Сеть',
                            value: connectionController.networkLabel,
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Порт',
                            value: connectionController.localPort.toString(),
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Сбои',
                            value: connectionController.healthFailures
                                .toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FreethSectionTitle(
                    title: 'Аккаунт и доступ',
                    subtitle:
                        'Ключевые параметры вашего Freeth-аккаунта в одном блоке.',
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
                          FreethInfoRow(label: 'Email', value: email),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Telegram ID',
                            value: telegramId,
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(label: 'Public ID', value: publicId),
                          const SizedBox(height: 8),
                          FreethInfoRow(label: 'ID доступа', value: accessId),
                          const SizedBox(height: 8),
                          FreethInfoRow(label: 'Статус', value: status),
                          const SizedBox(height: 8),
                          FreethInfoRow(label: 'Доступ до', value: paidUntil),
                          const SizedBox(height: 8),
                          FreethInfoRow(label: 'Язык', value: language),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Создан через',
                            value: createdVia,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FreethSectionTitle(
                    title: 'Быстрые разделы',
                    subtitle:
                        'Переходы к важным экранам приложения без перегруза интерфейса.',
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
                                'Личный кабинет, email и управление аккаунтом.',
                            onTap: () => context.go('/profile'),
                          ),
                          const Divider(height: 24),
                          _NavTile(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Подписка',
                            subtitle: 'Статус доступа и продление.',
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
                                'Локации, режим, журнал и технические данные.',
                            onTap: () => context.go('/access'),
                          ),
                          const Divider(height: 24),
                          _NavTile(
                            icon: Icons.grid_view_rounded,
                            title: 'VPN для приложений',
                            subtitle:
                                'Выберите, какие приложения используют Freeth VPN.',
                            onTap: () => context.push('/split-tunnel'),
                          ),
                          const Divider(height: 24),
                          _NavTile(
                            icon: Icons.notes_rounded,
                            title: 'Журнал подключения',
                            subtitle:
                                'Полный экран событий подключения и восстановления канала.',
                            onTap: () => context.go('/logs'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FreethSectionTitle(
                    title: 'Поддержка и прозрачность',
                    subtitle:
                        'Freeth должен быть не только удобным, но и понятным.',
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
                              context,
                              'Здесь можно будет открыть поддержку Freeth.',
                            ),
                          ),
                          const Divider(height: 24),
                          _NavTile(
                            icon: Icons.copy_all_outlined,
                            title: 'Скопировать сведения о профиле',
                            subtitle: 'Удобно для поддержки и диагностики.',
                            onTap: () => _copyProfileSummary(context, client),
                          ),
                          const Divider(height: 24),
                          _NavTile(
                            icon: Icons.warning_amber_rounded,
                            title: 'Тест сбоя канала',
                            subtitle:
                                'Искусственно добавить health-failure в контроллер.',
                            onTap: () =>
                                connectionController.registerHealthFailure(),
                          ),
                          const Divider(height: 24),
                          _NavTile(
                            icon: Icons.health_and_safety_outlined,
                            title: 'Тест восстановления канала',
                            subtitle:
                                'Сбросить деградацию и отметить канал как восстановленный.',
                            onTap: () =>
                                connectionController.registerHealthSuccess(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FreethSectionTitle(
                    title: 'Документы',
                    subtitle:
                        'Юридические материалы должны быть доступны из настроек.',
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
                      onPressed: () => sessionController.logout(),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Выйти из аккаунта'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
