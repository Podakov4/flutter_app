import 'package:dio/dio.dart';

import '../models/client_profile.dart';
import 'api_client.dart';

class ProfileApi {
  ProfileApi(this._apiClient);

  final ApiClient _apiClient;

  Future<ClientProfile> getMe() async {
    final Response<dynamic> response = await _apiClient.dio.get('/me');

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      response.data as Map,
    );

    return ClientProfile.fromJson(
      Map<String, dynamic>.from(data['client'] as Map),
    );
  }

  Future<ClientProfile> updateProfile({required String? email}) async {
    final Response<dynamic> response = await _apiClient.dio.patch(
      '/me/profile',
      data: <String, dynamic>{'email': email},
    );

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      response.data as Map,
    );

    return ClientProfile.fromJson(
      Map<String, dynamic>.from(data['client'] as Map),
    );
  }
}
