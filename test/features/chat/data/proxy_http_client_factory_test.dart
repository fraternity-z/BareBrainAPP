import 'package:bare_brain_app/src/features/chat/data/datasources/proxy_http_client_factory.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProxyHttpClientFactory', () {
    test('returns DIRECT when proxy is disabled', () {
      expect(
        ProxyHttpClientFactory.proxyForUri(
          Uri.parse('https://example.com'),
          const ChatNetworkProxySettings(enabled: false),
        ),
        'DIRECT',
      );
    });

    test('returns configured proxy when enabled', () {
      expect(
        ProxyHttpClientFactory.proxyForUri(
          Uri.parse('https://example.com'),
          const ChatNetworkProxySettings(
            enabled: true,
            server: 'proxy.local',
            port: 1080,
          ),
        ),
        'PROXY proxy.local:1080',
      );
    });

    test('matches host and CIDR bypass rules', () {
      const settings = ChatNetworkProxySettings(
        enabled: true,
        server: 'proxy.local',
        port: 1080,
        bypassRules: <String>[
          'localhost',
          'example.test',
          '10.0.0.0/8',
          '192.168.1.0/24',
        ],
      );

      expect(
        ProxyHttpClientFactory.proxyForUri(
          Uri.parse('https://api.example.test'),
          settings,
        ),
        'DIRECT',
      );
      expect(
        ProxyHttpClientFactory.proxyForUri(
          Uri.parse('http://10.2.3.4'),
          settings,
        ),
        'DIRECT',
      );
      expect(
        ProxyHttpClientFactory.proxyForUri(
          Uri.parse('http://192.168.1.88'),
          settings,
        ),
        'DIRECT',
      );
      expect(
        ProxyHttpClientFactory.proxyForUri(
          Uri.parse('http://192.168.2.88'),
          settings,
        ),
        'PROXY proxy.local:1080',
      );
    });
  });
}
