import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter_sing_box/flutter_sing_box.dart' as sb;
import 'package:mmkv/mmkv.dart';

import '../../core/models/split_tunnel_config.dart';
import 'freeth_vpn_runtime_models.dart';
import 'sing_box_config_builder.dart';
import 'vless_uri.dart';

class FreethVpnRuntime {
  FreethVpnRuntime();

  static bool _initialized = false;

  final sb.FlutterSingBox _singBox = sb.FlutterSingBox();

  final StreamController<FreethVpnRuntimeSnapshot> _snapshots =
      StreamController<FreethVpnRuntimeSnapshot>.broadcast();

  StreamSubscription<sb.ProxyState>? _proxyStateSubscription;
  StreamSubscription<sb.ClientStatus>? _statusSubscription;
  StreamSubscription<List<String>>? _logSubscription;

  FreethVpnRuntimeSnapshot _snapshot = const FreethVpnRuntimeSnapshot(
    state: FreethVpnRuntimeState.idle,
  );

  bool get isSupported => io.Platform.isAndroid;

  Stream<FreethVpnRuntimeSnapshot> get snapshots => _snapshots.stream;

  FreethVpnRuntimeSnapshot get currentSnapshot => _snapshot;

  static Future<void> ensureInitialized(sb.FlutterSingBox singBox) async {
    if (_initialized) {
      return;
    }

    if (!io.Platform.isAndroid) {
      _initialized = true;
      return;
    }

    await MMKV.initialize();
    await singBox.init();

    _initialized = true;
  }

  Future<void> initialize() async {
    await ensureInitialized(_singBox);

    if (!isSupported) {
      return;
    }

    _proxyStateSubscription ??= _singBox.proxyStateStream.listen(
      _handleProxyState,
    );

    _statusSubscription ??= _singBox.connectedStatusStream.listen(
      _handleClientStatus,
    );

    _logSubscription ??= _singBox.logStream.listen((List<String> logs) {
      if (logs.isEmpty) {
        return;
      }

      _emit(_snapshot.copyWith(message: logs.last));
    });
  }

  Future<bool> start({
    required String vlessUrl,
    required String profileName,
    SplitTunnelConfig? splitTunnelConfig,
  }) async {
    if (!isSupported) {
      return false;
    }

    await initialize();

    _emit(
      _snapshot.copyWith(
        state: FreethVpnRuntimeState.starting,
        message: 'Starting',
      ),
    );

    try {
      final VlessUri vless = VlessUri.parse(vlessUrl);
      final Map<String, dynamic> config = const SingBoxConfigBuilder()
          .buildFromVless(vless, splitTunnelConfig: splitTunnelConfig);

      final sb.ProfileManager manager = sb.ProfileManager();

      _deleteOldRuntimeProfiles(manager);

      final int id = manager.generateProfileId;
      final String profilePath = await manager.getProfilePath(id);

      final io.Directory configDir = profilePath.endsWith('.json')
          ? io.File(profilePath).parent
          : io.Directory(profilePath);

      await configDir.create(recursive: true);

      final io.File usingConfigFile = io.File(
        '${configDir.path}/using_config.json',
      );

      await usingConfigFile.writeAsString(jsonEncode(config));

      final sb.Profile profile = sb.Profile(
        id: id,
        order: id,
        name: profileName.trim().isEmpty ? 'Freeth' : profileName.trim(),
        typed: sb.TypedProfile(
          type: sb.ProfileType.local,
          path: usingConfigFile.path,
          lastUpdated: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      manager.updateProfile(profile);
      manager.setSelectedProfile(id);

      // Native-часть flutter_sing_box читает именно эти MMKV-ключи.
      final MMKV profileKv = MMKV(
        'cs_profile',
        mode: MMKVMode.MULTI_PROCESS_MODE,
      );

      profileKv.encodeInt('selected_profile_id', id);
      profileKv.encodeString('using_config', configDir.path);

      final MMKV settingsKv = MMKV(
        'cs_settings',
        mode: MMKVMode.MULTI_PROCESS_MODE,
      );

      settingsKv.encodeString('service_mode', 'vpn');
      settingsKv.encodeInt('selected_profile', id);

      try {
        await _singBox.stopVpn();
      } catch (_) {
        // Сервис мог быть уже остановлен.
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));

      await _singBox.startVpn();

      // Важно: здесь НЕ говорим “подключено”.
      // Фактическое Started придёт через proxyStateStream.
      return true;
    } catch (error) {
      _emit(
        _snapshot.copyWith(
          state: FreethVpnRuntimeState.error,
          message: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<void> stop() async {
    if (!isSupported) {
      return;
    }

    await initialize();

    _emit(
      _snapshot.copyWith(
        state: FreethVpnRuntimeState.stopping,
        message: 'Stopping',
      ),
    );

    await _singBox.stopVpn();

    // Фактическое Stopped обычно придёт через proxyStateStream.
    // Оставляем fallback, чтобы UI не зависал, если stream задержался.
    _emit(
      _snapshot.copyWith(
        state: FreethVpnRuntimeState.stopped,
        message: 'Stopped',
      ),
    );
  }

  Future<void> dispose() async {
    await _proxyStateSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _logSubscription?.cancel();

    if (!_snapshots.isClosed) {
      await _snapshots.close();
    }
  }

  void _handleProxyState(sb.ProxyState state) {
    switch (state) {
      case sb.ProxyState.starting:
        _emit(
          _snapshot.copyWith(
            state: FreethVpnRuntimeState.starting,
            message: state.name,
          ),
        );
        return;

      case sb.ProxyState.started:
        _emit(
          _snapshot.copyWith(
            state: FreethVpnRuntimeState.started,
            message: state.name,
          ),
        );
        return;

      case sb.ProxyState.stopping:
        _emit(
          _snapshot.copyWith(
            state: FreethVpnRuntimeState.stopping,
            message: state.name,
          ),
        );
        return;

      case sb.ProxyState.stopped:
        _emit(
          _snapshot.copyWith(
            state: FreethVpnRuntimeState.stopped,
            message: state.name,
          ),
        );
        return;

      case sb.ProxyState.unknown:
        return;
    }
  }

  void _handleClientStatus(sb.ClientStatus status) {
    _emit(
      _snapshot.copyWith(
        uplink: status.uplink,
        downlink: status.downlink,
        uplinkTotal: status.uplinkTotal,
        downlinkTotal: status.downlinkTotal,
        trafficAvailable: status.trafficAvailable,
      ),
    );
  }

  void _emit(FreethVpnRuntimeSnapshot next) {
    _snapshot = next;

    if (_snapshots.isClosed) {
      return;
    }

    _snapshots.add(next);
  }

  void _deleteOldRuntimeProfiles(sb.ProfileManager manager) {
    final List<sb.Profile> profiles = manager.getProfiles();

    for (final sb.Profile profile in profiles) {
      if (profile.name.startsWith('Freeth')) {
        try {
          manager.deleteProfile(profile.id);
        } catch (_) {
          // Старый профиль мог быть занят или уже удалён.
        }
      }
    }
  }
}
