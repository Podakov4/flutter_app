import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/client_profile.dart';
import '../../../core/models/connection_mode.dart';
import '../../../core/models/connection_state.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/freeth_action_card.dart';
import '../../../shared/widgets/freeth_hero_card.dart';
import '../../../shared/widgets/freeth_info_row.dart';
import '../../../shared/widgets/freeth_mode_card.dart';
import '../../../shared/widgets/freeth_section_title.dart';
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
      return 'Подключайтесь к Freeth и выбирайте нужную локацию в пару нажатий.';
    }
    if (client?.isActive == true) {
      return 'Выберите локацию и подключитесь к Freeth.';
    }
    return 'Проверьте доступ и подключите Freeth.';
  }

  bool _isExpiringSoon(String? value) {
    if (value == null || value.trim().isEmpty) {
      return false;
    }

    final DateTime? paidUntil = DateTime.tryParse(value);

    if (paidUntil == null) {
      return false;
    }

    final DateTime now = DateTime.now();

    return paidUntil.isAfter(now) &&
        paidUntil.difference(now) <= const Duration(days: 7);
  }

  Widget? _subscriptionNotice(BuildContext context, ClientProfile? client) {
    final bool isActive = client?.isActive == true;
    final bool isPaid = client?.isPaid == true;
    final bool expiringSoon = _isExpiringSoon(client?.paidUntil);

    if (isActive && isPaid && !expiringSoon) {
      return null;
    }

    final bool isWarning = isActive && isPaid && expiringSoon;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  isWarning
                      ? Icons.schedule_rounded
                      : Icons.workspace_premium_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isWarning
                            ? 'Подписка скоро закончится'
                            : 'Подписка не активна',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWarning
                            ? 'Доступ активен до ${AppFormatters.dateTime(client?.paidUntil)}.'
                            : 'Продлите доступ, чтобы подключаться к Freeth.',
                        style: TextStyle(
                          height: 1.35,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => context.go('/subscription'),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(isWarning ? 'Продлить' : 'Оплатить'),
              ),
            ),
          ],
        ),
      ),
    );
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
        final ConnectionController connection = widget.connectionController;

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
        final Widget? subscriptionNotice = _subscriptionNotice(context, client);

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
                    if (subscriptionNotice != null) ...<Widget>[
                      subscriptionNotice,
                      const SizedBox(height: 16),
                    ],
                    FreethHeroCard(
                      title: _heroTitle(client),
                      subtitle: _heroSubtitle(client),
                      badges: <Widget>[
                        StatusBadge(
                          label: isActive ? 'Доступ готов' : 'Нужна активация',
                          isPositive: isActive,
                        ),
                        StatusBadge(
                          label: isPaid
                              ? 'Подписка оплачена'
                              : 'Проверьте подписку',
                          isPositive: isPaid || isActive,
                        ),
                        StatusBadge(
                          label: status.label,
                          isPositive: status.isPositive,
                        ),
                      ],
                      actions: <Widget>[
                        FilledButton.icon(
                          onPressed: !connection.canConnect || connection.isBusy
                              ? null
                              : () {
                                  if (connection.isConnected) {
                                    connection.disconnect();
                                  } else {
                                    connection.connect();
                                  }
                                },
                          icon: Icon(
                            connection.isConnected
                                ? Icons.power_settings_new_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            connection.isConnected
                                ? 'Отключить'
                                : connection.isBusy
                                ? 'Подключение...'
                                : 'Подключить',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go('/access'),
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text('Открыть подключение'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const FreethSectionTitle(
                      title: 'Сейчас',
                      subtitle:
                          'Основное состояние подключения и выбранная локация.',
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
                            FreethInfoRow(
                              label: 'Локация',
                              value: connection.currentLocationTitle,
                            ),
                            const SizedBox(height: 8),
                            FreethInfoRow(
                              label: 'Маршрут',
                              value: connection.currentLocationSubtitle,
                            ),
                            const SizedBox(height: 8),
                            FreethInfoRow(
                              label: 'Сеть',
                              value: connection.networkLabel,
                            ),

                            const SizedBox(height: 8),
                            FreethInfoRow(label: 'Доступ до', value: paidUntil),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const FreethSectionTitle(
                      title: 'Режим',
                      subtitle:
                          'Выберите автоматический или ручной сценарий подключения.',
                    ),
                    const SizedBox(height: 12),
                    FreethModeCard(
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
                    const FreethSectionTitle(
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
                            FreethActionCard(
                              icon: Icons.power_settings_new_rounded,
                              title: 'Подключение',
                              subtitle:
                                  'Локации, режим, технические данные и текущее состояние.',
                              onTap: () => context.go('/access'),
                            ),
                            FreethActionCard(
                              icon: Icons.notes_rounded,
                              title: 'Журнал',
                              subtitle:
                                  'События подключения, предупреждения и восстановление канала.',
                              onTap: () => context.go('/logs'),
                            ),
                            FreethActionCard(
                              icon: Icons.devices_other_rounded,
                              title: 'Устройства',
                              subtitle:
                                  'Управление подключёнными устройствами и лимитами.',
                              onTap: () => context.go('/devices'),
                            ),
                            FreethActionCard(
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
                            FreethInfoRow(label: 'Имя', value: fullName),
                            const SizedBox(height: 8),
                            FreethInfoRow(label: 'Email', value: email),
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
