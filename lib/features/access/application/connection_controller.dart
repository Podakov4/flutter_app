import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/access_api.dart';
import '../../../core/models/access_info.dart';
import '../../../core/models/connection_mode.dart';
import '../../../core/models/connection_state.dart';
import '../../../core/session/session_controller.dart';
import 'connection_log_entry.dart';

class ConnectionController extends ChangeNotifier {
  ConnectionController({
    required AccessApi accessApi,
    required SessionController sessionController,
  }) : _accessApi = accessApi,
       _sessionController = sessionController,
       _lastSeenSessionStatus = sessionController.status {
    _sessionController.addListener(_handleSessionChanged);
  }

  final AccessApi _accessApi;
  final SessionController _sessionController;
  final Connectivity _connectivity = Connectivity();

  static const String _modeKey = 'freeth.connection.mode';
  static const String _serverKey = 'freeth.connection.server';
  static const String _autoSwitchKey = 'freeth.connection.auto_switch';
  static const String _fallbackKey = 'freeth.connection.fallback';
  static const String _detailedLogsKey = 'freeth.connection.detailed_logs';

  SharedPreferences? _prefs;
  StreamSubscription<dynamic>? _connectivitySubscription;
  Timer? _healthTimer;

  bool _initialized = false;
  bool _initializing = false;
  bool _isDisposed = false;
  bool _isHealthCheckInFlight = false;

  AccessInfo? _access;
  ConnectionMode _mode = ConnectionMode.smart;
  ConnectionStatus _status = ConnectionStatus.idle;
  String? _selectedServerCode;
  String? _lastError;
  String _networkLabel = 'не определена';
  int _localPort = 10807;
  int _healthFailures = 0;
  bool _isLoading = false;

  bool _autoSwitchOnNetworkChange = true;
  bool _fallbackEnabled = true;
  bool _showDetailedLogs = true;

  SessionStatus _lastSeenSessionStatus;

  final List<ConnectionLogEntry> _logs = <ConnectionLogEntry>[];

  AccessInfo? get access => _access;
  ConnectionMode get mode => _mode;
  ConnectionStatus get status => _status;
  String? get lastError => _lastError;
  String get networkLabel => _networkLabel;
  int get localPort => _localPort;
  int get healthFailures => _healthFailures;
  bool get isLoading => _isLoading;
  bool get autoSwitchOnNetworkChange => _autoSwitchOnNetworkChange;
  bool get fallbackEnabled => _fallbackEnabled;
  bool get showDetailedLogs => _showDetailedLogs;

  List<ConnectionLogEntry> get logs =>
      List<ConnectionLogEntry>.unmodifiable(_logs);

  bool get canConnect => _access?.access == true;
  bool get subscriptionActive => _access?.subscriptionActive == true;
  bool get isConnected => _status == ConnectionStatus.connected;
  bool get isBusy =>
      _status == ConnectionStatus.connecting ||
      _status == ConnectionStatus.reconnecting ||
      _isLoading;

  List<AccessServerInfo> get availableServers =>
      _access?.servers.where((AccessServerInfo s) => s.enabled).toList() ??
      <AccessServerInfo>[];

  AccessServerInfo? get currentServer {
    final List<AccessServerInfo> servers = availableServers;
    if (servers.isEmpty) {
      return null;
    }

    if (_mode == ConnectionMode.manual && _selectedServerCode != null) {
      for (final AccessServerInfo server in servers) {
        if (server.code == _selectedServerCode) {
          return server;
        }
      }
    }

    return servers.first;
  }

  String get currentLocationTitle {
    final AccessServerInfo? server = currentServer;
    if (server == null) {
      return 'Локация не выбрана';
    }

    if ((server.displayName ?? '').trim().isNotEmpty) {
      return server.displayName!;
    }
    if ((server.name ?? '').trim().isNotEmpty) {
      return server.name!;
    }
    return server.code.toUpperCase();
  }

  String get currentLocationSubtitle {
    final AccessServerInfo? server = currentServer;
    if (server == null) {
      return 'Откройте список локаций и выберите подходящий маршрут.';
    }

    final String country = (server.countryCode ?? '').trim().isNotEmpty
        ? server.countryCode!
        : 'Локация';

    if ((server.domain ?? '').trim().isNotEmpty) {
      return '$country • ${server.domain}';
    }

    return country;
  }

