class Server {
  final String name;
  final String country;
  final String flag;
  final String ping;
  final String manualUrl;

  Server({
    required this.name,
    required this.country,
    required this.flag,
    required this.ping,
    required this.manualUrl,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      name: json['name'] ?? 'Неизвестный сервер',
      country: json['country'] ?? 'Неизвестная страна',
      flag: json['flag'] ?? '🏳️', // Эмодзи флага
      ping: json['ping'] ?? 'Неизвестно',
      manualUrl: json['manualUrl'] ?? '',
    );
  }
}
