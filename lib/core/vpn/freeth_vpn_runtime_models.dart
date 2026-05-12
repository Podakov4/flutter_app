enum FreethVpnRuntimeState { idle, starting, started, stopping, stopped, error }

class FreethVpnRuntimeSnapshot {
  const FreethVpnRuntimeSnapshot({
    required this.state,
    this.uplink = 0,
    this.downlink = 0,
    this.uplinkTotal = 0,
    this.downlinkTotal = 0,
    this.trafficAvailable = false,
    this.message,
  });

  final FreethVpnRuntimeState state;
  final int uplink;
  final int downlink;
  final int uplinkTotal;
  final int downlinkTotal;
  final bool trafficAvailable;
  final String? message;

  FreethVpnRuntimeSnapshot copyWith({
    FreethVpnRuntimeState? state,
    int? uplink,
    int? downlink,
    int? uplinkTotal,
    int? downlinkTotal,
    bool? trafficAvailable,
    String? message,
  }) {
    return FreethVpnRuntimeSnapshot(
      state: state ?? this.state,
      uplink: uplink ?? this.uplink,
      downlink: downlink ?? this.downlink,
      uplinkTotal: uplinkTotal ?? this.uplinkTotal,
      downlinkTotal: downlinkTotal ?? this.downlinkTotal,
      trafficAvailable: trafficAvailable ?? this.trafficAvailable,
      message: message ?? this.message,
    );
  }
}
