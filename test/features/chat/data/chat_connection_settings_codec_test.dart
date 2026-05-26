import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/data/models/chat_connection_settings_codec.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatConnectionSettingsCodec', () {
    test('round-trips settings', () {
      const settings = ChatConnectionSettings(
        host: '192.168.1.10',
        port: 18789,
        clientId: 'barebrain_app',
        responseTimeout: Duration(seconds: 90),
        secure: true,
      );

      final restored = ChatConnectionSettingsCodec.fromJson(
        ChatConnectionSettingsCodec.toJson(settings),
      );

      expect(restored.host, '192.168.1.10');
      expect(restored.port, 18789);
      expect(restored.clientId, 'barebrain_app');
      expect(restored.responseTimeout, const Duration(seconds: 90));
      expect(restored.secure, isTrue);
    });

    test('rejects malformed settings', () {
      expect(
        () => ChatConnectionSettingsCodec.fromJson(<String, dynamic>{
          'host': '192.168.1.10',
          'port': '18789',
          'clientId': 'barebrain_app',
          'responseTimeoutMs': 90000,
        }),
        throwsA(isA<ChatStorageException>()),
      );
    });
  });
}
