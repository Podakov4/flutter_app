enum ConnectionLogLevel { info, warning, error }

class ConnectionLogEntry {
  const ConnectionLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });

  final DateTime timestamp;
  final ConnectionLogLevel level;
  final String message;

  String get levelLabel {
    switch (level) {
      case ConnectionLogLevel.info:
        return 'INF';
      case ConnectionLogLevel.warning:
        return 'WRN';
      case ConnectionLogLevel.error:
        return 'ERR';
    }
  }
}
