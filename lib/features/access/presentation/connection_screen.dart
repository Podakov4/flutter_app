import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/connection_mode.dart';
import '../../../core/models/connection_state.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/freeth_hero_card.dart';
import '../../../shared/widgets/freeth_info_row.dart';
import '../../../shared/widgets/freeth_section_title.dart';
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServerSelectionScreen(
          connectionController: widget.connectionController,
        ),
      ),
    );
  }

  Future<void> _showRenewDialog() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Нужно продлить доступ'),
          content: const Text(
            'Чтобы подключиться к Freeth, продлите подписку.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Позже'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/subscription');
              },
              child: const Text('Продлить'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.connectionController,
      builder: (BuildContext context, _) {
        final ConnectionController controller = widget.connectionController;
        final access = controller.access;

        if (controller.isLoading && access == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Подключение')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.lastError != null && access == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Подключение')),
            body: Center(
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
        final String? happImportUrl = access?.happImportUrl;
        final String? preferredHappUrl = access?.preferredHappUrl;
        final String? manualUrl = access?.manualUrl;
        final List<String> manualUrls = access?.manualUrls ?? <String>[];

        final bool hasPreferredHappUrl =
            preferredHappUrl != null && preferredHappUrl.trim().isNotEmpty;
        final bool hasPlainSubscriptionUrl =
            subscriptionUrl != null && subscriptionUrl.trim().isNotEmpty;
        final bool hasEncryptedHappUrl =
            happImportUrl != null && happImportUrl.trim().isNotEmpty;
        final bool hasManualUrl =
            manualUrl != null && manualUrl.trim().isNotEmpty;
        final bool hasManualUrls = manualUrls.isNotEmpty;

        return Scaffold(
          appBar: AppBar(title: const Text('Подключение')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  FreethHeroCard(
                    title: 'Управление подключением',
                    subtitle:
                        'Подключайтесь, выбирайте локацию и следите за состоянием Freeth.',
                    badges: <Widget>[
                      StatusBadge(
                        label: status.label,
                        isPositive: status.isPositive,
                      ),
                      StatusBadge(
                        label: controller.canConnect
                            ? 'Доступ готов'
                            : 'Нужна активация',
                        isPositive: controller.canConnect,
                      ),
                      StatusBadge(
                        label: controller.subscriptionActive
                            ? 'Подписка активна'
                            : 'Проверьте подписку',
                        isPositive:
                            controller.subscriptionActive ||
                            controller.canConnect,
                      ),
                    ],
                    actions: <Widget>[
                      FilledButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : () {
                                if (!controller.canConnect) {
                                  _showRenewDialog();
                                  return;
                                }

                                if (controller.isConnected) {
                                  controller.disconnect();
                                } else {
                                  controller.connect();
                                }
                              },
                        icon: Icon(
                          status == ConnectionStatus.connected
                              ? Icons.power_settings_new_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          status == ConnectionStatus.connected
                              ? 'Отключить'
                              : controller.isBusy
                              ? 'Подключение...'
                              : 'Подключить',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : controller.reconnect,
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('Переподключить'),
                      ),
                      OutlinedButton.icon(
                        onPressed: access == null ? null : _openServerSelection,
                        icon: const Icon(Icons.public_rounded),
                        label: const Text('Локации'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const FreethSectionTitle(
                    title: 'Состояние',
                    subtitle: 'Текущий статус, локация и основные действия.',
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
                          FreethInfoRow(
                            label: 'Локация',
                            value: controller.currentLocationTitle,
                            labelWidth: 96,
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Маршрут',
                            value: controller.currentLocationSubtitle,
                            labelWidth: 96,
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Сеть',
                            value: controller.networkLabel,
                            labelWidth: 96,
                          ),

                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Доступ до',
                            value: expiresAt,
                            labelWidth: 96,
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Тип',
                            value: type,
                            labelWidth: 96,
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Платформы',
                            value: supports,
                            labelWidth: 96,
                          ),
                          const SizedBox(height: 8),
                          FreethInfoRow(
                            label: 'Сбои',
                            value: controller.healthFailures.toString(),
                            labelWidth: 96,
                          ),
                          if (controller.lastError != null) ...<Widget>[
                            const SizedBox(height: 14),
                            Text(
                              controller.lastError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FreethSectionTitle(
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
                  const FreethSectionTitle(
                    title: 'Автоповедение',
                    subtitle:
                        'Часть поведения уже управляется живым ConnectionController и сохраняется между запусками.',
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: <Widget>[
                        SwitchListTile.adaptive(
                          title: const Text('Автопереключение при смене сети'),
                          subtitle: const Text(
                            'Если сеть меняется во время активного подключения, Freeth сможет мягко переподключиться.',
                          ),
                          value: controller.autoSwitchOnNetworkChange,
                          onChanged: controller.setAutoSwitchOnNetworkChange,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          title: const Text('Разрешить резервный маршрут'),
                          subtitle: const Text(
                            'Если основной канал деградирует, Freeth сможет уйти в failover.',
                          ),
                          value: controller.fallbackEnabled,
                          onChanged: controller.setFallbackEnabled,
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          title: const Text('Подробный журнал'),
                          subtitle: const Text(
                            'Сохранять и показывать более подробные события подключения.',
                          ),
                          value: controller.showDetailedLogs,
                          onChanged: controller.setShowDetailedLogs,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const FreethSectionTitle(
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
                        if (hasPreferredHappUrl) ...<Widget>[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              hasEncryptedHappUrl
                                  ? 'Ссылка для Happ'
                                  : 'Универсальная подписка',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(preferredHappUrl),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => _copyText(
                              preferredHappUrl,
                              hasEncryptedHappUrl
                                  ? 'Ссылка для Happ'
                                  : 'Подписочная ссылка',
                            ),
                            child: Text(
                              hasEncryptedHappUrl
                                  ? 'Копировать ссылку для Happ'
                                  : 'Копировать подписку',
                            ),
                          ),
                          if (hasEncryptedHappUrl &&
                              hasPlainSubscriptionUrl) ...<Widget>[
                            const SizedBox(height: 12),
                            Text(
                              'Для Happ используйте эту encrypted-ссылку. Обычная подписка оставлена как технический fallback.',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
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
                          SelectableText(manualUrl),
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
                        if (!hasPreferredHappUrl &&
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
          ),
        );
      },
    );
  }
}
