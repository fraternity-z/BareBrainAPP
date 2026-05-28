import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/errors/chat_exception.dart';
import '../../domain/entities/chat_app_settings.dart';
import '../../domain/repositories/chat_voice_output.dart';
import 'proxy_http_client_factory.dart';

class HttpChatVoiceOutput implements ChatVoiceOutput {
  const HttpChatVoiceOutput({
    this.httpClientFactory,
    this.networkProxySettingsProvider,
  });

  final HttpClientFactory? httpClientFactory;
  final ChatNetworkProxySettings Function()? networkProxySettingsProvider;

  @override
  Future<void> speak(String content, ChatVoiceSettings settings) async {
    if (!settings.enabled) {
      return;
    }

    final endpoint = Uri.tryParse(settings.endpoint.trim());
    if (endpoint == null ||
        endpoint.host.isEmpty ||
        (endpoint.scheme != 'http' && endpoint.scheme != 'https')) {
      throw const ChatConnectionException('语音服务地址必须是 http 或 https URL');
    }

    final client = ProxyHttpClientFactory.create(
      settings: networkProxySettingsProvider?.call(),
      httpClientFactory: httpClientFactory,
    );
    try {
      final request = await client.postUrl(endpoint).timeout(settings.timeout);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode(<String, dynamic>{
          'text': content,
          'speaker': settings.speaker,
          'streaming': settings.streaming,
        }),
      );

      final response = await request.close().timeout(settings.timeout);
      await response.drain<void>().timeout(settings.timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ChatConnectionException(
          '语音服务返回状态码 ${response.statusCode}',
        );
      }
    } on ChatException {
      rethrow;
    } on TimeoutException {
      throw ChatTimeoutException(
        '语音服务超时：${settings.timeout.inSeconds} 秒',
      );
    } catch (error) {
      throw ChatConnectionException('语音服务失败：$error');
    } finally {
      client.close(force: true);
    }
  }
}
