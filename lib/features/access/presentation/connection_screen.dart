import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/connection_mode.dart';
import '../../../core/models/connection_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';
import '../application/connection_controller.dart';
import 'server_selection_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key, required this.connectionController});

  final ConnectionController connectionController;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.connectionController.access == null &&
        !widget.connectionController.isLoading) {
      widget.connectionController.loadAccess();
    }
  }

  Future<void> _copyText(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label скопирована')));
  }

  void _openServerSelection() {
    final access = widget.connectionController.access;
    if (access == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServerSelectionScreen(access: access),
      ),
    );
  }

  Widget _buildBody() {
    return AnimatedBuilder(
      animation: widget.connectionController,
      builder: (BuildContext context, _) {
        final controller = widget.connectionController;
        final access = controller.access;

        if (controller.isLoading && access == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.lastError != null && access == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(controller.lastError!),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.loadAccess,
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final ConnectionStatus status = controller.status;
        final ConnectionMode mode = controller.mode;

        final String expiresAt = AppFormatters.dateTime(access?.expiresAt);
        final String type = AppFormatters.fallback(access?.type);
        final String supports = access == null || access.supports.isEmpty
            ? '—'
            : access.supports.join(', ');

        final String? subscriptionUrl = access?.subscriptionUrl;
        final String? manualUrl = access?.manualUrl;
        final List<String> manualUrls = access?.manualUrls ?? <String>[];

        final bool hasSubscriptionUrl =
            subscriptionUrl != null && subscriptionUrl.trim().isNotEmpty;
        final bool hasManualUrl =
            manualUrl != null && manualUrl.trim().isNotEmpty;
        final bool hasManualUrls = manualUrls.isNotEmpty;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: <Widget>[
                _HeroCard(
                  status: status,
                  canConnect: controller.canConnect,
                  subscriptionActive: controller.subscriptionActive,
                  isBusy: controller.isBusy,
                  onConnectToggle: !controller.canConnect || controller.isBusy
                      ? null
                      : () {
                          if (controller.isConnected) {
                            controller.disconnect();
                          } else {
                            controller.connect();
                          }
                        },
                  onReconnect: controller.isBusy ? null : controller.reconnect,
                  onOpenLocations: access == null ? null : _openServerSelection,
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: 'Состояние подключения',
                  subtitle:
                      'Экран подключения отвечает за текущий статус, режим, локацию и рабочие действия.',
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
                            StatusBadge(label: mode.label, isPositive: true),
                            StatusBadge(
                              label: controller.subscriptionActive
                                  ? 'Подписка активна'
                                  : 'Проверьте подписку',
                              isPositive:
                                  controller.subscriptionActive ||
                                  controller.canConnect,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          label: 'Локация',
                          value: controller.currentLocationTitle,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Маршрут',
                          value: controller.currentLocationSubtitle,
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Сеть', value: controller.networkLabel),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Порт',
                          value: controller.localPort.toString(),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Доступ до', value: expiresAt),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Тип', value: type),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Платформы', value: supports),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: 'Режим и локации',
                  subtitle:
                      'Freeth должен быть понятным: можно доверить маршрут приложению или выбрать локацию вручную.',
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Режим подключения',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            ChoiceChip(
                              label: const Text('Умный режим'),
                              selected: mode == ConnectionMode.smart,
                              onSelected: (_) => controller.setSmartMode(),
                            ),
                            ChoiceChip(
                              label: const Text('Ручной режим'),
                              selected: mode == ConnectionMode.manual,
                              onSelected: (_) => controller.setManualMode(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          mode.subtitle,
                          style: const TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: access == null
                              ? null
                              : _openServerSelection,
                          icon: const Icon(Icons.public_rounded),
                          label: const Text('Открыть локации'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(
                  title: 'Последние события',
                  subtitle:
                      'Полный журнал вынесен в отдельный экран, а здесь только краткая сводка.',
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (controller.logs.isEmpty)
                          const Text(
                            'Пока нет событий. Подключитесь или смените режим, чтобы журнал начал заполняться.',
                          )
                        else
                          ...controller.logs.take(5).map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                '[${entry.levelLabel}] ${entry.message}',
                                style: const TextStyle(height: 1.35),
                              ),
                            );
                          }),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: () => context.go('/logs'),
                              icon: const Icon(Icons.notes_rounded),
                              label: const Text('Открыть журнал'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  controller.registerHealthFailure(),
                              icon: const Icon(Icons.warning_amber_rounded),
                              label: const Text('Тест сбоя'),
                            ),
                            TextButton.icon(
                              onPressed: controller.registerHealthSuccess,
                              icon: const Icon(
                                Icons.health_and_safety_outlined,
                              ),
                              label: const Text('Тест восстановления'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    title: const Text(
                      'Технические данные подключения',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Для ручной настройки и продвинутого использования',
                    ),
                    children: <Widget>[
                      if (hasSubscriptionUrl) ...<Widget>[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Подписочная ссылка',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(subscriptionUrl!),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              _copyText(subscriptionUrl, 'Подписочная ссылка'),
                          child: const Text('Копировать подписку'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (hasManualUrl) ...<Widget>[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Быстрая ручная ссылка',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(manualUrl!),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              _copyText(manualUrl, 'Ручная ссылка'),
                          child: const Text('Копировать ручную ссылку'),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (hasManualUrls) ...<Widget>[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Дополнительные ручные ссылки',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List<Widget>.generate(manualUrls.length, (
                          int index,
                        ) {
                          final String value = manualUrls[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(child: SelectableText(value)),
                                const SizedBox(width: 12),
                                IconButton(
                                  tooltip: 'Копировать',
                                  onPressed: () =>
                                      _copyText(value, 'Ручная ссылка'),
                                  icon: const Icon(Icons.copy_rounded),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      if (!hasSubscriptionUrl &&
                          !hasManualUrl &&
                          !hasManualUrls)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Технические данные пока недоступны.'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подключение')),
      body: _buildBody(),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.status,
    required this.canConnect,
    required this.subscriptionActive,
    required this.isBusy,
    required this.onConnectToggle,
    required this.onReconnect,
    required this.onOpenLocations,
  });

  final ConnectionStatus status;
  final bool canConnect;
  final bool subscriptionActive;
  final bool isBusy;
  final VoidCallback? onConnectToggle;
  final VoidCallback? onReconnect;
  final VoidCallback? onOpenLocations;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final String mainLabel = status == ConnectionStatus.connected
        ? 'Отключить'
        : isBusy
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
              StatusBadge(label: status.label, isPositive: status.isPositive),
              StatusBadge(
                label: canConnect ? 'Доступ готов' : 'Нужна активация',
                isPositive: canConnect,
              ),
              StatusBadge(
                label: subscriptionActive
                    ? 'Подписка активна'
                    : 'Проверьте подписку',
                isPositive: subscriptionActive || canConnect,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Управление подключением',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Freeth объединяет статус, режим, локации и журнал в одном месте. Технические ссылки остаются доступны, но больше не доминируют в интерфейсе.',
            style: TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.icon(
                onPressed: onConnectToggle,
                icon: Icon(
                  status == ConnectionStatus.connected
                      ? Icons.power_settings_new_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(mainLabel),
              ),
              OutlinedButton.icon(
                onPressed: onReconnect,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Переподключить'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenLocations,
                icon: const Icon(Icons.public_rounded),
                label: const Text('Локации'),
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
          width: 96,
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
