import 'vless_uri.dart';

class SingBoxConfigBuilder {
  const SingBoxConfigBuilder();

  Map<String, dynamic> buildFromVless(VlessUri vless) {
    final Map<String, dynamic> proxyOutbound = _buildVlessOutbound(vless);

    return <String, dynamic>{
      'log': <String, dynamic>{
        'disabled': false,
        'level': 'info',
        'timestamp': true,
      },
      'dns': <String, dynamic>{
        'servers': <Map<String, dynamic>>[
          <String, dynamic>{'tag': 'dns-local', 'type': 'local'},
        ],
        'rules': <Map<String, dynamic>>[],
        'final': 'dns-local',
        'strategy': 'ipv4_only',
        'independent_cache': true,
      },
      'inbounds': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'tun',
          'tag': 'tun-in',
          'address': <String>['172.19.0.1/30', 'fdfe:dcba:9876::1/126'],
          'mtu': 1500,
          'auto_route': true,
          'strict_route': true,
          'stack': 'mixed',
          'sniff_override_destination': true,
        },
      ],
      'outbounds': <Map<String, dynamic>>[
        proxyOutbound,
        <String, dynamic>{'type': 'direct', 'tag': 'direct'},
        <String, dynamic>{'type': 'block', 'tag': 'block'},
      ],
      'route': <String, dynamic>{
        'auto_detect_interface': true,
        'final': 'freeth-out',
        'rules': <Map<String, dynamic>>[
          <String, dynamic>{'ip_is_private': true, 'outbound': 'direct'},
        ],
      },
      'experimental': <String, dynamic>{
        'cache_file': <String, dynamic>{'enabled': true},
      },
    };
  }

  Map<String, dynamic> _buildVlessOutbound(VlessUri vless) {
    final Map<String, dynamic> outbound = <String, dynamic>{
      'type': 'vless',
      'tag': 'freeth-out',
      'server': vless.server,
      'server_port': vless.port,
      'uuid': vless.uuid,
      'packet_encoding': 'xudp',
    };

    if (vless.flow.isNotEmpty) {
      outbound['flow'] = vless.flow;
    }

    if (vless.isTls) {
      outbound['tls'] = <String, dynamic>{
        'enabled': true,
        'server_name': vless.sni ?? vless.hostHeader ?? vless.server,
        'insecure': false,
        'utls': <String, dynamic>{
          'enabled': true,
          'fingerprint': vless.fingerprint ?? 'chrome',
        },
      };
    }

    if (vless.isWebSocket) {
      final Map<String, dynamic> transport = <String, dynamic>{
        'type': 'ws',
        'path': vless.path,
      };

      final String? host = vless.hostHeader;
      if (host != null) {
        transport['headers'] = <String, dynamic>{'Host': host};
      }

      outbound['transport'] = transport;
    }

    return outbound;
  }
}
