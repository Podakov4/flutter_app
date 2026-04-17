import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/access_api.dart';
import '../../../core/models/access_info.dart';
import '../../../core/models/connection_mode.dart';
import '../../../core/models/connection_state.dart';
import 'connection_log_entry.dart';

class ConnectionController extends ChangeNotifier {
  ConnectionController({required AccessApi accessApi}) : _accessApi = accessApi;

  final AccessApi _accessApi;

  AccessInfo? _access;
  ConnectionMode _mode = ConnectionMode.smart;
  ConnectionStatus _status = ConnectionStatus.idle;
  String? _selectedServerCode;
  String? _lastError;
  String _networkLabel = 'не определена';
  int _localPort = 10807;
  int _healthFailures = 0;
  bool _isLoading = false;

  final List<ConnectionLogEntry> _logs = <ConnectionLogEntry>[];

  AccessInfo? get access => _access;
  ConnectionMode get mode => _mode;
  ConnectionStatus get status => _status;
  String? get lastError => _lastError;
  String get networkLabel => _networkLabel;
  int get localPort => _localPort;
  int get healthFailures => _healthFailures;
  bool get isLoading => _isLoading;
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

  Future<void> loadAccess() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final AccessInfo value = await _accessApi.getAccess();
      _access = value;

      if (_selectedServerCode == null && availableServers.isNotEmpty) {
        _selectedServerCode = availableServers.first.code;
      }

      _logInfo('Конфигурация доступа обновлена');
    } catch (_) {
      _lastError = 'Не удалось загрузить данные подключения';
      _logError(_lastError!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connect() async {
    if (!canConnect) {
      _lastError = 'Подключение недоступно: активный доступ не найден';
      _status = ConnectionStatus.error;
      _logError(_lastError!);
      notifyListeners();
      return;
    }

    _lastError = null;
    _status = _status == ConnectionStatus.connected
        ? ConnectionStatus.reconnecting
        : ConnectionStatus.connecting;
    notifyListeners();

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
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_status == ConnectionStatus.disconnected ||
        _status == ConnectionStatus.idle) {
      return;
    }

    _logInfo('Отключение от Freeth');
    await Future<void>.delayed(const Duration(milliseconds: 150));

    _status = ConnectionStatus.disconnected;
    _healthFailures = 0;
    _logInfo('VPN отключён');
    notifyListeners();
  }

  Future<void> reconnect() async {
    _status = ConnectionStatus.reconnecting;
    notifyListeners();

    _logInfo('Фоновое переподключение...');
    await disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await connect();
  }

  void setSmartMode() {
    _mode = ConnectionMode.smart;
    _logInfo('Включён умный режим');
    notifyListeners();
  }

  void setManualMode() {
    _mode = ConnectionMode.manual;
    if (_selectedServerCode == null && availableServers.isNotEmpty) {
      _selectedServerCode = availableServers.first.code;
    }
    _logInfo('Включён ручной режим');
    notifyListeners();
  }

  void selectServer(String code) {
    _selectedServerCode = code;
    _mode = ConnectionMode.manual;

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

    notifyListeners();
  }

  void updateNetworkLabel(String value) {
    _networkLabel = value;
    _logInfo('Сеть: $value');
    notifyListeners();
  }

  Future<void> registerHealthSuccess() async {
    if (_healthFailures != 0 || _status == ConnectionStatus.degraded) {
      _healthFailures = 0;
      _status = ConnectionStatus.connected;
      _logInfo('Основной канал восстановлен');
      notifyListeners();
    }
  }

  Future<void> registerHealthFailure({String reason = 'timeout@step=3'}) async {
    _healthFailures += 1;
    _logWarning('Проверка основного канала: не прошла (reason=$reason)');
    _logWarning('Основной канал: сбой ($_healthFailures/2)');

    if (_healthFailures >= 2) {
      _status = ConnectionStatus.degraded;
      _logWarning(
        'Основной канал недоступен → переключение на резервный маршрут',
      );

      _localPort = _localPort == 10807 ? 10808 : 10807;
      _logInfo('Порт VPN изменился → $_localPort');
      notifyListeners();

      await reconnect();
    } else {
      notifyListeners();
    }
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  String exportLogs() {
    return _logs
        .map(
          (ConnectionLogEntry entry) =>
              '[${_formatTime(entry.timestamp)}] [${entry.levelLabel}] ${entry.message}',
        )
        .join('\n');
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
}
