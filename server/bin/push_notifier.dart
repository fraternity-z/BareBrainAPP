import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'relay_protocol.dart';
import 'server_environment.dart';

class PushConfig {
  const PushConfig({
    required this.webhookUrl,
    required this.authHeaderName,
    required this.authHeaderValue,
    required this.timeout,
  });

  factory PushConfig.fromEnvironment(ServerEnvironment environment) {
    return PushConfig(
      webhookUrl: environment.uri('PUSH_WEBHOOK_URL'),
      authHeaderName: environment.string('PUSH_AUTH_HEADER', 'Authorization'),
      authHeaderValue: environment.string('PUSH_AUTH_VALUE', ''),
      timeout: Duration(
        milliseconds: environment.integer('PUSH_TIMEOUT_MS', 8000),
      ),
    );
  }

  final Uri? webhookUrl;
  final String authHeaderName;
  final String authHeaderValue;
  final Duration timeout;

  bool get enabled => webhookUrl != null;
}

class PushNotifier {
  PushNotifier({
    required PushConfig config,
    HttpClient? httpClient,
  })  : _config = config,
        _httpClient = httpClient ?? HttpClient();

  final PushConfig _config;
  final HttpClient _httpClient;

  Future<void> notifyIncoming({
    required String deviceId,
    required String chatId,
    required String content,
  }) async {
    final webhookUrl = _config.webhookUrl;
    if (webhookUrl == null) {
      return;
    }

    final request =
        await _httpClient.postUrl(webhookUrl).timeout(_config.timeout);
    request.headers.contentType = ContentType.json;
    if (_config.authHeaderValue.isNotEmpty) {
      request.headers.set(
        _config.authHeaderName,
        _config.authHeaderValue,
      );
    }

    final payload = <String, Object?>{
      'type': 'incoming_message',
      'device_id': deviceId,
      'chat_id': chatId,
      'title': 'BareBrain',
      'body': _notificationBody(content),
      'content': content,
      'sent_at': DateTime.now().toUtc().toIso8601String(),
    };
    request.write(jsonEncode(payload));

    final response = await request.close().timeout(_config.timeout);
    try {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final body = await utf8.decodeStream(response).timeout(_config.timeout);
        throw RelayProtocolException(
          'Push webhook returned ${response.statusCode}: $body',
        );
      }
    } finally {
      unawaited(response.drain<void>());
    }
  }

  void close() {
    _httpClient.close(force: true);
  }

  String _notificationBody(String content) {
    final normalized = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length <= 120) {
      return normalized;
    }

    return '${normalized.substring(0, 120)}...';
  }
}
