import 'dart:async';
import 'dart:convert';

import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/data/datasources/bare_brain_websocket_transport.dart';
import 'package:bare_brain_app/src/features/chat/data/datasources/text_socket_connection.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BareBrainWebSocketTransport', () {
    const settings = ChatConnectionSettings(
      host: '192.168.1.10',
      port: 18789,
      clientId: 'barebrain_app',
      responseTimeout: Duration(milliseconds: 50),
    );

    test('checks connection with handshake only', () async {
      late _FakeTextSocketConnection connection;
      final transport = BareBrainWebSocketTransport(
        connectionFactory: (uri) {
          connection = _FakeTextSocketConnection();
          expect(uri.toString(), 'ws://192.168.1.10:18789/');
          return connection;
        },
      );

      await transport.checkConnection(settings);

      expect(connection.sent, isEmpty);
      expect(connection.closed, isTrue);
    });

    test('sends BareBrain message payload and returns matching response',
        () async {
      late _FakeTextSocketConnection connection;
      final transport = BareBrainWebSocketTransport(
        connectionFactory: (uri) {
          connection = _FakeTextSocketConnection();
          expect(uri.toString(), 'ws://192.168.1.10:18789/');
          return connection;
        },
      );

      final responseFuture = transport.sendMessage(
        'hello',
        settings,
        chatId: 'conversation_a',
      );

      await Future<void>.delayed(Duration.zero);
      expect(jsonDecode(connection.sent.single), <String, dynamic>{
        'type': 'message',
        'content': 'hello',
        'chat_id': 'conversation_a',
      });

      connection.addIncoming(
        '{"type":"response","content":"ignored","chat_id":"other"}',
      );
      connection.addIncoming(
        '{"type":"response","content":"Hi","chat_id":"conversation_a"}',
      );

      final response = await responseFuture;

      expect(response.content, 'Hi');
      expect(connection.closed, isTrue);
    });

    test('throws timeout when no complete response arrives', () async {
      final transport = BareBrainWebSocketTransport(
        connectionFactory: (_) => _FakeTextSocketConnection(),
      );

      await expectLater(
        transport.sendMessage('hello', settings, chatId: 'conversation_a'),
        throwsA(isA<ChatTimeoutException>()),
      );
    });
  });
}

class _FakeTextSocketConnection implements TextSocketConnection {
  final StreamController<String> _incoming = StreamController<String>();
  final List<String> sent = <String>[];
  bool closed = false;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  Stream<String> get messages => _incoming.stream;

  @override
  void send(String text) {
    sent.add(text);
  }

  void addIncoming(String text) {
    _incoming.add(text);
  }

  @override
  Future<void> close() {
    closed = true;
    unawaited(_incoming.close());
    return Future<void>.value();
  }
}
