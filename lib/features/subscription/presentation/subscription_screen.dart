import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/subscription_api.dart';
import '../../../core/models/subscription_info.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key, required this.subscriptionApi});

  final SubscriptionApi subscriptionApi;

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = true;
  bool _isCreatingPayment = false;
  String? _errorText;
  SubscriptionInfo? _subscription;
  int _selectedMonths = 1;

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
      final SubscriptionInfo data = await widget.subscriptionApi.getSubscription();

      if (!mounted) {
        return;
      }

      setState(() {
        _subscription = data;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = 'Не удалось загрузить подписку';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCheckout() async {
    setState(() {
      _isCreatingPayment = true;
    });

    try {
      final String paymentUrl = await widget.subscriptionApi.createCheckout(
        months: _selectedMonths,
      );

      if (paymentUrl.isEmpty) {
        throw Exception('Empty payment url');
      }

      final Uri uri = Uri.parse(paymentUrl);

      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть страницу оплаты')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать платёж')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPayment = false;
        });
      }
    }
  }

  String _planLabel(String? planCode) {
    final String code = (planCode ?? '').trim().toLowerCase();
    switch (code) {
      case '1m':
        return '1 месяц';
      case '3m':
        return '3 месяца';
      case '12m':
        return '12 месяцев';
      case 'trial_7d':
        return 'Пробный период 7 дней';
      default:
        return code.isEmpty ? 'не указан' : planCode!;
    }
  }

  String _periodLabel(bool isActive, bool isPaid) {
    if (!isActive) {
      return 'Нет активного периода';
    }
    if (isPaid) {
      return 'Платный период';
    }
    return 'Пробный или бесплатный период';
  }

  String _expiryLabel(bool isExpired, int daysLeft) {
    if (isExpired) {
      return 'Истекла';
    }
    if (daysLeft > 0) {
      return 'Осталось $daysLeft дн.';
    }
    return 'Активна';
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

    final SubscriptionInfo? sub = _subscription;

    final bool isActive = sub?.isActive == true;
    final bool isPaid = sub?.isPaid == true;
    final bool isExpired = sub?.isExpired == true;
    final String paidUntil = AppFormatters.dateTime(sub?.paidUntil);
    final int daysLeft = sub?.daysLeft ?? 0;
    final int maxDevices = sub?.maxDevices ?? 0;
    final String planCode = _planLabel(sub?.planCode);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            const Text(
              'Подписка',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
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
                      label: isActive
                          ? 'Подписка активна'
                          : 'Подписка не активна',
                      isPositive: isActive,
                    ),
                    StatusBadge(
                      label: _periodLabel(isActive, isPaid),
                      isPositive: isActive,
                    ),
                    StatusBadge(
                      label: _expiryLabel(isExpired, daysLeft),
                      isPositive: !isExpired,
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
                      'Информация',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(label: 'Действует до', value: paidUntil),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Осталось дней', value: '$daysLeft'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Лимит устройств', value: '$maxDevices'),
                    const SizedBox(height: 8),
                    _InfoRow(label: 'План', value: planCode),
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
                  children: const <Widget>[
                    Text(
                      'Подключение',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ссылки подключения и выбор сервера доступны во вкладке «Соединение».',
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
                      'Продление',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedMonths,
                      decoration: const InputDecoration(
                        labelText: 'Срок подписки',
                      ),
                      items: const <DropdownMenuItem<int>>[
                        DropdownMenuItem(value: 1, child: Text('1 месяц')),
                        DropdownMenuItem(value: 3, child: Text('3 месяца')),
                        DropdownMenuItem(value: 12, child: Text('12 месяцев')),
                      ],
                      onChanged: (int? value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _selectedMonths = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _isCreatingPayment ? null : _openCheckout,
                      child: _isCreatingPayment
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Продлить подписку'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Обновить')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подписка')),
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
          width: 128,
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
