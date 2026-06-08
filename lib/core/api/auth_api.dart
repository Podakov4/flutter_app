import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'api_client.dart';

class AuthApi {
  AuthApi({required ApiClient apiClient, required TokenStorage tokenStorage})
    : _apiClient = apiClient,
      _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<void> loginByCode({
    required String code,
    required String deviceUid,
    required String platform,
    String? deviceName,
    String? appVersion,
    String? osVersion,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/app/auth/login-by-code',
      data: <String, dynamic>{
        'code': code.trim(),
        'device_uid': deviceUid,
        'platform': platform,
        'device_name': deviceName,
        'app_version': appVersion,
        'os_version': osVersion,
      },
      options: Options(extra: <String, dynamic>{'skipAuthRefresh': true}),
    );

    await _saveTokensFromLoginResponse(response.data);
  }

  Future<int?> requestEmailCode(String email) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/app/auth/request-email-code',
      data: <String, dynamic>{'email': email.trim().toLowerCase()},
      options: Options(extra: <String, dynamic>{'skipAuthRefresh': true}),
    );

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      response.data as Map,
    );

    final dynamic cooldown = data['cooldown_seconds'];
    if (cooldown is int) {
      return cooldown;
    }
    if (cooldown is num) {
      return cooldown.toInt();
    }

    return null;
  }

  Future<void> verifyEmailCode({
    required String email,
    required String code,
    required String deviceUid,
    required String platform,
    String? deviceName,
    String? appVersion,
    String? osVersion,
  }) async {
    final Response<dynamic> response = await _apiClient.dio.post(
      '/app/auth/verify-email-code',
      data: <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'device_uid': deviceUid,
        'platform': platform,
        'device_name': deviceName,
        'app_version': appVersion,
        'os_version': osVersion,
      },
      options: Options(extra: <String, dynamic>{'skipAuthRefresh': true}),
    );

    await _saveTokensFromLoginResponse(response.data);
  }

  Future<bool> refreshTokens() {
    return _apiClient.refreshTokens();
  }

  Future<void> logout() async {
    final String? refreshToken = await _tokenStorage.getRefreshToken();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await _apiClient.dio.post(
          '/app/auth/logout',
          data: <String, dynamic>{'refresh_token': refreshToken},
          options: Options(extra: <String, dynamic>{'skipAuthRefresh': true}),
        );
      } catch (_) {}
    }

    await _tokenStorage.clear();
  }

  Future<void> _saveTokensFromLoginResponse(dynamic responseData) async {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      responseData as Map,
    );

    final Map<String, dynamic> tokens = Map<String, dynamic>.from(
      data['tokens'] as Map,
    );

    final String? accessToken = tokens['access_token'] as String?;
    final String? refreshToken = tokens['refresh_token'] as String?;

    if (accessToken == null || refreshToken == null) {
      throw StateError(
        'Сервер вернул неполные токены: access=${accessToken == null ? 'null' : 'ok'}, refresh=${refreshToken == null ? 'null' : 'ok'}',
      );
    }

    await _tokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
