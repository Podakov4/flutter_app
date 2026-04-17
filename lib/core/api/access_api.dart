import 'package:dio/dio.dart';

import '../models/access_info.dart';
import 'api_client.dart';

class AccessApi {
  AccessApi(this._apiClient);

  final ApiClient _apiClient;

  Future<AccessInfo> getAccess() async {
    final Response<dynamic> response = await _apiClient.dio.get('/vpn/access');

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      response.data as Map,
    );

    final Object? accessRaw = data['access'];
    if (accessRaw is! Map) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Некорректный ответ /vpn/access: отсутствует поле access',
      );
    }

    return AccessInfo.fromJson(Map<String, dynamic>.from(accessRaw));
  }
}
