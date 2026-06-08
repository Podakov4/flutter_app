import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  // Single key stores both tokens as JSON — one write is atomic.
  static const String _tokensKey = 'auth_tokens_v2';

  // Legacy keys from the old two-key layout; kept only for migration reads.
  static const String _legacyAccessKey = 'access_token';
  static const String _legacyRefreshKey = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(
      key: _tokensKey,
      value: jsonEncode(<String, String>{'a': accessToken, 'r': refreshToken}),
    );
  }

  Future<String?> getAccessToken() async => (await _readTokens())?.$1;

  Future<String?> getRefreshToken() async => (await _readTokens())?.$2;

  Future<void> clear() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _tokensKey),
      _storage.delete(key: _legacyAccessKey),
      _storage.delete(key: _legacyRefreshKey),
    ]);
  }

  Future<(String, String)?> _readTokens() async {
    final String? raw = await _storage.read(key: _tokensKey);
    if (raw != null) {
      try {
        final Map<String, dynamic> map =
            jsonDecode(raw) as Map<String, dynamic>;
        final String? a = map['a'] as String?;
        final String? r = map['r'] as String?;
        if (a != null && r != null) {
          return (a, r);
        }
      } catch (_) {}
    }

    // Migration: read old separate keys and return them once.
    // On next saveTokens() call they will be replaced by the new single key.
    final String? legacyAccess =
        await _storage.read(key: _legacyAccessKey);
    final String? legacyRefresh =
        await _storage.read(key: _legacyRefreshKey);
    if (legacyAccess != null && legacyRefresh != null) {
      return (legacyAccess, legacyRefresh);
    }

    return null;
  }
}
