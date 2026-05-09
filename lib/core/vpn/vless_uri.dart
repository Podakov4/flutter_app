class VlessUri {
  const VlessUri({
    required this.raw,
    required this.uuid,
    required this.server,
    required this.port,
    required this.name,
    required this.query,
  });

  final String raw;
  final String uuid;
  final String server;
  final int port;
  final String name;
  final Map<String, String> query;

  String get type => query['type']?.trim().toLowerCase() ?? '';

  String get security => query['security']?.trim().toLowerCase() ?? '';

  String get encryption => query['encryption']?.trim().toLowerCase() ?? 'none';

  String get flow => query['flow']?.trim() ?? '';

  String get path {
    final value = query['path']?.trim();
    if (value == null || value.isEmpty) {
      return '/';
    }

    return value;
  }

  String? get hostHeader {
    final value = query['host']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String? get sni {
    final value = query['sni']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  String? get fingerprint {
    final value = query['fp']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  bool get isTls => security == 'tls';

  bool get isWebSocket => type == 'ws' || type == 'websocket';

  static VlessUri parse(String value) {
    final String source = value.trim();

    if (!source.startsWith('vless://')) {
      throw FormatException('Ожидалась VLESS-ссылка', source);
    }

    final Uri uri = Uri.parse(source);

    if (uri.scheme != 'vless') {
      throw FormatException('Неверная схема VLESS-ссылки', source);
    }

    final String uuid = uri.userInfo.trim();
    final String server = uri.host.trim();
    final int port = uri.hasPort ? uri.port : 443;

    if (uuid.isEmpty) {
      throw FormatException('В VLESS-ссылке отсутствует UUID', source);
    }

    if (server.isEmpty) {
      throw FormatException('В VLESS-ссылке отсутствует сервер', source);
    }

    final String title = uri.fragment.trim().isEmpty
        ? server
        : Uri.decodeComponent(uri.fragment.trim());

    return VlessUri(
      raw: source,
      uuid: uuid,
      server: server,
      port: port,
      name: title,
      query: uri.queryParameters.map(
        (key, value) => MapEntry(key.trim(), value.trim()),
      ),
    );
  }
}
