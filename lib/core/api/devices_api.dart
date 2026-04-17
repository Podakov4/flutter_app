import 'package:dio/dio.dart';

import '../models/device_info.dart';
import 'api_client.dart';

class DevicesResponse {
  const DevicesResponse({
    required this.devices,
    required this.maxDevices,
    required this.activeDevices,
    required this.canAddMore,
    required this.currentDeviceId,
  });

  final List<DeviceInfo> devices;
  final int maxDevices;
  final int activeDevices;
  final bool canAddMore;
  final int? currentDeviceId;
}

class DevicesApi {
  DevicesApi(this._apiClient);

  final ApiClient _apiClient;

  Future<DevicesResponse> getDevices() async {
    final Response<dynamic> response = await _apiClient.dio.get('/me/devices');

    final Map<String, dynamic> data = Map<String, dynamic>.from(
      response.data as Map,
    );

    final List<dynamic> rawDevices = (data['devices'] as List?) ?? <dynamic>[];
    final Map<String, dynamic> limit = Map<String, dynamic>.from(
      data['limit'] as Map? ?? <String, dynamic>{},
    );

    return DevicesResponse(
      devices: rawDevices
          .map(
            (item) =>
                DeviceInfo.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      maxDevices: (limit['max_devices'] as num?)?.toInt() ?? 0,
      activeDevices: (limit['active_devices'] as num?)?.toInt() ?? 0,
      canAddMore: limit['can_add_more'] == true,
      currentDeviceId: (data['current_device_id'] as num?)?.toInt(),
    );
  }

  Future<void> revokeDevice(int deviceId) async {
    await _apiClient.dio.post(
      '/me/devices/revoke',
      data: <String, dynamic>{'device_id': deviceId},
    );
  }
}
