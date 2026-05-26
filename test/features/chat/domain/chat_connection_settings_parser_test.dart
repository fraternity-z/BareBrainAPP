import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/services/chat_connection_settings_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatConnectionSettingsParser', () {
    test('parses a pasted BareBrain WebSocket URL', () {
      final settings = ChatConnectionSettingsParser.parse(
        hostInput: 'ws://192.168.1.10:18789/',
        portInput: '9999',
        clientIdInput: 'barebrain_app',
        timeoutSecondsInput: '90',
        secure: false,
      );

      expect(settings.host, '192.168.1.10');
      expect(settings.port, 18789);
      expect(settings.secure, isFalse);
      expect(settings.websocketUri.toString(), 'ws://192.168.1.10:18789/');
    });

    test('normalizes existing settings before use', () {
      final settings = ChatConnectionSettingsParser.normalize(
        const ChatConnectionSettings(
          host: ' 192.168.1.10 ',
          port: 18789,
          clientId: ' barebrain_app ',
          responseTimeout: Duration(seconds: 30),
        ),
      );

      expect(settings.host, '192.168.1.10');
      expect(settings.clientId, 'barebrain_app');
    });

    test('parses secure WebSocket URL and normalizes client id', () {
      final settings = ChatConnectionSettingsParser.parse(
        hostInput: 'wss://barebrain.local:18789/',
        portInput: '',
        clientIdInput: ' mobile-client ',
        timeoutSecondsInput: '30',
        secure: false,
      );

      expect(settings.host, 'barebrain.local');
      expect(settings.port, 18789);
      expect(settings.clientId, 'mobile-client');
      expect(settings.secure, isTrue);
    });

    test('uses default BareBrain port when port is omitted', () {
      final settings = ChatConnectionSettingsParser.parse(
        hostInput: '192.168.1.10',
        portInput: '',
        clientIdInput: 'barebrain_app',
        timeoutSecondsInput: '30',
        secure: false,
      );

      expect(settings.port, 18789);
    });

    test('rejects unsupported schemes and paths', () {
      expect(
        () => ChatConnectionSettingsParser.parse(
          hostInput: 'http://192.168.1.10',
          portInput: '18789',
          clientIdInput: 'barebrain_app',
          timeoutSecondsInput: '30',
          secure: false,
        ),
        throwsA(isA<ChatValidationException>()),
      );

      expect(
        () => ChatConnectionSettingsParser.parse(
          hostInput: 'ws://192.168.1.10:18789/chat',
          portInput: '',
          clientIdInput: 'barebrain_app',
          timeoutSecondsInput: '30',
          secure: false,
        ),
        throwsA(isA<ChatValidationException>()),
      );
    });

    test('validates client id and timeout bounds', () {
      const settings = ChatConnectionSettings(
        host: '192.168.1.10',
        port: 18789,
        clientId: 'bad id',
        responseTimeout: Duration(seconds: 30),
      );

      expect(
        () => ChatConnectionSettingsParser.validate(settings),
        throwsA(isA<ChatValidationException>()),
      );

      expect(
        () => ChatConnectionSettingsParser.parse(
          hostInput: '192.168.1.10',
          portInput: '18789',
          clientIdInput: 'barebrain_app',
          timeoutSecondsInput: '2',
          secure: false,
        ),
        throwsA(isA<ChatValidationException>()),
      );
    });
  });
}
