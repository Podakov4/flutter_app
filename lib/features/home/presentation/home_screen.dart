import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/client_profile.dart';
import '../../../core/models/connection_mode.dart';
import '../../../core/models/connection_state.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../access/application/connection_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.sessionController,
    required this.connectionController,
  });

  final SessionController sessionController;
  final ConnectionController connectionController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.connectionController.access == null &&
        !widget.connectionController.isLoading) {
      widget.connectionController.loadAccess();
    }
  }

  String _subscriptionLabel(ClientProfile? client) {
    if (client?.isActive == true && client?.isPaid == true) {
      return 'Подписка активна';
    }
    if (client?.isActive == true) {
      return 'Доступ активен';
    }
    return 'Доступ не активен';
  }

  String _heroTitle(ClientProfile? client) {
    if (client?.isActive == true && client?.isPaid == true) {
      return 'Freeth готов к работе';
    }
    if (client?.isActive == true) {
      return 'Доступ уже активен';
    }
    return 'Подключите Freeth';
  }

  String _heroSubtitle(ClientProfile? client) {
    if (client?.isActive == true && client?.isPaid == true) {
      return 'Управляйте локацией, режимом и состоянием подключения из одного места.';
    }
    if (client?.isActive == true) {
      return 'Проверьте подключение, выберите локацию и начните работу.';
    }
    return 'Сначала проверьте подписку и подготовьте подключение в пару нажатий.';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        widget.sessionController,
        widget.connectionController,
      ]),
      builder: (BuildContext context, _) {
        final ClientProfile? client = widget.sessionController.client;
        final connection = widget.connectionController;

        final String fullName = (client?.fullName?.trim().isNotEmpty == true)
            ? client!.fullName!
            : 'Пользователь';

        final String email = AppFormatters.fallback(
          client?.email,
          empty: 'не указан',
        );
        final String paidUntil = AppFormatters.dateTime(client?.paidUntil);

        final bool isActive = client?.isActive == true;
        final bool isPaid = client?.isPaid == true;

        final ConnectionStatus status = connection.status;
        final ConnectionMode mode = connection.mode;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Freeth'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Профиль',
                onPressed: () => context.go('/profile'),
                icon: const Icon(Icons.account_circle_outlined),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  children: <Widget>[
                    _HeroCard(
                      title: _heroTitle(client),
                      subtitle: _heroSubtitle(client),
                      isActive: isActive,
                      isPaid: isPaid,
                      connectionStatus: status,
                      onMainAction: !connection.canConnect || connection.isBusy
                          ? null
                          : () {
                              if (connection.isConnected) {
                                connection.disconnect();
                              } else {
                                connection.connect();
                              }
                            },
                      onSecondaryAction: () => context.go('/access'),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      title: 'Сейчас в Freeth',
                      subtitle:
                          'Главный экран показывает не только профиль, но и живое состояние подключения.',
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
                                  label: status.label,
                                  isPositive: status.isPositive,
                                ),
                                StatusBadge(
                                  label: _subscriptionLabel(client),
                                  isPositive: isPaid || isActive,
                                ),
                                StatusBadge(
                                  label: mode.label,
                                  isPositive: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _InfoRow(
                              label: 'Локация',
                              value: connection.currentLocationTitle,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Маршрут',
                              value: connection.currentLocationSubtitle,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Сеть',
                              value: connection.networkLabel,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Порт',
                              value: connection.localPort.toString(),
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(label: 'Доступ до', value: paidUntil),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      title: 'Режим Freeth',
                      subtitle:
                          'Не просто список серверов, а понятный сценарий подключения.',
                    ),
                    const SizedBox(height: 12),
                    _ModeCard(
                      title: mode.label,
                      subtitle: mode.subtitle,
                      icon: mode == ConnectionMode.smart
                          ? Icons.auto_awesome_rounded
                          : Icons.public_rounded,
                      onToggle: () {
                        if (mode == ConnectionMode.smart) {
                          connection.setManualMode();
                        } else {
                          connection.setSmartMode();
                        }
                      },
                      toggleLabel: mode == ConnectionMode.smart
                          ? 'Переключить на ручной'
                          : 'Переключить на умный',
                    ),
                    const SizedBox(height: 16),
                    _SectionTitle(
                      title: 'Быстрые действия',
                      subtitle:
                          'Основные сценарии без перегруженного интерфейса.',
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
                              icon: Icons.power_settings_new_rounded,
                              title: 'Подключение',
                              subtitle:
                                  'Локации, режим, технические данные и текущее состояние.',
                              onTap: () => context.go('/access'),
                            ),
                            _ActionCard(
                              icon: Icons.notes_rounded,
                              title: 'Журнал',
                              subtitle:
                                  'События подключения, предупреждения и восстановление канала.',
                              onTap: () => context.go('/logs'),
                            ),
                            _ActionCard(
                              icon: Icons.devices_other_rounded,
                              title: 'Устройства',
                              subtitle:
                                  'Управление подключёнными устройствами и лимитами.',
                              onTap: () => context.go('/devices'),
                            ),
                            _ActionCard(
                              icon: Icons.workspace_premium_outlined,
                              title: 'Подписка',
                              subtitle:
                                  'Статус доступа, срок действия и продление.',
                              onTap: () => context.go('/subscription'),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Последние события',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (connection.logs.isEmpty)
                              const Text(
                                'Журнал пока пуст. События появятся после подключения, смены режима или обновления конфигурации.',
                              )
                            else
                              ...connection.logs.take(4).map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    '[${entry.levelLabel}] ${entry.message}',
                                    style: const TextStyle(height: 1.35),
                                  ),
                                );
                              }),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => context.go('/logs'),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text('Открыть журнал'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Аккаунт',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(label: 'Имя', value: fullName),
                            const SizedBox(height: 8),
                            _InfoRow(label: 'Email', value: email),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                OutlinedButton.icon(
                                  onPressed: () => context.go('/profile'),
                                  icon: const Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                  label: const Text('Профиль'),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      widget.sessionController.logout(),
                                  icon: const Icon(Icons.logout_rounded),
                                  label: const Text('Выйти'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isPaid,
    required this.connectionStatus,
    required this.onMainAction,
    required this.onSecondaryAction,
  });

  final String title;
  final String subtitle;
  final bool isActive;
  final bool isPaid;
  final ConnectionStatus connectionStatus;
  final VoidCallback? onMainAction;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final String mainLabel = connectionStatus == ConnectionStatus.connected
        ? 'Отключить'
        : connectionStatus == ConnectionStatus.connecting ||
              connectionStatus == ConnectionStatus.reconnecting
        ? 'Подключение...'
        : 'Подключить';

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
                label: isActive ? 'Доступ готов' : 'Нужна активация',
                isPositive: isActive,
              ),
              StatusBadge(
                label: isPaid ? 'Подписка оплачена' : 'Проверьте подписку',
                isPositive: isPaid || isActive,
              ),
              StatusBadge(
                label: connectionStatus.label,
                isPositive: connectionStatus.isPositive,
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
                onPressed: onMainAction,
                icon: Icon(
                  connectionStatus == ConnectionStatus.connected
                      ? Icons.power_settings_new_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(mainLabel),
              ),
              OutlinedButton.icon(
                onPressed: onSecondaryAction,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Открыть подключение'),
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onToggle,
    required this.toggleLabel,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onToggle;
  final String toggleLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onToggle,
                    icon: const Icon(Icons.swap_horiz_rounded),
                    label: Text(toggleLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
