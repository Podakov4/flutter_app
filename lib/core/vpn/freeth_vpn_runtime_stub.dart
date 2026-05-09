class FreethVpnRuntime {
  bool get isSupported => false;

  static Future<void> ensureInitialized() async {}

  Future<bool> start({
    required String vlessUrl,
    required String profileName,
  }) async {
    return false;
  }

  Future<void> stop() async {}
}
