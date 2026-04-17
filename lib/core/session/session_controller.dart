import 'package:flutter/foundation.dart';

import '../api/auth_api.dart';
import '../api/profile_api.dart';
import '../models/client_profile.dart';
import '../storage/token_storage.dart';

enum SessionStatus { unknown, authenticated, unauthenticated }

class SessionController extends ChangeNotifier {
  SessionController({
    required TokenStorage tokenStorage,
    required ProfileApi profileApi,
    required AuthApi authApi,
  }) : _tokenStorage = tokenStorage,
       _profileApi = profileApi,
       _authApi = authApi;

  final TokenStorage _tokenStorage;
  final ProfileApi _profileApi;
  final AuthApi _authApi;

  SessionStatus _status = SessionStatus.unknown;
  ClientProfile? _client;

  SessionStatus get status => _status;
  ClientProfile? get client => _client;

  Future<void> restoreSession() async {
    try {
      final String? accessToken = await _tokenStorage.getAccessToken();
      final String? refreshToken = await _tokenStorage.getRefreshToken();

      if ((accessToken == null || accessToken.isEmpty) &&
          (refreshToken == null || refreshToken.isEmpty)) {
        await _setUnauthenticated();
        return;
      }

      if (accessToken == null || accessToken.isEmpty) {
        final bool refreshed = await _authApi.refreshTokens();
        if (!refreshed) {
          await _setUnauthenticated(clearTokens: true);
          return;
        }
      }

      final ClientProfile client = await _profileApi.getMe();
      _setAuthenticated(client);
    } catch (_) {
      await _setUnauthenticated(clearTokens: true);
    }
  }

  Future<void> refreshMe() async {
    final ClientProfile client = await _profileApi.getMe();
    _setAuthenticated(client);
  }

  Future<void> markLoggedIn() async {
    await refreshMe();
  }

  Future<void> updateEmail(String? email) async {
    final ClientProfile client = await _profileApi.updateProfile(email: email);
    _setAuthenticated(client);
  }

  Future<void> logout() async {
    await _authApi.logout();
    await _setUnauthenticated();
  }

  void _setAuthenticated(ClientProfile client) {
    _client = client;
    _status = SessionStatus.authenticated;
    notifyListeners();
  }

  Future<void> _setUnauthenticated({bool clearTokens = false}) async {
    if (clearTokens) {
      await _tokenStorage.clear();
    }

    _client = null;
    _status = SessionStatus.unauthenticated;
    notifyListeners();
  }
}
