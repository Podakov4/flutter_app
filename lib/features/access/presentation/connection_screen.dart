import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/access_api.dart';
import '../../../core/models/access_info.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';
import 'server_selection_screen.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key, required this.accessApi});

  final AccessApi accessApi;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _isLoading = true;
  String? _errorText;
  AccessInfo? _access;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final AccessInfo access = await widget.accessApi.getAccess();

      if (!mounted) {
        return;
      }

      setState(() {
        _access = access;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'Не удалось загрузить данные подключения';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  void _openServerSelection(AccessInfo access) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ServerSelectionScreen(access: access),
      ),
    );
  }

  Widget _buildServerPreview(AccessInfo access) {
    if (!access.hasServerSelectionData) {
      return const SizedBox.shrink();
    }

    final List<AccessServerInfo> previewServers = access.servers.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Серверы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Для автообновления конфигурации удобнее использовать подписочную ссылку. Для ручного подключения можно выбрать конкретный сервер.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 16),
            if (previewServers.isEmpty)
              const Text('Список серверов не загружен отдельно.')
            else
              ...previewServers.map(
                (server) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        server.enabled ? '🟢 ' : '⚪ ',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              (server.displayName?.trim().isNotEmpty == true)
                                  ? server.displayName!
                                  : (server.name?.trim().isNotEmpty == true)
                                      ? server.name!
                                      : server.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if ((server.domain ?? '').trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(server.domain!),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _openServerSelection(access),
              child: const Text('Выбрать сервер'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorText != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(_errorText!),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }

    final AccessInfo? access = _access;

    final bool enabled = access?.access == true;
    final bool subscriptionActive = access?.subscriptionActive == true;
    final String expiresAt = AppFormatters.dateTime(access?.expiresAt);
    final String subscriptionUrl = AppFormatters.fallback(
      access?.subscriptionUrl,
    );
    final String manualUrl = AppFormatters.fallback(access?.manualUrl);
    final String supports = access == null || access.supports.isEmpty
        ? '—'
        : access.supports.join(', ');
    final int serverCount = access?.servers.length ?? 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Text(
              'Соединение',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        StatusBadge(
                          label: AppFormatters.activeInactive(enabled),
                          isPositive: enabled,
                        ),
                        StatusBadge(
                          label: AppFormatters.subscriptionStatus(
                            subscriptionActive,
                          ),
                          isPositive: subscriptionActive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Доступ до', value: expiresAt),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Тип', value: AppFormatters.fallback(access?.type)),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Платформы', value: supports),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Серверов', value: '$serverCount'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Подписочная ссылка',
              subtitle:
                  'Подходит для автоматического обновления конфигурации в приложениях-клиентах.',
              value: subscriptionUrl,
              selectable: true,
              action: subscriptionUrl == '—'
                  ? null
                  : OutlinedButton(
                      onPressed: () =>
                          _copyText(subscriptionUrl, 'Подписочная ссылка'),
                      child: const Text('Копировать'),
                    ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Быстрая ручная ссылка',
              subtitle:
                  'Базовая ссылка для подключения. Для выбора конкретной точки используйте список серверов ниже.',
              value: manualUrl,
              selectable: true,
              action: manualUrl == '—'
                  ? null
                  : OutlinedButton(
                      onPressed: () =>
                          _copyText(manualUrl, 'Ручная ссылка'),
                      child: const Text('Копировать'),
                    ),
            ),
            const SizedBox(height: 12),
            if (access != null) _buildServerPreview(access),
            const SizedBox(height: 24),
            FilledButton(onPressed: _load, child: const Text('Обновить')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Соединение')),
      body: _buildBody(),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.selectable = false,
    this.action,
  });

  final String title;
  final String value;
  final String? subtitle;
  final bool selectable;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(subtitle!, style: const TextStyle(height: 1.4)),
            ],
            const SizedBox(height: 12),
            selectable
                ? SelectableText(value)
                : Text(value, style: const TextStyle(fontSize: 16)),
            if (action != null) ...<Widget>[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
