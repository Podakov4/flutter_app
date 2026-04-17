import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../../core/models/client_profile.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/status_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.sessionController});

  final SessionController sessionController;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _emailController;
  late final FocusNode _emailFocusNode;

  bool _isSaving = false;
  bool _isEditingEmail = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.sessionController.client?.email ?? '',
    );
    _emailFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    if (value.trim().isEmpty) {
      return true;
    }

    final RegExp regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value.trim());
  }

  String _extractErrorMessage(Object error, String fallback) {
    if (error is DioException) {
      final dynamic data = error.response?.data;
      if (data is Map && data['detail'] is String) {
        return data['detail'] as String;
      }
    }
    return fallback;
  }

  void _startEditingEmail() {
    final String currentEmail = widget.sessionController.client?.email ?? '';

    setState(() {
      _isEditingEmail = true;
      _emailError = null;
      _emailController.text = currentEmail;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _emailFocusNode.requestFocus();
    });
  }

  void _cancelEditingEmail() {
    _emailFocusNode.unfocus();

    setState(() {
      _isEditingEmail = false;
      _emailError = null;
      _emailController.text = widget.sessionController.client?.email ?? '';
    });
  }

  Future<void> _saveEmail() async {
    _emailFocusNode.unfocus();

    final String email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Введите корректный email';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _emailError = null;
    });

    try {
      await widget.sessionController.updateEmail(email.isEmpty ? null : email);

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditingEmail = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email сохранён')));
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _emailError = _extractErrorMessage(error, 'Не удалось сохранить email');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _statusText(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
        return 'Активен';
      case 'blocked':
        return 'Заблокирован';
      case 'deleted':
        return 'Удалён';
      default:
        return AppFormatters.fallback(status);
    }
  }

  String _createdViaText(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'telegram':
        return 'Telegram';
      case 'email':
        return 'Email';
      case 'merged':
        return 'Telegram + email';
      case 'admin':
        return 'Администратор';
      default:
        return AppFormatters.fallback(value);
    }
  }

  String _languageText(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return AppFormatters.fallback(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ClientProfile? client = widget.sessionController.client;

    final String fullName = (client?.fullName?.trim().isNotEmpty == true)
        ? client!.fullName!
        : 'Пользователь';

    final String telegramId = AppFormatters.fallback(client?.telegramId);
    final String accessId = AppFormatters.fallback(
      client?.login,
      empty: 'не указан',
    );
    final String currentEmail = client?.email?.trim() ?? '';
    final bool hasEmail = currentEmail.isNotEmpty;

    final bool isActive = client?.isActive == true;
    final bool isPaid = client?.isPaid == true;
    final String paidUntil = AppFormatters.dateTime(client?.paidUntil);
    final String statusText = _statusText(client?.status);
    final String createdVia = _createdViaText(client?.createdVia);
    final String language = _languageText(client?.defaultLanguage);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: <Widget>[
              const Text(
                'Профиль',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              _ProfileInfoCard(
                title: 'Основная информация',
                rows: <_ProfileRowData>[
                  _ProfileRowData('Имя', fullName),
                  _ProfileRowData('Telegram ID', telegramId),
                  _ProfileRowData('ID доступа', accessId),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (!_isEditingEmail) ...<Widget>[
                        Text(
                          hasEmail
                              ? 'Используется для входа в приложение и уведомлений. Сейчас: $currentEmail'
                              : 'Email не привязан. Добавьте его для альтернативного входа и уведомлений.',
                          style: const TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _startEditingEmail,
                          child: Text(
                            hasEmail ? 'Изменить email' : 'Привязать email',
                          ),
                        ),
                      ] else ...<Widget>[
                        const Text(
                          'Введите новый email.',
                          style: TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'name@example.com',
                            errorText: _emailError,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            FilledButton(
                              onPressed: _isSaving ? null : _saveEmail,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Сохранить'),
                            ),
                            TextButton(
                              onPressed: _isSaving ? null : _cancelEditingEmail,
                              child: const Text('Отмена'),
                            ),
                          ],
                        ),
                      ],
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
                        'Аккаунт',
                        style: TextStyle(
                          fontSize: 18,
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
                            label: isPaid
                                ? 'Платный период'
                                : isActive
                                ? 'Пробный или бесплатный период'
                                : 'Без активной подписки',
                            isPositive: isActive,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(label: 'Статус', value: statusText),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Доступ до', value: paidUntil),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Язык', value: language),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Создан через', value: createdVia),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => widget.sessionController.logout(),
                child: const Text('Выйти из аккаунта'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.title, required this.rows});

  final String title;
  final List<_ProfileRowData> rows;

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
            const SizedBox(height: 16),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InfoRow(label: row.label, value: row.value),
              ),
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 150,
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

class _ProfileRowData {
  const _ProfileRowData(this.label, this.value);

  final String label;
  final String value;
}
