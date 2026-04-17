import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; // Добавлен импорт

import '../../../core/api/auth_api.dart';
import '../../../core/device/device_identity.dart';
import '../../../core/session/session_controller.dart';

enum _AuthMethod { email, telegram }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authApi,
    required this.sessionController,
  });

  final AuthApi authApi;
  final SessionController sessionController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailCodeController = TextEditingController();
  final TextEditingController _telegramCodeController = TextEditingController();
  final DeviceIdentityService _deviceIdentityService = DeviceIdentityService();

  _AuthMethod _authMethod = _AuthMethod.email;
  bool _isSendingEmailCode = false;
  bool _isVerifyingEmail = false;
  bool _isVerifyingTelegram = false;
  bool _emailCodeRequested = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  String? _errorText;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _emailCodeController.dispose();
    _telegramCodeController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Введите email';
    }

    final RegExp regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(email)) {
      return 'Введите корректный email';
    }

    return null;
  }

  String? _validateEmailCode(String? value) {
    if (!_emailCodeRequested) {
      return null;
    }

    final String code = (value ?? '').trim();
    if (code.isEmpty) {
      return 'Введите код из письма';
    }
    if (code.length != 6) {
      return 'Код должен содержать 6 цифр';
    }
    return null;
  }

  String? _validateTelegramCode(String? value) {
    final String code = (value ?? '').trim();
    if (code.isEmpty) {
      return 'Введите код из Telegram';
    }
    if (code.length < 4) {
      return 'Код слишком короткий';
    }
    return null;
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

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();

    setState(() {
      _cooldownSeconds = seconds;
    });

    if (seconds <= 0) {
      return;
    }

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
        });
        return;
      }

      setState(() {
        _cooldownSeconds -= 1;
      });
    });
  }

  Future<void> _requestEmailCode() async {
    final String? emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() {
        _errorText = emailError;
      });
      return;
    }

    if (_cooldownSeconds > 0) {
      return;
    }

    setState(() {
      _isSendingEmailCode = true;
      _errorText = null;
    });

    try {
      final int cooldownSeconds =
          await widget.authApi.requestEmailCode(_emailController.text) ?? 0;

      if (!mounted) {
        return;
      }

      setState(() {
        _emailCodeRequested = true;
        _emailCodeController.clear();
      });
      _startCooldown(cooldownSeconds);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Код отправлен на почту'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = _extractErrorMessage(error, 'Не удалось отправить код');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingEmailCode = false;
        });
      }
    }
  }

  Future<void> _verifyEmailCode() async {
    final String? emailError = _validateEmail(_emailController.text);
    final String? codeError = _validateEmailCode(_emailCodeController.text);

    if (emailError != null || codeError != null) {
      setState(() {
        _errorText = emailError ?? codeError;
      });
      return;
    }

    setState(() {
      _isVerifyingEmail = true;
      _errorText = null;
    });

    try {
      final DeviceIdentity identity = await _deviceIdentityService
          .getIdentity();

      await widget.authApi.verifyEmailCode(
        email: _emailController.text,
        code: _emailCodeController.text,
        deviceUid: identity.deviceUid,
        platform: identity.platform,
        deviceName: identity.deviceName,
        appVersion: identity.appVersion,
        osVersion: identity.osVersion,
      );

      await widget.sessionController.markLoggedIn();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = _extractErrorMessage(
          error,
          'Не удалось выполнить вход по email',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingEmail = false;
        });
      }
    }
  }

  Future<void> _verifyTelegramCode() async {
    final String? codeError = _validateTelegramCode(
      _telegramCodeController.text,
    );
    if (codeError != null) {
      setState(() {
        _errorText = codeError;
      });
      return;
    }

    setState(() {
      _isVerifyingTelegram = true;
      _errorText = null;
    });

    try {
      final DeviceIdentity identity = await _deviceIdentityService
          .getIdentity();

      await widget.authApi.loginByCode(
        code: _telegramCodeController.text,
        deviceUid: identity.deviceUid,
        platform: identity.platform,
        deviceName: identity.deviceName,
        appVersion: identity.appVersion,
        osVersion: identity.osVersion,
      );

      await widget.sessionController.markLoggedIn();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorText = _extractErrorMessage(
          error,
          'Не удалось выполнить вход по коду из Telegram',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingTelegram = false;
        });
      }
    }
  }

  void _switchAuthMethod(_AuthMethod method) {
    setState(() {
      _authMethod = method;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Center(
                  child: Image.asset('assets/images/logo.png', height: 150),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text(
                          'Вход в Freeth',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Выберите удобный способ входа: через email или с помощью кода из Telegram-бота.',
                          style: TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        SegmentedButton<_AuthMethod>(
                          segments: const <ButtonSegment<_AuthMethod>>[
                            ButtonSegment<_AuthMethod>(
                              value: _AuthMethod.email,
                              label: Text('Email'),
                              icon: Icon(Icons.email_outlined),
                            ),
                            ButtonSegment<_AuthMethod>(
                              value: _AuthMethod.telegram,
                              label: Text('Telegram'),
                              icon: Icon(Icons.telegram),
                            ),
                          ],
                          selected: <_AuthMethod>{_authMethod},
                          onSelectionChanged: (Set<_AuthMethod> selection) {
                            _switchAuthMethod(selection.first);
                          },
                        ),
                        const SizedBox(height: 24),
                        if (_authMethod == _AuthMethod.email) ...<Widget>[
                          const Text(
                            'Введите email. Мы отправим одноразовый код для входа.',
                            style: TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const <String>[AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'Например: user@example.com',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed:
                                _isSendingEmailCode || _cooldownSeconds > 0
                                ? null
                                : _requestEmailCode,
                            child: _isSendingEmailCode
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _emailCodeRequested
                                        ? _cooldownSeconds > 0
                                              ? 'Повторная отправка через $_cooldownSeconds сек'
                                              : 'Отправить код ещё раз'
                                        : 'Получить код',
                                  ),
                          ),
                          if (_emailCodeRequested) ...<Widget>[
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailCodeController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              onFieldSubmitted: (_) => _verifyEmailCode(),
                              decoration: const InputDecoration(
                                labelText: 'Код из письма',
                                hintText: '6 цифр',
                                counterText: '',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _isVerifyingEmail
                                  ? null
                                  : _verifyEmailCode,
                              child: _isVerifyingEmail
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Войти по email'),
                            ),
                          ],
                        ] else ...<Widget>[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Откройте Telegram-бота Freeth, выберите «Войти в приложение» и получите одноразовый код. Затем введите его ниже.',
                              style: TextStyle(height: 1.4),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // --- ИЗМЕНЕННАЯ КНОПКА ТУТ ---
                          OutlinedButton.icon(
                            onPressed: () async {
                              final Uri botUrl = Uri.parse(
                                'https://t.me/youFreethBot',
                              );
                              if (await canLaunchUrl(botUrl)) {
                                await launchUrl(
                                  botUrl,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Не удалось открыть ссылку',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Открыть Telegram-бота'),
                          ),
                          // -----------------------------
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _telegramCodeController,
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.characters,
                            onFieldSubmitted: (_) => _verifyTelegramCode(),
                            decoration: const InputDecoration(
                              labelText: 'Код из Telegram',
                              hintText: 'Например: ABCD2345',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _isVerifyingTelegram
                                ? null
                                : _verifyTelegramCode,
                            child: _isVerifyingTelegram
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Войти по коду из Telegram'),
                          ),
                        ],
                        if (_errorText != null) ...<Widget>[
                          const SizedBox(height: 16),
                          Text(
                            _errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        const Text(
                          'Продолжая, вы принимаете условия сервиса Freeth и соглашаетесь с обработкой данных в соответствии с документами ниже.',
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            TextButton(
                              onPressed: () =>
                                  context.push('/legal/user-agreement'),
                              child: const Text('Пользовательское соглашение'),
                            ),
                            TextButton(
                              onPressed: () => context.push('/legal/privacy'),
                              child: const Text('Политика конфиденциальности'),
                            ),
                            TextButton(
                              onPressed: () => context.push('/legal/refund'),
                              child: const Text('Политика возвратов'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
