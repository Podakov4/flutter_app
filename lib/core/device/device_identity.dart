import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceUid,
    required this.platform,
    required this.deviceName,
    required this.appVersion,
    required this.osVersion,
  });

  final String deviceUid;
  final String platform;
  final String deviceName;
  final String appVersion;
  final String osVersion;
}

class DeviceIdentityService {
  DeviceIdentityService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _deviceUidKey = 'freeth_device_uid';

  final FlutterSecureStorage _storage;

  Future<DeviceIdentity> getIdentity() async {
    final String platform = _platformName();
    String? deviceUid = await _storage.read(key: _deviceUidKey);

    if (deviceUid == null || deviceUid.isEmpty) {
      deviceUid = _generateDeviceUid(platform);
      await _storage.write(key: _deviceUidKey, value: deviceUid);
    }

    return DeviceIdentity(
      deviceUid: deviceUid,
      platform: platform,
      deviceName: _deviceName(),
      appVersion: _appVersion(),
      osVersion: _osVersion(platform),
    );
  }

  String _platformName() {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  String _deviceName() {
    if (kIsWeb) return 'Web Browser';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android Device';
      case TargetPlatform.iOS:
        return 'iPhone';
      case TargetPlatform.windows:
        return 'Windows Desktop';
      case TargetPlatform.macOS:
        return 'macOS Desktop';
      case TargetPlatform.linux:
        return 'Linux Desktop';
      case TargetPlatform.fuchsia:
        return 'Fuchsia Device';
    }
  }

  String _osVersion(String platform) {
    if (kIsWeb) return 'web';
    return platform;
  }

  String _appVersion() {
    return '0.1.0';
  }

  String _generateDeviceUid(String platform) {
    final Random random = Random.secure();
    final int timestamp = DateTime.now().microsecondsSinceEpoch;

    final String randomPart = List<int>.generate(
      12,
      (_) => random.nextInt(16),
    ).map((int n) => n.toRadixString(16)).join();

    return 'freeth-$platform-$timestamp-$randomPart';
  }
}
