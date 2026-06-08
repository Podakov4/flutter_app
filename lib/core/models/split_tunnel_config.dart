enum SplitTunnelMode { all, includeOnly, excludeOnly }

extension SplitTunnelModeX on SplitTunnelMode {
  String get label {
    switch (this) {
      case SplitTunnelMode.all:
        return 'Все приложения';
      case SplitTunnelMode.includeOnly:
        return 'Только выбранные';
      case SplitTunnelMode.excludeOnly:
        return 'Все, кроме выбранных';
    }
  }

  String get description {
    switch (this) {
      case SplitTunnelMode.all:
        return 'Все приложения используют Freeth VPN. Стандартный режим — трафик любого приложения идёт через защищённый канал.';
      case SplitTunnelMode.includeOnly:
        return 'Только отмеченные приложения работают через Freeth VPN. Остальные приложения используют обычное интернет-соединение.';
      case SplitTunnelMode.excludeOnly:
        return 'Все приложения работают через Freeth VPN, кроме отмеченных. Удобно, если нужно вывести отдельные сервисы из-под VPN.';
    }
  }
}

class SplitTunnelConfig {
  const SplitTunnelConfig({required this.mode, required this.packages});

  final SplitTunnelMode mode;
  final List<String> packages;

  bool get isActive => mode != SplitTunnelMode.all && packages.isNotEmpty;
}
