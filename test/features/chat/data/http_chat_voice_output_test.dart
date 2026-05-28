import 'dart:convert';
import 'dart:io';

import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/data/datasources/http_chat_voice_output.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpChatVoiceOutput', () {
    test('posts assistant text to the configured endpoint', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
      });
      final requestFuture = server.first;
      const output = HttpChatVoiceOutput();

      final speakFuture = output.speak(
        'pong',
        ChatVoiceSettings(
          enabled: true,
          endpoint: 'http://127.0.0.1:${server.port}/voice',
          speaker: 'alice',
          streaming: false,
        ),
      );

      final request = await requestFuture;
      final body = await utf8.decoder.bind(request).join();
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();

      await speakFuture;

      expect(request.method, 'POST');
      expect(request.uri.path, '/voice');
      expect(jsonDecode(body), <String, dynamic>{
        'text': 'pong',
        'speaker': 'alice',
        'streaming': false,
      });
    });

    test('rejects invalid endpoints', () async {
      const output = HttpChatVoiceOutput();

      await expectLater(
        output.speak(
          'pong',
          const ChatVoiceSettings(
            enabled: true,
            endpoint: 'not a url',
          ),
        ),
        throwsA(isA<ChatConnectionException>()),
      );
    });

    test('reports non-success status codes', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
      });
      final requestFuture = server.first;
      const output = HttpChatVoiceOutput();

      final speakFuture = output.speak(
        'pong',
        ChatVoiceSettings(
          enabled: true,
          endpoint: 'http://127.0.0.1:${server.port}/voice',
        ),
      );

      final request = await requestFuture;
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();

      await expectLater(
        speakFuture,
        throwsA(
          isA<ChatConnectionException>().having(
            (error) => error.message,
            'message',
            contains('语音服务返回状态码 500'),
          ),
        ),
      );
    });
  });
}
