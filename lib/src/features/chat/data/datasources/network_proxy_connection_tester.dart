import 'dart:async';
import 'dart:io';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_app_settings.dart';
import 'proxy_http_client_factory.dart';

class NetworkProxyConnectionTester {
  const NetworkProxyConnectionTester({
    this.httpClientFactory,
    this.timeout = const Duration(seconds: 8),
  });

  final HttpClient Function(ChatNetworkProxySettings settings)?
      httpClientFactory;
  final Duration timeout;

  Future<void> test(ChatNetworkProxySettings settings) async {
    final endpoint = Uri.tryParse(settings.testUrl.trim());
    if (endpoint == null ||
        endpoint.host.isEmpty ||
        (endpoint.scheme != 'http' && endpoint.scheme != 'https')) {
      throw const ChatValidationException('测试地址必须是 http 或 https URL');
    }

    final client = httpClientFactory?.call(settings) ??
        ProxyHttpClientFactory.create(settings: settings);
    try {
      final request = await client.getUrl(endpoint).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      await response.drain<void>().timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ChatConnectionException(
          '代理测试返回状态码 ${response.statusCode}',
        );
      }
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw ChatTimeoutException('代理测试超时：${timeout.inSeconds} 秒');
    } catch (error) {
      throw ChatConnectionException('代理测试失败：$error');
    } finally {
      client.close(force: true);
    }
  }
}
