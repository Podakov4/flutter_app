import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  DeviceIdentityService({
    FlutterSecureStorage? storage,
    DeviceInfoPlugin? deviceInfoPlugin,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  static const String _deviceUidKey = 'freeth_device_uid';

  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfoPlugin;

  Future<DeviceIdentity> getIdentity() async {
    final String platform = _platformName();
    final String deviceUid = await _getOrCreateDeviceUid(platform);
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final _DeviceDetails details = await _resolveDeviceDetails(platform);

    return DeviceIdentity(
      deviceUid: deviceUid,
      platform: platform,
      deviceName: details.deviceName,
      appVersion: _formatAppVersion(packageInfo),
      osVersion: details.osVersion,
    );
  }

  Future<String> _getOrCreateDeviceUid(String platform) async {
    String? deviceUid = await _storage.read(key: _deviceUidKey);

    if (deviceUid == null || deviceUid.isEmpty) {
      deviceUid = _generateDeviceUid(platform);
      await _storage.write(key: _deviceUidKey, value: deviceUid);
    }

    return deviceUid;
  }

  Future<_DeviceDetails> _resolveDeviceDetails(String platform) async {
    try {
      final BaseDeviceInfo info = await _deviceInfoPlugin.deviceInfo;
      final Map<String, dynamic> data = info.data;

      if (platform == 'android') {
        return _androidDetails(data);
      }

      if (platform == 'web') {
        return _webDetails(data);
      }

      if (platform == 'ios') {
        return _iosDetails(data);
      }

      if (platform == 'linux') {
        return _linuxDetails(data);
      }

      if (platform == 'windows') {
        return _windowsDetails(data);
      }

      if (platform == 'macos') {
        return _macosDetails(data);
      }

      return _fallbackDetails(platform);
    } catch (_) {
      return _fallbackDetails(platform);
    }
  }

  _DeviceDetails _androidDetails(Map<String, dynamic> data) {
    final String brand = _title(_text(data['brand']));
    final String model = _text(data['model']);
    final Map<String, dynamic> version = _map(data['version']);
    final String release = _text(version['release']);
    final String sdk = _text(version['sdkInt']);

    return _DeviceDetails(
      deviceName: _joinUnique([brand, model], 'Android Device'),
      osVersion: release.isEmpty
          ? 'Android'
          : sdk.isEmpty
          ? 'Android $release'
          : 'Android $release, SDK $sdk',
    );
  }

  _DeviceDetails _webDetails(Map<String, dynamic> data) {
    final String browser = _title(_enumText(data['browserName']));
    final String platform = _text(data['platform']);
    final String vendor = _text(data['vendor']);

    return _DeviceDetails(
      deviceName: browser.isEmpty ? 'Web Browser' : '$browser Browser',
      osVersion: _joinUnique([platform, vendor], 'web'),
    );
  }

  _DeviceDetails _iosDetails(Map<String, dynamic> data) {
    final String name = _text(data['name']);
    final String model = _text(data['model']);
    final String systemName = _text(data['systemName']);
    final String systemVersion = _text(data['systemVersion']);

    return _DeviceDetails(
      deviceName: _joinUnique([name, model], 'iPhone'),
      osVersion: _joinUnique([systemName, systemVersion], 'iOS'),
    );
  }

  _DeviceDetails _linuxDetails(Map<String, dynamic> data) {
    final String prettyName = _text(data['prettyName']);
    final String name = _text(data['name']);
    final String version = _text(data['version']);

    return _DeviceDetails(
      deviceName: prettyName.isEmpty ? 'Linux Desktop' : prettyName,
      osVersion: _joinUnique([name, version], 'Linux'),
    );
  }

  _DeviceDetails _windowsDetails(Map<String, dynamic> data) {
    final String computerName = _text(data['computerName']);
    final String productName = _text(data['productName']);
    final String displayVersion = _text(data['displayVersion']);

    return _DeviceDetails(
      deviceName: computerName.isEmpty ? 'Windows Desktop' : computerName,
      osVersion: _joinUnique([productName, displayVersion], 'Windows'),
    );
  }

  _DeviceDetails _macosDetails(Map<String, dynamic> data) {
    final String computerName = _text(data['computerName']);
    final String osRelease = _text(data['osRelease']);

    return _DeviceDetails(
      deviceName: computerName.isEmpty ? 'macOS Desktop' : computerName,
      osVersion: osRelease.isEmpty ? 'macOS' : 'macOS $osRelease',
    );
  }

  _DeviceDetails _fallbackDetails(String platform) {
    if (platform == 'web') {
      return const _DeviceDetails(deviceName: 'Web Browser', osVersion: 'web');
    }

    if (platform == 'android') {
      return const _DeviceDetails(
        deviceName: 'Android Device',
        osVersion: 'Android',
      );
    }

    return _DeviceDetails(
      deviceName: '${_title(platform)} Device',
      osVersion: platform,
    );
  }

  String _platformName() {
    if (kIsWeb) {
      return 'web';
    }

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

  String _formatAppVersion(PackageInfo packageInfo) {
    if (packageInfo.buildNumber.isEmpty) {
      return packageInfo.version;
    }

    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  String _generateDeviceUid(String platform) {
    final Random random = Random.secure();
    final int timestamp = DateTime.now().microsecondsSinceEpoch;
    final String randomPart = List.generate(
      12,
      (_) => random.nextInt(16),
    ).map((int n) => n.toRadixString(16)).join();

    return 'freeth-$platform-$timestamp-$randomPart';
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }

    return {};
  }

  String _text(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  String _enumText(Object? value) {
    final String text = _text(value);
    if (!text.contains('.')) {
      return text;
    }

    return text.split('.').last;
  }

  String _title(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          if (part.length == 1) {
            return part.toUpperCase();
          }

          return part[0].toUpperCase() + part.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _joinUnique(List<String> values, String fallback) {
    final List<String> result = [];

    for (final String value in values) {
      final String normalized = value.trim();
      if (normalized.isEmpty) {
        continue;
      }

      final bool exists = result.any(
        (item) => item.toLowerCase() == normalized.toLowerCase(),
      );

      if (!exists) {
        result.add(normalized);
      }
    }

    if (result.isEmpty) {
      return fallback;
    }

    return result.join(' ');
  }
}

class _DeviceDetails {
  const _DeviceDetails({required this.deviceName, required this.osVersion});

  final String deviceName;
  final String osVersion;
}
