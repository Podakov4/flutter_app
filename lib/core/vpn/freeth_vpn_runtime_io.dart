import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_sing_box/flutter_sing_box.dart' as sb;
import 'package:mmkv/mmkv.dart';

import 'sing_box_config_builder.dart';
import 'vless_uri.dart';

class FreethVpnRuntime {
  static bool _initialized = false;

  bool get isSupported => io.Platform.isAndroid;

  static Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }

    if (!io.Platform.isAndroid) {
      _initialized = true;
      return;
    }

    await MMKV.initialize();
    await sb.FlutterSingBox().init();

    _initialized = true;
  }

  Future<bool> start({
    required String vlessUrl,
    required String profileName,
  }) async {
    if (!isSupported) {
      return false;
    }

    await ensureInitialized();

    final VlessUri vless = VlessUri.parse(vlessUrl);
    final Map<String, dynamic> config = const SingBoxConfigBuilder()
        .buildFromVless(vless);

    final sb.ProfileManager manager = sb.ProfileManager();

    _deleteOldRuntimeProfiles(manager);

    final int id = manager.generateProfileId;
    final String path = await manager.getProfilePath(id);

    final sb.Profile profile = sb.Profile(
      id: id,
      order: id,
      name: profileName.trim().isEmpty ? 'Freeth' : profileName.trim(),
      typed: sb.TypedProfile(
        type: sb.ProfileType.local,
        path: path,
        lastUpdated: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await io.File(path).writeAsString(jsonEncode(config));

    manager.updateProfile(profile);
    manager.setSelectedProfile(id);

    try {
      await sb.FlutterSingBox().stopVpn();
    } catch (_) {}

    await Future<void>.delayed(const Duration(milliseconds: 500));

    await sb.FlutterSingBox().startVpn();

    return true;
  }

  Future<void> stop() async {
    if (!isSupported) {
      return;
    }

    await ensureInitialized();
    await sb.FlutterSingBox().stopVpn();
  }

  void _deleteOldRuntimeProfiles(sb.ProfileManager manager) {
    final List<sb.Profile> profiles = manager.getProfiles();

    for (final sb.Profile profile in profiles) {
      if (profile.name.startsWith('Freeth')) {
        try {
          manager.deleteProfile(profile.id);
        } catch (_) {}
      }
    }
  }
}
