import 'dart:async';

import 'freeth_vpn_runtime_models.dart';

class FreethVpnRuntime {
  FreethVpnRuntime();

  final StreamController<FreethVpnRuntimeSnapshot> _snapshots =
      StreamController<FreethVpnRuntimeSnapshot>.broadcast();

  bool get isSupported => false;

  Stream<FreethVpnRuntimeSnapshot> get snapshots => _snapshots.stream;

  FreethVpnRuntimeSnapshot get currentSnapshot =>
      const FreethVpnRuntimeSnapshot(state: FreethVpnRuntimeState.idle);

  static Future<void> ensureInitialized() async {}

  Future<void> initialize() async {}

  Future<bool> start({
    required String vlessUrl,
    required String profileName,
  }) async {
    return false;
  }

  Future<void> stop() async {}

  Future<void> dispose() async {
    await _snapshots.close();
  }
}
