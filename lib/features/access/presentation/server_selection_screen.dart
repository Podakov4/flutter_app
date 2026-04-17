import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/access_info.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';

class ServerSelectionScreen extends StatelessWidget {
  const ServerSelectionScreen({super.key, required this.access});

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

  void _showServerDetails(BuildContext context, AccessServerInfo server) {
    final String manualUrl = AppFormatters.fallback(server.manualUrl);
    final bool hasManualUrl = (server.manualUrl?.trim().isNotEmpty == true);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: ListView(
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
                    if ((server.countryCode ?? '').trim().isNotEmpty)
                      StatusBadge(label: server.countryCode!, isPositive: true),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoRow(label: 'Локация', value: _serverSubtitle(server)),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Домен',
                  value: AppFormatters.fallback(server.domain),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Данные для ручного подключения',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SelectableText(manualUrl),
                if (hasManualUrl) ...<Widget>[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        _copyText(context, server.manualUrl!, 'Ссылка локации'),
                    child: const Text('Копировать данные'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _serverTitle(AccessServerInfo server) {
    if (server.displayName?.trim().isNotEmpty == true) {
      return server.displayName!;
    }
    if (server.name?.trim().isNotEmpty == true) {
      return server.name!;
    }
    return server.code.toUpperCase();
  }

  String _serverSubtitle(AccessServerInfo server) {
    final String country = AppFormatters.fallback(
      server.countryCode,
      empty: 'Локация',
    );

    if (server.domain?.trim().isNotEmpty == true) {
      return '$country • ${server.domain}';
    }

    return country;
  }

  @override
  Widget build(BuildContext context) {
    final List<AccessServerInfo> enabledServers = access.servers
        .where((AccessServerInfo server) => server.enabled)
        .toList();

    final AccessServerInfo? currentServer = enabledServers.isNotEmpty
        ? enabledServers.first
        : (access.servers.isNotEmpty ? access.servers.first : null);

    final bool hasSubscriptionUrl =
        (access.subscriptionUrl?.trim().isNotEmpty == true);

    return Scaffold(
      appBar: AppBar(title: const Text('Локации')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const Text(
                'Локации Freeth',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Здесь можно посмотреть доступные локации и выбрать удобный способ подключения. '
                'Основной сценарий — использовать подписку, а ручные данные доступны отдельно.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 24),
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
                            label: access.access
                                ? 'Доступ активен'
                                : 'Доступ не активен',
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
                      const SizedBox(height: 16),
                      _InfoRow(
                        label: 'Доступ до',
                        value: AppFormatters.dateTime(access.expiresAt),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Режим',
                        value: access.servers.length > 1
                            ? 'Ручной выбор локации'
                            : 'Одна доступная локация',
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Текущая',
                        value: currentServer == null
                            ? 'Не определена'
                            : _serverTitle(currentServer),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const <Widget>[
                      Text(
                        'Как устроен Freeth',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 14),
                      _ModeTile(
                        title: 'Умный режим',
                        subtitle:
                            'Freeth сможет сам выбирать лучший маршрут и переключаться при нестабильной сети.',
                        icon: Icons.auto_awesome_rounded,
                      ),
                      SizedBox(height: 12),
                      _ModeTile(
                        title: 'Ручной режим',
                        subtitle:
                            'Вы сами выбираете локацию и подключаетесь к нужной точке.',
                        icon: Icons.public_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (access.servers.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        Text(
                          'Локации пока недоступны',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Пока используйте подписку для подключения. Когда серверы будут доступны отдельно, они автоматически появятся на этом экране.',
                          style: TextStyle(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                )
              else ...<Widget>[
                const SizedBox(height: 6),
                const Text(
                  'Доступные локации',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...List<Widget>.generate(access.servers.length, (int index) {
                  final AccessServerInfo server = access.servers[index];
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _serverTitle(server),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _serverSubtitle(server),
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
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
                          const SizedBox(height: 14),
                          Text(
                            isCurrent
                                ? 'Сейчас эта локация используется как основная для подключения.'
                                : server.enabled
                                ? 'Эта локация доступна для ручного подключения.'
                                : 'Эта локация временно недоступна.',
                            style: const TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showServerDetails(context, server),
                                icon: const Icon(Icons.tune_rounded),
                                label: const Text('Детали'),
                              ),
                              if ((server.manualUrl ?? '').trim().isNotEmpty)
                                TextButton(
                                  onPressed: () => _copyText(
                                    context,
                                    server.manualUrl!,
                                    'Ссылка локации',
                                  ),
                                  child: const Text('Копировать'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 8),
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
                      SelectableText(
                        AppFormatters.fallback(access.subscriptionUrl),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _copyText(
                          context,
                          access.subscriptionUrl!,
                          'Подписочная ссылка',
                        ),
                        child: const Text('Копировать подписку'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (access.manualUrls.isNotEmpty) ...<Widget>[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ручные ссылки',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List<Widget>.generate(access.manualUrls.length, (
                        int index,
                      ) {
                        final String manualUrl = access.manualUrls[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(child: SelectableText(manualUrl)),
                              const SizedBox(width: 12),
                              IconButton(
                                tooltip: 'Копировать',
                                onPressed: () => _copyText(
                                  context,
                                  manualUrl,
                                  'Ручная ссылка',
                                ),
                                icon: const Icon(Icons.copy_rounded),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (!hasSubscriptionUrl && access.manualUrls.isEmpty)
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
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(height: 1.35)),
              ],
            ),
          ),
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
