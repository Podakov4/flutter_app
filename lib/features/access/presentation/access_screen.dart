import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/access_api.dart';
import '../../../core/models/access_info.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key, required this.accessApi});

  final AccessApi accessApi;

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
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
      final access = await widget.accessApi.getAccess();

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
        _errorText = 'Не удалось загрузить данные доступа';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openInHapp(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть happ')),
      );
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
    final String? happUrl = access?.preferredHappUrl;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Text(
              'Доступ',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Статус доступа',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusBadge(
                      label: AppFormatters.activeInactive(enabled),
                      isPositive: enabled,
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
                      'Подписка',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    StatusBadge(
                      label: AppFormatters.subscriptionStatus(
                        subscriptionActive,
                      ),
                      isPositive: subscriptionActive,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _InfoCard(title: 'Действует до', value: expiresAt),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Ссылка подписки',
              value: subscriptionUrl,
              selectable: true,
              action: subscriptionUrl == '—'
                  ? null
                  : OutlinedButton(
                      onPressed: () =>
                          _copyText(subscriptionUrl, 'Ссылка подписки'),
                      child: const Text('Копировать'),
                    ),
            ),
            const SizedBox(height: 12),
            _InfoCard(
              title: 'Ручная ссылка',
              value: manualUrl,
              selectable: true,
              action: manualUrl == '—'
                  ? null
                  : OutlinedButton(
                      onPressed: () => _copyText(manualUrl, 'Ручная ссылка'),
                      child: const Text('Копировать'),
                    ),
            ),
            if (happUrl != null) ...<Widget>[
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Открыть в happ',
                value: happUrl,
                selectable: true,
                action: Row(
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () => _openInHapp(happUrl),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Открыть в happ'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => _copyText(happUrl, 'Ссылка happ'),
                      child: const Text('Копировать'),
                    ),
                  ],
                ),
              ),
            ],
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
      appBar: AppBar(title: const Text('Доступ')),
      body: _buildBody(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.value,
    this.selectable = false,
    this.action,
  });

  final String title;
  final String value;
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
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
