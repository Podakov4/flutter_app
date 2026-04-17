class AccessServerInfo {
  const AccessServerInfo({
    required this.code,
    required this.name,
    required this.displayName,
    required this.countryCode,
    required this.domain,
    required this.manualUrl,
    required this.enabled,
  });

  final String code;
  final String? name;
  final String? displayName;
  final String? countryCode;
  final String? domain;
  final String? manualUrl;
  final bool enabled;

  factory AccessServerInfo.fromJson(Map<String, dynamic> json) {
    return AccessServerInfo(
      code: (json['code'] as String?) ?? '',
      name: json['name'] as String?,
      displayName: json['display_name'] as String?,
      countryCode: json['country_code'] as String?,
      domain: json['domain'] as String?,
      manualUrl: json['manual_url'] as String?,
      enabled: json['enabled'] == true,
    );
  }
}

class AccessInfo {
  const AccessInfo({
    required this.access,
    required this.subscriptionActive,
    required this.expiresAt,
    required this.type,
    required this.subscriptionUrl,
    required this.manualUrl,
    required this.manualUrls,
    required this.supports,
    required this.servers,
  });

  final bool access;
  final bool subscriptionActive;
  final String? expiresAt;
  final String? type;
  final String? subscriptionUrl;
  final String? manualUrl;
  final List<String> manualUrls;
  final List<String> supports;
  final List<AccessServerInfo> servers;

  bool get hasServerSelectionData =>
      servers.isNotEmpty ||
      manualUrls.isNotEmpty ||
      (subscriptionUrl?.trim().isNotEmpty == true);

  factory AccessInfo.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> vpn = Map<String, dynamic>.from(
      json['vpn'] as Map? ?? <String, dynamic>{},
    );

    return AccessInfo(
      access: json['access'] == true,
      subscriptionActive: json['subscription_active'] == true,
      expiresAt: json['expires_at'] as String?,
      type: vpn['type'] as String?,
      subscriptionUrl: vpn['subscription_url'] as String?,
      manualUrl: vpn['manual_url'] as String?,
      manualUrls: ((vpn['manual_urls'] as List?) ?? <dynamic>[])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      supports: ((vpn['supports'] as List?) ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      servers: ((vpn['servers'] as List?) ?? <dynamic>[])
          .map(
            (item) => AccessServerInfo.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
