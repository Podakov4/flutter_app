enum ConnectionStatus {
  idle,
  connecting,
  connected,
  reconnecting,
  degraded,
  disconnected,
  error,
}

extension ConnectionStatusX on ConnectionStatus {
  String get label {
    switch (this) {
      case ConnectionStatus.idle:
        return 'Ожидание';
      case ConnectionStatus.connecting:
        return 'Подключение';
      case ConnectionStatus.connected:
        return 'Подключено';
      case ConnectionStatus.reconnecting:
        return 'Переподключение';
      case ConnectionStatus.degraded:
        return 'Нестабильно';
      case ConnectionStatus.disconnected:
        return 'Отключено';
      case ConnectionStatus.error:
        return 'Ошибка';
    }
  }

  bool get isPositive {
    switch (this) {
      case ConnectionStatus.connected:
        return true;
      case ConnectionStatus.idle:
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
      case ConnectionStatus.degraded:
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        return false;
    }
  }
}
