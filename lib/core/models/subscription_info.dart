class SubscriptionInfo {
  const SubscriptionInfo({
    required this.isActive,
    required this.isPaid,
    required this.paidUntil,
    required this.isExpired,
    required this.daysLeft,
    required this.secondsLeft,
    required this.planCode,
    required this.maxDevices,
  });

  final bool isActive;
  final bool isPaid;
  final String? paidUntil;
  final bool isExpired;
  final int daysLeft;
  final int secondsLeft;
  final String? planCode;
  final int maxDevices;

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      isActive: json['is_active'] == true,
      isPaid: json['is_paid'] == true,
      paidUntil: json['paid_until'] as String?,
      isExpired: json['is_expired'] == true,
      daysLeft: (json['days_left'] as num?)?.toInt() ?? 0,
      secondsLeft: (json['seconds_left'] as num?)?.toInt() ?? 0,
      planCode: json['plan_code'] as String?,
      maxDevices: (json['max_devices'] as num?)?.toInt() ?? 0,
    );
  }
}
