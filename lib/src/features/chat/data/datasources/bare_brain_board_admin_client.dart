import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/entities/chat_connection_settings.dart';
import '../../domain/repositories/bare_brain_board_config_client.dart';
import 'proxy_http_client_factory.dart';

class BareBrainBoardAdminClient implements BareBrainBoardConfigClient {
  const BareBrainBoardAdminClient({
    this.httpClientFactory,
    this.networkProxySettingsProvider,
  });

  static const int adminPort = 80;

  final HttpClientFactory? httpClientFactory;
  final ChatNetworkProxySettings Function()? networkProxySettingsProvider;

  @override
  Future<Map<String, String>> fetchConfig(
    ChatConnectionSettings settings,
  ) async {
    final endpoint = _endpoint(settings, '/config');
    final client = _createClient();
    try {
      final request = await client.getUrl(endpoint).timeout(
            settings.responseTimeout,
          );
      request.followRedirects = false;
      final response = await request.close().timeout(settings.responseTimeout);
      final body = await response.transform(utf8.decoder).join().timeout(
            settings.responseTimeout,
          );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ChatConnectionException(
          '板子配置读取返回状态码 ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const ChatProtocolException('板子配置响应不是有效对象');
      }

      return decoded.map((key, value) {
        return MapEntry(key, value is String ? value : value?.toString() ?? '');
      });
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw ChatTimeoutException(
        '板子配置读取超时：${settings.responseTimeout.inSeconds} 秒',
      );
    } on FormatException {
      throw const ChatProtocolException('板子配置响应不是有效 JSON');
    } catch (error) {
      throw ChatConnectionException('板子配置读取失败：$error');
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<void> saveConfig(
    ChatConnectionSettings settings,
    Map<String, String> patch,
  ) async {
    if (patch.isEmpty) {
      throw const ChatValidationException('没有可保存的板子配置');
    }

    final endpoint = _endpoint(settings, '/save');
    final client = _createClient();
    try {
      final request = await client.postUrl(endpoint).timeout(
            settings.responseTimeout,
          );
      request
        ..followRedirects = false
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(patch));

      final response = await request.close().timeout(settings.responseTimeout);
      await response.drain<void>().timeout(settings.responseTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ChatConnectionException(
          '板子配置保存返回状态码 ${response.statusCode}',
        );
      }
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw ChatTimeoutException(
        '板子配置保存超时：${settings.responseTimeout.inSeconds} 秒',
      );
    } catch (error) {
      throw ChatConnectionException('板子配置保存失败：$error');
    } finally {
      client.close(force: true);
    }
  }

  HttpClient _createClient() {
    return ProxyHttpClientFactory.create(
      settings: networkProxySettingsProvider?.call(),
      httpClientFactory: httpClientFactory,
    );
  }

  Uri _endpoint(ChatConnectionSettings settings, String path) {
    if (settings.isRelay) {
      throw const ChatValidationException('Relay 模式暂不支持板子设置');
    }

    final host = settings.host.trim();
    if (host.isEmpty) {
      throw const ChatValidationException('设备地址不能为空');
    }

    return Uri(
      scheme: 'http',
      host: host,
      port: adminPort,
      path: path,
    );
  }
}
