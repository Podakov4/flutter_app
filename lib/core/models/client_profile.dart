class ClientProfile {
  const ClientProfile({
    required this.id,
    required this.publicId,
    required this.telegramId,
    required this.fullName,
    required this.login,
    required this.email,
    required this.status,
    required this.createdVia,
    required this.defaultLanguage,
    required this.isActive,
    required this.isPaid,
    required this.paidUntil,
    required this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String? publicId;
  final String telegramId;
  final String? fullName;
  final String? login;
  final String? email;
  final String? status;
  final String? createdVia;
  final String? defaultLanguage;
  final bool isActive;
  final bool isPaid;
  final String? paidUntil;
  final String? lastLoginAt;
  final String? createdAt;
  final String? updatedAt;

  factory ClientProfile.fromJson(Map<String, dynamic> json) {
    return ClientProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      publicId: json['public_id'] as String?,
      telegramId: (json['telegram_id'] as String?) ?? '',
      fullName: json['full_name'] as String?,
      login: json['login'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String?,
      createdVia: json['created_via'] as String?,
      defaultLanguage: json['default_language'] as String?,
      isActive: json['is_active'] == true,
      isPaid: json['is_paid'] == true,
      paidUntil: json['paid_until'] as String?,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
