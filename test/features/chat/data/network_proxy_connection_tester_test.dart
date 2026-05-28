import 'dart:io';

import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/data/datasources/network_proxy_connection_tester.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkProxyConnectionTester', () {
    test('performs a real HTTP request to the configured test URL', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
      });
      final requestFuture = server.first;
      const tester = NetworkProxyConnectionTester();

      final testFuture = tester.test(
        ChatNetworkProxySettings(
          testUrl: 'http://127.0.0.1:${server.port}/health',
        ),
      );

      final request = await requestFuture;
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();

      await testFuture;

      expect(request.method, 'GET');
      expect(request.uri.path, '/health');
    });

    test('rejects invalid test URLs', () async {
      const tester = NetworkProxyConnectionTester();

      await expectLater(
        tester.test(const ChatNetworkProxySettings(testUrl: 'not a url')),
        throwsA(isA<ChatValidationException>()),
      );
    });

    test('reports non-success status codes', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
      });
      final requestFuture = server.first;
      const tester = NetworkProxyConnectionTester();

      final testFuture = tester.test(
        ChatNetworkProxySettings(
          testUrl: 'http://127.0.0.1:${server.port}/health',
        ),
      );

      final request = await requestFuture;
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();

      await expectLater(
        testFuture,
        throwsA(
          isA<ChatConnectionException>().having(
            (error) => error.message,
            'message',
            contains('代理测试返回状态码 404'),
          ),
        ),
      );
    });
  });
}
