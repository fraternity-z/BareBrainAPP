import 'dart:async';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/entities/chat_connection_settings.dart';
import 'proxy_http_client_factory.dart';

class HttpOtaVersionChecker {
  const HttpOtaVersionChecker({
    this.httpClientFactory,
    this.networkProxySettingsProvider,
  });

  final HttpClientFactory? httpClientFactory;
  final ChatNetworkProxySettings Function()? networkProxySettingsProvider;

  Future<void> check(ChatConnectionSettings settings) async {
    final endpoint = Uri(
      scheme: settings.secure ? 'https' : 'http',
      host: settings.host,
      port: settings.port,
      path: settings.otaSettings.versionPath,
      queryParameters: <String, String>{
        'channel': settings.otaSettings.channel,
      },
    );

    final client = ProxyHttpClientFactory.create(
      settings: networkProxySettingsProvider?.call(),
      httpClientFactory: httpClientFactory,
    );
    try {
      final request = await client
          .getUrl(endpoint)
          .timeout(settings.otaSettings.requestTimeout);
      request.followRedirects = false;
      final response = await request.close().timeout(
            settings.otaSettings.requestTimeout,
          );
      await response.drain<void>().timeout(settings.otaSettings.requestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 400) {
        throw ChatConnectionException(
          'OTA 版本检查返回状态码 ${response.statusCode}',
        );
      }
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw ChatTimeoutException(
        'OTA 版本检查超时：${settings.otaSettings.requestTimeout.inSeconds} 秒',
      );
    } catch (error) {
      throw ChatConnectionException('OTA 版本检查失败：$error');
    } finally {
      client.close(force: true);
    }
  }
}
