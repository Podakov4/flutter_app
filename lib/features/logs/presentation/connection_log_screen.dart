import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../access/application/connection_controller.dart';
import '../../access/application/connection_log_entry.dart';

class ConnectionLogScreen extends StatelessWidget {
  const ConnectionLogScreen({super.key, required this.connectionController});

  final ConnectionController connectionController;

  Future<void> _copyLogs(BuildContext context) async {
    final String text = connectionController.exportLogs();
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Журнал пока пуст')));
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Журнал скопирован')));
  }

  Color _logColor(BuildContext context, ConnectionLogLevel level) {
    switch (level) {
      case ConnectionLogLevel.info:
        return Theme.of(context).colorScheme.primary;
      case ConnectionLogLevel.warning:
        return Colors.orange;
      case ConnectionLogLevel.error:
        return Theme.of(context).colorScheme.error;
    }
  }

  IconData _logIcon(ConnectionLogLevel level) {
    switch (level) {
      case ConnectionLogLevel.info:
        return Icons.info_outline_rounded;
      case ConnectionLogLevel.warning:
        return Icons.warning_amber_rounded;
      case ConnectionLogLevel.error:
        return Icons.error_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Журнал подключения')),
      body: AnimatedBuilder(
        animation: connectionController,
        builder: (BuildContext context, _) {
          final List<ConnectionLogEntry> logs = connectionController.logs;

          return Center(
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
                            'Журнал Freeth',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Здесь видно, что происходит с подключением, локацией, режимом и восстановлением канала. '
                            'Это инженерный, но понятный экран — без копирования чужих приложений.',
                            style: TextStyle(height: 1.45),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: logs.isEmpty
                                    ? null
                                    : () => _copyLogs(context),
                                icon: const Icon(Icons.copy_rounded),
                                label: const Text('Копировать'),
                              ),
                              TextButton.icon(
                                onPressed: logs.isEmpty
                                    ? null
                                    : connectionController.clearLogs,
                                icon: const Icon(Icons.delete_outline_rounded),
                                label: const Text('Очистить'),
                              ),
                              TextButton.icon(
                                onPressed: () => connectionController
                                    .registerHealthFailure(),
                                icon: const Icon(Icons.warning_amber_rounded),
                                label: const Text('Тест сбоя'),
                              ),
                              TextButton.icon(
                                onPressed:
                                    connectionController.registerHealthSuccess,
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
                  if (logs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: const <Widget>[
                            Icon(Icons.notes_rounded, size: 36),
                            SizedBox(height: 12),
                            Text(
                              'Журнал пока пуст',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Подключитесь, смените локацию или обновите конфигурацию — события появятся здесь.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...logs.map((ConnectionLogEntry entry) {
                      final Color color = _logColor(context, entry.level);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(_logIcon(entry.level), color: color),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '[${entry.levelLabel}] ${entry.message}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      entry.timestamp.toLocal().toString(),
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
