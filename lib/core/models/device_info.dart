class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.deviceUid,
    required this.platform,
    required this.deviceName,
    required this.appVersion,
    required this.osVersion,
    required this.isActive,
    required this.isRevoked,
    required this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String? deviceUid;
  final String? platform;
  final String? deviceName;
  final String? appVersion;
  final String? osVersion;
  final bool isActive;
  final bool isRevoked;
  final String? lastSeenAt;
  final String? createdAt;
  final String? updatedAt;

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      deviceUid: json['device_uid'] as String?,
      platform: json['platform'] as String?,
      deviceName: json['device_name'] as String?,
      appVersion: json['app_version'] as String?,
      osVersion: json['os_version'] as String?,
      isActive: json['is_active'] == true,
      isRevoked: json['is_revoked'] == true,
      lastSeenAt: json['last_seen_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
