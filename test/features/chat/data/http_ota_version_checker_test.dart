import 'dart:io';

import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/data/datasources/http_ota_version_checker.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_ota_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpOtaVersionChecker', () {
    test('requests the configured OTA version endpoint', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
      });
      final requestFuture = server.first;
      const checker = HttpOtaVersionChecker();

      final checkFuture = checker.check(
        ChatConnectionSettings(
          host: '127.0.0.1',
          port: server.port,
          clientId: 'barebrain_app',
          responseTimeout: const Duration(seconds: 10),
          otaSettings: const ChatOtaSettings(
            versionPath: '/api/ota/version',
            channel: 'beta',
            requestTimeout: Duration(seconds: 10),
          ),
        ),
      );

      final request = await requestFuture;
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();

      await checkFuture;

      expect(request.method, 'GET');
      expect(request.uri.path, '/api/ota/version');
      expect(request.uri.queryParameters['channel'], 'beta');
    });

    test('reports non-success status codes', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
      });
      final requestFuture = server.first;
      const checker = HttpOtaVersionChecker();

      final checkFuture = checker.check(
        ChatConnectionSettings(
          host: '127.0.0.1',
          port: server.port,
          clientId: 'barebrain_app',
          responseTimeout: const Duration(seconds: 10),
          otaSettings: const ChatOtaSettings(
            requestTimeout: Duration(seconds: 10),
          ),
        ),
      );

      final request = await requestFuture;
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();

      await expectLater(
        checkFuture,
        throwsA(
          isA<ChatConnectionException>().having(
            (error) => error.message,
            'message',
            contains('OTA 版本检查返回状态码 500'),
          ),
        ),
      );
    });
  });
}
