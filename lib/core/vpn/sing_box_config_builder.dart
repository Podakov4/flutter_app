import '../../core/models/split_tunnel_config.dart';
import 'vless_uri.dart';

class SingBoxConfigBuilder {
  const SingBoxConfigBuilder();

  Map<String, dynamic> buildFromVless(
    VlessUri vless, {
    SplitTunnelConfig? splitTunnelConfig,
  }) {
    final Map<String, dynamic> proxyOutbound = _buildVlessOutbound(vless);

    final List<Map<String, dynamic>> dnsRules = <Map<String, dynamic>>[];

    if (!_isIpLiteral(vless.server)) {
      dnsRules.add(<String, dynamic>{
        'domain': <String>[vless.server],
        'server': 'dns-direct',
      });
    }

    final List<Map<String, dynamic>> routeRules = <Map<String, dynamic>>[
      <String, dynamic>{'protocol': 'dns', 'outbound': 'dns-out'},
      <String, dynamic>{'ip_is_private': true, 'outbound': 'direct'},
    ];

    String routeFinal = 'freeth-out';

    if (splitTunnelConfig != null && splitTunnelConfig.isActive) {
      final List<String> packages = splitTunnelConfig.packages;
      if (splitTunnelConfig.mode == SplitTunnelMode.includeOnly) {
        // Only selected apps → VPN; everything else → direct.
        routeRules.add(<String, dynamic>{
          'package_name': packages,
          'outbound': 'freeth-out',
        });
        routeFinal = 'direct';
      } else {
        // SplitTunnelMode.excludeOnly: selected apps → direct; rest → VPN.
        routeRules.add(<String, dynamic>{
          'package_name': packages,
          'outbound': 'direct',
        });
      }
    }

    return <String, dynamic>{
      'log': <String, dynamic>{
        'disabled': false,
        'level': 'info',
        'timestamp': true,
      },

      'dns': <String, dynamic>{
        'servers': <Map<String, dynamic>>[
          <String, dynamic>{
            'tag': 'dns-direct',
            'type': 'udp',
            'server': '1.1.1.1',
            'server_port': 53,
          },
        ],
        'rules': dnsRules,
        'final': 'dns-direct',
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
          'sniff': true,
          'sniff_override_destination': true,
        },
      ],

      'outbounds': <Map<String, dynamic>>[
        proxyOutbound,
        <String, dynamic>{
          'type': 'direct',
          'tag': 'direct',
          'domain_strategy': 'ipv4_only',
        },
        <String, dynamic>{'type': 'dns', 'tag': 'dns-out'},
        <String, dynamic>{'type': 'block', 'tag': 'block'},
      ],

      'route': <String, dynamic>{
        'auto_detect_interface': true,
        'final': routeFinal,
        'rules': routeRules,
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
      'domain_strategy': 'prefer_ipv4',
    };

    if (vless.packetEncoding.isNotEmpty) {
      outbound['packet_encoding'] = vless.packetEncoding;
    }

    if (vless.flow.isNotEmpty) {
      outbound['flow'] = vless.flow;
    }

    if (vless.isTls) {
      final Map<String, dynamic> tls = <String, dynamic>{
        'enabled': true,
        'server_name': vless.sni ?? vless.hostHeader ?? vless.server,
        'insecure': false,
      };

      if (vless.fingerprint != null) {
        tls['utls'] = <String, dynamic>{
          'enabled': true,
          'fingerprint': vless.fingerprint!,
        };
      }

      outbound['tls'] = tls;
    }

    if (vless.isWebSocket) {
      final Map<String, dynamic> transport = <String, dynamic>{
        'type': 'ws',
        'path': vless.path,
      };

      final String? host = vless.hostHeader;
      if (host != null && host.isNotEmpty) {
        transport['headers'] = <String, dynamic>{'Host': host};
      }

      outbound['transport'] = transport;
    }

    return outbound;
  }

  bool _isIpLiteral(String value) {
    final String host = value.trim();

    if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host)) {
      return true;
    }

    if (host.contains(':') && RegExp(r'^[0-9a-fA-F:]+$').hasMatch(host)) {
      return true;
    }

    return false;
  }
}
