import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/split_tunnel_config.dart';

class InstalledApp {
  const InstalledApp({required this.packageName, required this.name});
  final String packageName;
  final String name;
}

class SplitTunnelController extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel(
    'com.example.freeth_app/installed_apps',
  );
  static const String _modeKey = 'freeth.split_tunnel.mode';
  static const String _packagesKey = 'freeth.split_tunnel.packages';

  SplitTunnelMode _mode = SplitTunnelMode.all;
  Set<String> _selectedPackages = <String>{};
  List<InstalledApp> _installedApps = <InstalledApp>[];
  bool _appsLoading = false;
  bool _initialized = false;
  Future<void>? _initFuture;
  SharedPreferences? _prefs;

  SplitTunnelMode get mode => _mode;
  Set<String> get selectedPackages => Set<String>.unmodifiable(_selectedPackages);
  List<InstalledApp> get installedApps =>
      List<InstalledApp>.unmodifiable(_installedApps);
  bool get appsLoading => _appsLoading;

  bool isSelected(String packageName) => _selectedPackages.contains(packageName);

  SplitTunnelConfig get currentConfig => SplitTunnelConfig(
    mode: _mode,
    packages: _selectedPackages.toList(),
  );

  Future<void> ensureInitialized() {
    if (_initialized) return Future<void>.value();
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final String? savedMode = _prefs!.getString(_modeKey);
    _mode = switch (savedMode) {
      'includeOnly' => SplitTunnelMode.includeOnly,
      'excludeOnly' => SplitTunnelMode.excludeOnly,
      _ => SplitTunnelMode.all,
    };
    final String? savedPackages = _prefs!.getString(_packagesKey);
    if (savedPackages != null) {
      try {
        final List<dynamic> list = jsonDecode(savedPackages) as List<dynamic>;
        _selectedPackages = Set<String>.from(list.whereType<String>());
      } catch (_) {}
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setMode(SplitTunnelMode mode) async {
    await ensureInitialized();
    if (_mode == mode) return;
    _mode = mode;
    await _prefs?.setString(_modeKey, mode.name);
    notifyListeners();
  }

  Future<void> toggleApp(String packageName) async {
    if (_selectedPackages.contains(packageName)) {
      _selectedPackages.remove(packageName);
    } else {
      _selectedPackages.add(packageName);
    }
    await _prefs?.setString(
      _packagesKey,
      jsonEncode(_selectedPackages.toList()),
    );
    notifyListeners();
  }

  Future<void> loadInstalledApps() async {
    if (!io.Platform.isAndroid) return;
    if (_appsLoading || _installedApps.isNotEmpty) return;

    _appsLoading = true;
    notifyListeners();

    try {
      final List<dynamic> result =
          await _channel.invokeMethod<List<dynamic>>('getInstalledApps') ??
          <dynamic>[];
      _installedApps = result
          .map((dynamic item) {
            final Map<String, dynamic> map = Map<String, dynamic>.from(
              item as Map,
            );
            return InstalledApp(
              packageName: (map['packageName'] as String?) ?? '',
              name: (map['name'] as String?) ?? '',
            );
          })
          .where((InstalledApp app) => app.packageName.isNotEmpty)
          .toList();
    } catch (_) {
      _installedApps = <InstalledApp>[];
    } finally {
      _appsLoading = false;
      notifyListeners();
    }
  }
}
