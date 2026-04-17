import 'dart:async';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage)
    : dio = Dio(_buildOptions()),
      _refreshDio = Dio(_buildOptions()) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final String? accessToken = await _tokenStorage.getAccessToken();

          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          final RequestOptions requestOptions = error.requestOptions;

          if (!_shouldAttemptRefresh(error)) {
            handler.next(error);
            return;
          }

          final bool refreshed = await refreshTokens();
          if (!refreshed) {
            handler.next(error);
            return;
          }

          try {
            final String? accessToken = await _tokenStorage.getAccessToken();
            final Map<String, dynamic> headers = Map<String, dynamic>.from(
              requestOptions.headers,
            );

            if (accessToken != null && accessToken.isNotEmpty) {
              headers['Authorization'] = 'Bearer $accessToken';
            } else {
              headers.remove('Authorization');
            }

            final Response<dynamic> response = await dio.fetch<dynamic>(
              requestOptions.copyWith(
                headers: headers,
                extra: <String, dynamic>{
                  ...requestOptions.extra,
                  'retryAfterRefresh': true,
                },
              ),
            );

            handler.resolve(response);
          } on DioException catch (retryError) {
            handler.next(retryError);
          } catch (_) {
            handler.next(error);
          }
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  final Dio dio;
  final Dio _refreshDio;
  Completer<bool>? _refreshCompleter;

  static BaseOptions _buildOptions() {
    return BaseOptions(
      baseUrl: AppEnv.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: <String, dynamic>{'Accept': 'application/json'},
    );
  }

  Future<bool> refreshTokens() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final Completer<bool> completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final String? refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _tokenStorage.clear();
        completer.complete(false);
        return completer.future;
      }

      final Response<dynamic> response = await _refreshDio.post(
        '/app/auth/refresh',
        data: <String, dynamic>{'refresh_token': refreshToken},
      );

      final Map<String, dynamic> data = Map<String, dynamic>.from(
        response.data as Map,
      );

      final String? newAccessToken = data['access_token'] as String?;
      final String? newRefreshToken = data['refresh_token'] as String?;

      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        await _tokenStorage.clear();
        completer.complete(false);
        return completer.future;
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      completer.complete(true);
      return completer.future;
    } catch (_) {
      await _tokenStorage.clear();
      completer.complete(false);
      return completer.future;
    } finally {
      _refreshCompleter = null;
    }
  }

  bool _shouldAttemptRefresh(DioException error) {
    final RequestOptions request = error.requestOptions;

    if (error.response?.statusCode != 401) {
      return false;
    }

    if (request.extra['skipAuthRefresh'] == true) {
      return false;
    }

    if (request.extra['retryAfterRefresh'] == true) {
      return false;
    }

    final String path = request.path;
    if (path.endsWith('/app/auth/refresh')) {
      return false;
    }

    return true;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