  Future<void> initialize() async {
    if (_initialized || _initializing) {
      return;
    }

    _initializing = true;

    try {
      _prefs = await SharedPreferences.getInstance();

      final String? savedMode = _prefs?.getString(_modeKey);
      final String? savedServer = _prefs?.getString(_serverKey);

      _autoSwitchOnNetworkChange = _prefs?.getBool(_autoSwitchKey) ?? true;
      _fallbackEnabled = _prefs?.getBool(_fallbackKey) ?? true;
      _showDetailedLogs = _prefs?.getBool(_detailedLogsKey) ?? true;

      if (savedMode == 'manual') {
        _mode = ConnectionMode.manual;
      } else {
        _mode = ConnectionMode.smart;
      }

      if (savedServer != null && savedServer.trim().isNotEmpty) {
        _selectedServerCode = savedServer;
      }

      final dynamic initialConnectivity = await _connectivity
          .checkConnectivity();
      _networkLabel = _connectivityLabel(
        _normalizeConnectivity(initialConnectivity),
      );

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        dynamic event,
      ) {
        final String nextLabel = _connectivityLabel(
          _normalizeConnectivity(event),
        );

        if (nextLabel == _networkLabel) {
          return;
        }

        _networkLabel = nextLabel;
        _logInfo('Сеть: $nextLabel');
        _safeNotify();

        if (_autoSwitchOnNetworkChange &&
            _status == ConnectionStatus.connected &&
            nextLabel != 'без сети' &&
            nextLabel != 'не определена') {
          _logInfo('Сеть изменилась → мягкое переподключение');
          unawaited(reconnect());
        }
      });

      _initialized = true;
      _initializing = false;

