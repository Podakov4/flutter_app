import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/access_info.dart';
import '../../../core/models/connection_mode.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';
import '../application/connection_controller.dart';

class ServerSelectionScreen extends StatelessWidget {
  const ServerSelectionScreen({super.key, required this.connectionController});

  final ConnectionController connectionController;

  Future<void> _copyText(
    BuildContext context,
    String value,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label скопирована')));
  }

  String _serverTitle(AccessServerInfo server) {
    if ((server.displayName ?? '').trim().isNotEmpty) {
      return server.displayName!;
    }
    if ((server.name ?? '').trim().isNotEmpty) {
      return server.name!;
    }
    return server.code.toUpperCase();
  }

  String _serverSubtitle(AccessServerInfo server) {
    final String country = AppFormatters.fallback(
      server.countryCode,
      empty: 'Локация',
    );

    if ((server.domain ?? '').trim().isNotEmpty) {
      return '$country • ${server.domain}';
    }

    return country;
  }

  void _showServerDetails(BuildContext context, AccessServerInfo server) {
    final bool isCurrent =
        connectionController.currentServer?.code == server.code;
    final bool hasManualUrl = (server.manualUrl?.trim().isNotEmpty == true);
    final String manualUrl = AppFormatters.fallback(server.manualUrl);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: AnimatedBuilder(
              animation: connectionController,
              builder: (BuildContext context, _) {
                return ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(
                      _serverTitle(server),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        StatusBadge(
                          label: server.enabled ? 'Доступна' : 'Недоступна',
                          isPositive: server.enabled,
                        ),
                        if (isCurrent)
                          const StatusBadge(label: 'Текущая', isPositive: true),
                        if ((server.countryCode ?? '').trim().isNotEmpty)
                          StatusBadge(
                            label: server.countryCode!,
                            isPositive: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _InfoRow(label: 'Локация', value: _serverSubtitle(server)),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Домен',
                      value: AppFormatters.fallback(server.domain),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      label: 'Режим',
                      value: connectionController.mode == ConnectionMode.smart
                          ? 'Сейчас активен умный режим'
                          : 'Сейчас активен ручной режим',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Данные для ручного подключения',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(manualUrl),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: !server.enabled
                              ? null
                              : () {
                                  connectionController.selectServer(
                                    server.code,
                                  );
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Выбрана локация: ${_serverTitle(server)}',
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: Text(
                            isCurrent ? 'Локация выбрана' : 'Выбрать локацию',
                          ),
                        ),
                        if (hasManualUrl)
                          OutlinedButton.icon(
                            onPressed: () => _copyText(
                              context,
                              server.manualUrl!,
                              'Ссылка локации',
                            ),
                            icon: const Icon(Icons.copy_rounded),
                            label: const Text('Копировать'),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: connectionController,
      builder: (BuildContext context, _) {
        final access = connectionController.access;
        final List<AccessServerInfo> servers = connectionController.allServers;
        final AccessServerInfo? currentServer = connectionController.currentServer;
        final ConnectionMode mode = connectionController.mode;

        return Scaffold(
          appBar: AppBar(title: const Text('Локации')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Локации Freeth',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Здесь выбирается рабочая локация Freeth. В ручном режиме выбор фиксируется пользователем, а в умном режиме приложение позже сможет выбирать маршрут самостоятельно.',
                            style: TextStyle(height: 1.45),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
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
                              StatusBadge(label: mode.label, isPositive: true),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _InfoRow(
                            label: 'Текущая',
                            value: currentServer == null
                                ? 'Не выбрана'
                                : _serverTitle(currentServer),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Маршрут',
                            value: connectionController.currentLocationSubtitle,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            label: 'Доступ до',
                            value: AppFormatters.dateTime(access?.expiresAt),
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
                            'Режим работы',
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
                                onSelected: (_) =>
                                    connectionController.setSmartMode(),
                              ),
                              ChoiceChip(
                                label: const Text('Ручной режим'),
                                selected: mode == ConnectionMode.manual,
                                onSelected: (_) =>
                                    connectionController.setManualMode(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            mode.subtitle,
                            style: TextStyle(
                              height: 1.4,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (servers.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: <Widget>[
                            const Icon(Icons.public_off_rounded, size: 36),
                            const SizedBox(height: 12),
                            const Text(
                              'Локации пока недоступны',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Попробуйте обновить данные подключения. Когда серверы будут доступны, они появятся здесь.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: connectionController.loadAccess,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Обновить'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...<Widget>[
                    const Text(
                      'Доступные локации',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...servers.map((server) {
                      final bool isCurrent =
                          currentServer != null &&
                          currentServer.code == server.code;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  Text(
                                    _serverTitle(server),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (isCurrent)
                                    const StatusBadge(
                                      label: 'Текущая',
                                      isPositive: true,
                                    )
                                  else
                                    StatusBadge(
                                      label: server.enabled
                                          ? 'Доступна'
                                          : 'Недоступна',
                                      isPositive: server.enabled,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _serverSubtitle(server),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                isCurrent
                                    ? 'Сейчас эта локация выбрана как основная.'
                                    : 'Эту локацию можно выбрать для ручного подключения.',
                                style: const TextStyle(height: 1.4),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: <Widget>[
                                  FilledButton.icon(
                                    onPressed: !server.enabled
                                        ? null
                                        : () {
                                            connectionController.selectServer(
                                              server.code,
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Выбрана локация: ${_serverTitle(server)}',
                                                ),
                                              ),
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                    ),
                                    label: Text(
                                      isCurrent ? 'Выбрана' : 'Выбрать',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _showServerDetails(context, server),
                                    icon: const Icon(Icons.tune_rounded),
                                    label: const Text('Детали'),
                                  ),
                                  if ((server.manualUrl ?? '')
                                      .trim()
                                      .isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () => _copyText(
                                        context,
                                        server.manualUrl!,
                                        'Ссылка локации',
                                      ),
                                      icon: const Icon(Icons.copy_rounded),
                                      label: const Text('Копировать'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
          width: 88,
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
