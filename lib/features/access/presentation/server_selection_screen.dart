import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/access_info.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';

class ServerSelectionScreen extends StatelessWidget {
  const ServerSelectionScreen({
    super.key,
    required this.access,
  });

  final AccessInfo access;

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

  @override
  Widget build(BuildContext context) {
    final String subscriptionUrl = AppFormatters.fallback(access.subscriptionUrl);
    final bool hasSubscriptionUrl =
        (access.subscriptionUrl?.trim().isNotEmpty == true);

    return Scaffold(
      appBar: AppBar(title: const Text('Серверы')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const Text(
                'Серверы',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Для обычного использования удобнее подписочная ссылка. Ниже доступны отдельные серверы для ручного подключения.',
                style: TextStyle(height: 1.4),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      StatusBadge(
                        label: access.access ? 'Доступ активен' : 'Доступ не активен',
                        isPositive: access.access,
                      ),
                      StatusBadge(
                        label: access.subscriptionActive
                            ? 'Подписка активна'
                            : 'Подписка не активна',
                        isPositive: access.subscriptionActive,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Подписочная ссылка',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(subscriptionUrl),
                      if (hasSubscriptionUrl) ...<Widget>[
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _copyText(
                            context,
                            access.subscriptionUrl!,
                            'Подписочная ссылка',
                          ),
                          child: const Text('Копировать'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (access.servers.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        Text(
                          'Список серверов пока недоступен',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Используйте подписочную ссылку выше. Когда backend вернёт отдельные ноды, они автоматически появятся на этом экране.',
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...access.servers.map(
                  (server) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              Text(
                                (server.displayName?.trim().isNotEmpty == true)
                                    ? server.displayName!
                                    : (server.name?.trim().isNotEmpty == true)
                                        ? server.name!
                                        : server.code,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              StatusBadge(
                                label: server.enabled ? 'Доступен' : 'Отключён',
                                isPositive: server.enabled,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Код', value: server.code),
                          const SizedBox(height: 6),
                          _InfoRow(
                            label: 'Страна',
                            value: AppFormatters.fallback(server.countryCode),
                          ),
                          const SizedBox(height: 6),
                          _InfoRow(
                            label: 'Домен',
                            value: AppFormatters.fallback(server.domain),
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            AppFormatters.fallback(server.manualUrl),
                          ),
                          if ((server.manualUrl ?? '').trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => _copyText(
                                context,
                                server.manualUrl!,
                                'Ссылка сервера',
                              ),
                              child: const Text('Копировать ссылку'),
                            ),
                          ],
                        ],
                      ),
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
      children: <Widget>[
        SizedBox(
          width: 72,
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