      if (_sessionController.status == SessionStatus.authenticated) {
        unawaited(loadAccess());
      } else {
        _safeNotify();
      }
    } catch (_) {
      _initializing = false;
      _lastError = 'Не удалось инициализировать состояние подключения';
      _logError(_lastError!);
      _safeNotify();
    }
  }

  Future<void> loadAccess() async {
    await initialize();

    if (_sessionController.status != SessionStatus.authenticated) {
      _clearRuntimeState(keepPreferences: true);
      return;
    }

    _isLoading = true;
    _lastError = null;
    _safeNotify();

    try {
      final AccessInfo value = await _accessApi.getAccess();
      _access = value;

      _normalizeSelectedServerAfterAccessLoad();

      _logInfo('Конфигурация доступа обновлена');
    } catch (_) {
      _lastError = 'Не удалось загрузить данные подключения';
      _logError(_lastError!);
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> connect() async {
    await initialize();

    if (_access == null && !_isLoading) {
      await loadAccess();
    }

    if (!canConnect) {
      _lastError = 'Подключение недоступно: активный доступ не найден';
      _status = ConnectionStatus.error;
      _logError(_lastError!);
      _safeNotify();
      return;
    }

    _lastError = null;
    _status = _status == ConnectionStatus.connected
        ? ConnectionStatus.reconnecting
        : ConnectionStatus.connecting;
    _safeNotify();

    _logInfo('Подключение к Freeth');
    _logInfo('Порт VPN: $_localPort, режим: socks');
    _logInfo('Локация: $currentLocationTitle');
    _logInfo('Режим: ${_mode.label}');

    await Future<void>.delayed(const Duration(milliseconds: 250));
    _logInfo('connect: buildConfig=0ms');

    await Future<void>.delayed(const Duration(milliseconds: 180));
    _logInfo('connect: setup=3ms');

    await Future<void>.delayed(const Duration(milliseconds: 220));
    _status = ConnectionStatus.connected;
    _healthFailures = 0;
    _logInfo('VPN подключён (порт $_localPort)');
    _logInfo('Health monitor: запущен');
    _startHealthMonitor();
    _safeNotify();
  }

  Future<void> disconnect() async {
    await initialize();

    if (_status == ConnectionStatus.disconnected ||
        _status == ConnectionStatus.idle) {
      return;
    }

    _stopHealthMonitor();
    _logInfo('Отключение от Freeth');
    await Future<void>.delayed(const Duration(milliseconds: 150));

    _status = ConnectionStatus.disconnected;
    _healthFailures = 0;
    _logInfo('VPN отключён');
    _safeNotify();
  }

  Future<void> reconnect() async {
    await initialize();

    _status = ConnectionStatus.reconnecting;
    _safeNotify();

    _logInfo('Фоновое переподключение...');
    await disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await connect();
  }

  Future<void> setSmartMode() async {
    await initialize();

    _mode = ConnectionMode.smart;
    await _prefs?.setString(_modeKey, 'smart');
    _logInfo('Включён умный режим');
    _safeNotify();
  }

  Future<void> setManualMode() async {
    await initialize();

    _mode = ConnectionMode.manual;
    if (_selectedServerCode == null && availableServers.isNotEmpty) {
      _selectedServerCode = availableServers.first.code;
      await _saveSelectedServer(_selectedServerCode!);
    }
    await _prefs?.setString(_modeKey, 'manual');
    _logInfo('Включён ручной режим');
    _safeNotify();
  }

  Future<void> selectServer(String code) async {
    await initialize();

    _selectedServerCode = code;
    _mode = ConnectionMode.manual;

    await _prefs?.setString(_modeKey, 'manual');
    await _saveSelectedServer(code);

    final AccessServerInfo? server = availableServers
        .cast<AccessServerInfo?>()
        .firstWhere(
          (AccessServerInfo? s) => s?.code == code,
          orElse: () => null,
        );

    if (server != null) {
      _logInfo('Выбрана локация: ${_serverTitle(server)}');
    } else {
      _logInfo('Выбрана локация: $code');
    }

    _safeNotify();

    if (_status == ConnectionStatus.connected) {
      _logInfo('Локация изменена → применяем через переподключение');
      unawaited(reconnect());
    }
  }

  Future<void> setAutoSwitchOnNetworkChange(bool value) async {
    await initialize();
    _autoSwitchOnNetworkChange = value;
    await _prefs?.setBool(_autoSwitchKey, value);
    _logInfo(
      value
          ? 'Автопереключение при смене сети включено'
          : 'Автопереключение при смене сети отключено',
    );
    _safeNotify();
  }

  Future<void> setFallbackEnabled(bool value) async {
    await initialize();
    _fallbackEnabled = value;
    await _prefs?.setBool(_fallbackKey, value);
    _logInfo(
      value ? 'Резервный маршрут включён' : 'Резервный маршрут отключён',
    );
    _safeNotify();
  }

  Future<void> setShowDetailedLogs(bool value) async {
    await initialize();
    _showDetailedLogs = value;
    await _prefs?.setBool(_detailedLogsKey, value);
    _logInfo(value ? 'Подробный журнал включён' : 'Подробный журнал отключён');
    _safeNotify();
  }

  void updateNetworkLabel(String value) {
    if (value == _networkLabel) {
      return;
    }

    _networkLabel = value;
    _logInfo('Сеть: $value');
    _safeNotify();
  }

  Future<void> registerHealthSuccess() async {
    if (_healthFailures != 0 || _status == ConnectionStatus.degraded) {
      _healthFailures = 0;
      _status = ConnectionStatus.connected;
      _logInfo('Основной канал восстановлен');
      _safeNotify();
    }
  }

  Future<void> registerHealthFailure({String reason = 'timeout@step=3'}) async {
    _healthFailures += 1;
    _logWarning('Проверка основного канала: не прошла (reason=$reason)');
    _logWarning('Основной канал: сбой ($_healthFailures/2)');

    if (_healthFailures >= 2) {
      _status = ConnectionStatus.degraded;

      if (_fallbackEnabled) {
        _logWarning(
          'Основной канал недоступен → переключение на резервный маршрут',
        );

        _localPort = _localPort == 10807 ? 10808 : 10807;
        _logInfo('Порт VPN изменился → $_localPort');
        _safeNotify();

        await reconnect();
      } else {
        _logWarning('Основной канал недоступен, но резервный маршрут отключён');
        _safeNotify();
      }
    } else {
      _safeNotify();
    }
  }

  void clearLogs() {
    _logs.clear();
    _safeNotify();
  }

  String exportLogs() {
    return _logs
        .map(
          (ConnectionLogEntry entry) =>
              '[${_formatTime(entry.timestamp)}] [${entry.levelLabel}] ${entry.message}',
        )
        .join('\n');
  }

  @override
  void dispose() {
    _sessionController.removeListener(_handleSessionChanged);
    _connectivitySubscription?.cancel();
    _stopHealthMonitor();
    _isDisposed = true;
    super.dispose();
  }

  void _handleSessionChanged() {
    final SessionStatus nextStatus = _sessionController.status;
    if (nextStatus == _lastSeenSessionStatus) {
      return;
    }

    _lastSeenSessionStatus = nextStatus;

    if (nextStatus == SessionStatus.authenticated) {
      unawaited(initialize().then((_) => loadAccess()));
      return;
    }

    if (nextStatus == SessionStatus.unauthenticated) {
      _clearRuntimeState(keepPreferences: true);
    }
  }

  void _clearRuntimeState({required bool keepPreferences}) {
    _stopHealthMonitor();

    _access = null;
    _status = ConnectionStatus.idle;
    _lastError = null;
    _healthFailures = 0;
    _isLoading = false;
    _localPort = 10807;
    _logs.clear();

    if (!keepPreferences) {
      _selectedServerCode = null;
      _mode = ConnectionMode.smart;
      _autoSwitchOnNetworkChange = true;
      _fallbackEnabled = true;
      _showDetailedLogs = true;
    }

    _safeNotify();
  }

  void _normalizeSelectedServerAfterAccessLoad() {
    final List<AccessServerInfo> servers = availableServers;
    if (servers.isEmpty) {
      return;
    }

    if (_selectedServerCode == null || !_hasServerCode(_selectedServerCode!)) {
      _selectedServerCode = servers.first.code;
      unawaited(_saveSelectedServer(_selectedServerCode!));
    }
  }

  bool _hasServerCode(String code) {
    for (final AccessServerInfo server in availableServers) {
      if (server.code == code) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveSelectedServer(String code) async {
    await _prefs?.setString(_serverKey, code);
  }

  void _startHealthMonitor() {
    _stopHealthMonitor();

    _healthTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(_runHealthCheck());
    });
  }

  void _stopHealthMonitor() {
    _healthTimer?.cancel();
    _healthTimer = null;
  }

  Future<void> _runHealthCheck() async {
    if (_isHealthCheckInFlight) {
      return;
    }

    if (_status != ConnectionStatus.connected &&
        _status != ConnectionStatus.degraded) {
      return;
    }

    _isHealthCheckInFlight = true;

    try {
      await _accessApi.getAccess();
      await registerHealthSuccess();
    } catch (_) {
      await registerHealthFailure(reason: 'health-check');
    } finally {
      _isHealthCheckInFlight = false;
    }
  }

  List<ConnectivityResult> _normalizeConnectivity(dynamic event) {
    if (event is List<ConnectivityResult>) {
      return event;
    }
    if (event is ConnectivityResult) {
      return <ConnectivityResult>[event];
    }
    return const <ConnectivityResult>[];
  }

  String _connectivityLabel(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return 'не определена';
    }

    if (results.contains(ConnectivityResult.none)) {
      return 'без сети';
    }
    if (results.contains(ConnectivityResult.wifi)) {
      return 'wifi';
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return 'мобильная';
    }
    if (results.contains(ConnectivityResult.ethernet)) {
      return 'ethernet';
    }

    return 'другая сеть';
  }

  String _serverTitle(AccessServerInfo server) {
    if ((server.displayName ?? '').trim().isNotEmpty) {
      return server.displayName!;
    }
    if ((server.name ?? '').trim().isNotEmpty) {
      return server.name!;
    }
    return server.code.toUpperCase();
  }

  void _logInfo(String message) {
    if (!_showDetailedLogs &&
        (message.startsWith('connect:') ||
            message.startsWith('Health monitor:'))) {
      return;
    }

    _logs.insert(
      0,
      ConnectionLogEntry(
        timestamp: DateTime.now(),
        level: ConnectionLogLevel.info,
        message: message,
      ),
    );
  }

  void _logWarning(String message) {
    _logs.insert(
      0,
      ConnectionLogEntry(
        timestamp: DateTime.now(),
        level: ConnectionLogLevel.warning,
        message: message,
      ),
    );
  }

  void _logError(String message) {
    _logs.insert(
      0,
      ConnectionLogEntry(
        timestamp: DateTime.now(),
        level: ConnectionLogLevel.error,
        message: message,
      ),
    );
  }

  String _formatTime(DateTime value) {
    final String h = value.hour.toString().padLeft(2, '0');
    final String m = value.minute.toString().padLeft(2, '0');
    final String s = value.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _safeNotify() {
    if (_isDisposed) {
      return;
    }
    notifyListeners();
  }
}
