enum ConnectionMode { smart, manual }

extension ConnectionModeX on ConnectionMode {
  String get label {
    switch (this) {
      case ConnectionMode.smart:
        return 'Умный режим';
      case ConnectionMode.manual:
        return 'Ручной режим';
    }
  }

  String get subtitle {
    switch (this) {
      case ConnectionMode.smart:
        return 'Freeth сам выбирает лучший маршрут и помогает при нестабильной сети.';
      case ConnectionMode.manual:
        return 'Вы сами фиксируете локацию и управляете маршрутом вручную.';
    }
  }
}
