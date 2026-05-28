import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/data/models/chat_connection_settings_codec.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_ota_settings.dart';
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
        otaSettings: ChatOtaSettings(
          versionPath: '/api/ota/version',
          firmwarePath: '/api/ota/firmware',
          channel: 'beta',
          requestTimeout: Duration(seconds: 180),
          autoCheck: true,
        ),
      );

      final restored = ChatConnectionSettingsCodec.fromJson(
        ChatConnectionSettingsCodec.toJson(settings),
      );

      expect(restored.host, '192.168.1.10');
      expect(restored.port, 18789);
      expect(restored.clientId, 'barebrain_app');
      expect(restored.responseTimeout, const Duration(seconds: 90));
      expect(restored.secure, isTrue);
      expect(restored.otaSettings.versionPath, '/api/ota/version');
      expect(restored.otaSettings.firmwarePath, '/api/ota/firmware');
      expect(restored.otaSettings.channel, 'beta');
      expect(restored.otaSettings.requestTimeout, const Duration(seconds: 180));
      expect(restored.otaSettings.autoCheck, isTrue);
    });

    test('restores default OTA settings from older payloads', () {
      final restored = ChatConnectionSettingsCodec.fromJson(
        <String, dynamic>{
          'host': '192.168.1.10',
          'port': 18789,
          'clientId': 'barebrain_app',
          'responseTimeoutMs': 90000,
          'secure': false,
        },
      );

      expect(restored.otaSettings.versionPath, '/ota/version');
      expect(restored.otaSettings.firmwarePath, '/ota/firmware');
      expect(restored.otaSettings.channel, 'stable');
      expect(restored.otaSettings.autoCheck, isFalse);
    });

    test('restores partial OTA settings with per-field defaults', () {
      final restored = ChatConnectionSettingsCodec.fromJson(
        <String, dynamic>{
          'host': ' 192.168.1.10 ',
          'port': 18789,
          'clientId': ' barebrain_app ',
          'responseTimeoutMs': 90000,
          'secure': false,
          'otaSettings': <String, dynamic>{
            'channel': 'beta',
            'autoCheck': true,
          },
        },
      );

      expect(restored.host, '192.168.1.10');
      expect(restored.clientId, 'barebrain_app');
      expect(restored.otaSettings.versionPath, '/ota/version');
      expect(restored.otaSettings.firmwarePath, '/ota/firmware');
      expect(restored.otaSettings.channel, 'beta');
      expect(restored.otaSettings.requestTimeout, const Duration(seconds: 120));
      expect(restored.otaSettings.autoCheck, isTrue);
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
