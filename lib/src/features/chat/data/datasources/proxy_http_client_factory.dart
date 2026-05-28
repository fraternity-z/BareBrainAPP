import 'dart:io';

import '../../domain/entities/chat_app_settings.dart';

typedef HttpClientFactory = HttpClient Function();

class ProxyHttpClientFactory {
  const ProxyHttpClientFactory._();

  static HttpClient create({
    ChatNetworkProxySettings? settings,
    HttpClientFactory? httpClientFactory,
  }) {
    final client = httpClientFactory?.call() ?? HttpClient();
    configure(client, settings);
    return client;
  }

  static void configure(
    HttpClient client,
    ChatNetworkProxySettings? settings,
  ) {
    if (settings == null || !settings.enabled) {
      return;
    }

    client.findProxy = (url) => proxyForUri(url, settings);
    if (settings.username.isEmpty) {
      return;
    }

    client.authenticateProxy = (host, port, scheme, realm) async {
      client.addProxyCredentials(
        host,
        port,
        realm ?? '',
        HttpClientBasicCredentials(settings.username, settings.password),
      );
      return true;
    };
  }

  static String proxyForUri(Uri uri, ChatNetworkProxySettings settings) {
    if (!settings.enabled || shouldBypassProxy(uri, settings.bypassRules)) {
      return 'DIRECT';
    }

    return 'PROXY ${settings.server}:${settings.port}';
  }

  static bool shouldBypassProxy(Uri uri, List<String> bypassRules) {
    final host = uri.host.toLowerCase();
    for (final rule in bypassRules) {
      if (_matchesBypassRule(host, rule)) {
        return true;
      }
    }

    return false;
  }

  static bool _matchesBypassRule(String host, String rule) {
    final normalized = rule.trim().toLowerCase();
    if (normalized.isEmpty) {
      return false;
    }

    if (normalized == '*' ||
        normalized == host ||
        host.endsWith('.$normalized')) {
      return true;
    }

    if (!normalized.contains('/')) {
      return false;
    }

    final ruleParts = normalized.split('/');
    if (ruleParts.length != 2) {
      return false;
    }

    final network = _parseIpv4Address(ruleParts[0]);
    final address = _parseIpv4Address(host);
    final prefix = int.tryParse(ruleParts[1]);
    if (network == null || address == null || prefix == null) {
      return false;
    }

    if (prefix < 0 || prefix > 32) {
      return false;
    }

    final mask = prefix == 0 ? 0 : (0xffffffff << (32 - prefix)) & 0xffffffff;
    return (address & mask) == (network & mask);
  }

  static int? _parseIpv4Address(String source) {
    final parts = source.split('.');
    if (parts.length != 4) {
      return null;
    }

    var value = 0;
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) {
        return null;
      }

      value = (value << 8) | octet;
    }

    return value;
  }
}
