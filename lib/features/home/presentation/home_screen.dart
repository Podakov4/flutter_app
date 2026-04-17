import 'package:flutter/material.dart';

import '../../../core/models/client_profile.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.sessionController});

  final SessionController sessionController;

  String _subscriptionLabel(ClientProfile? client) {
    if (client?.isActive == true && client?.isPaid == true) {
      return 'Подписка оплачена';
    }
    if (client?.isActive == true) {
      return 'Доступ активен';
    }
    return 'Доступ не активен';
  }

  @override
  Widget build(BuildContext context) {
    final ClientProfile? client = sessionController.client;

    final String fullName = (client?.fullName?.trim().isNotEmpty == true)
        ? client!.fullName!
        : 'Пользователь';

    final String telegramId = AppFormatters.fallback(client?.telegramId);
    final String email = AppFormatters.fallback(
      client?.email,
      empty: 'не указан',
    );
    final String paidUntil = AppFormatters.dateTime(client?.paidUntil);
    final bool isActive = client?.isActive == true;
    final bool isPaid = client?.isPaid == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Главная')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              children: <Widget>[
                Center(
                  child: Image.asset('assets/images/logo.png', height: 96),
                ),
                const SizedBox(height: 24),
                Text(
                  'Привет, $fullName',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Здесь собраны ваши доступ, устройства, подписка и профиль.',
                  style: TextStyle(fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Аккаунт',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            StatusBadge(
                              label: isActive
                                  ? 'Аккаунт активен'
                                  : 'Аккаунт не активен',
                              isPositive: isActive,
                            ),
                            StatusBadge(
                              label: _subscriptionLabel(client),
                              isPositive: isPaid || isActive,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(label: 'Telegram ID', value: telegramId),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Email', value: email),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Доступ до', value: paidUntil),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const <Widget>[
                        Text(
                          'Что можно сделать',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text('• Во вкладке «Соединение» — ссылки и серверы.'),
                        SizedBox(height: 8),
                        Text('• Во вкладке «Устройства» — список и отзыв устройств.'),
                        SizedBox(height: 8),
                        Text('• Во вкладке «Подписка» — статус и продление.'),
                        SizedBox(height: 8),
                        Text('• Во вкладке «Профиль» — email и данные аккаунта.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => sessionController.logout(),
                  child: const Text('Выйти'),
                ),
              ],
            ),
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
          width: 110,
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
