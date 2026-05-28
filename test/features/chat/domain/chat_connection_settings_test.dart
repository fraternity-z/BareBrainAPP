import 'package:bare_brain_app/src/features/chat/domain/entities/chat_connection_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_ota_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatConnectionSettings', () {
    test('compares settings by value', () {
      const settings = ChatConnectionSettings(
        host: '192.168.1.10',
        port: 18789,
        clientId: 'barebrain_app',
        responseTimeout: Duration(seconds: 30),
        secure: true,
        otaSettings: ChatOtaSettings(
          versionPath: '/api/version',
          firmwarePath: '/api/firmware',
          channel: 'beta',
          requestTimeout: Duration(seconds: 60),
          autoCheck: true,
        ),
      );

      const sameSettings = ChatConnectionSettings(
        host: '192.168.1.10',
        port: 18789,
        clientId: 'barebrain_app',
        responseTimeout: Duration(seconds: 30),
        secure: true,
        otaSettings: ChatOtaSettings(
          versionPath: '/api/version',
          firmwarePath: '/api/firmware',
          channel: 'beta',
          requestTimeout: Duration(seconds: 60),
          autoCheck: true,
        ),
      );
      const differentSettings = ChatConnectionSettings(
        host: '192.168.1.11',
        port: 18789,
        clientId: 'barebrain_app',
        responseTimeout: Duration(seconds: 30),
        secure: true,
        otaSettings: ChatOtaSettings(
          versionPath: '/api/version',
          firmwarePath: '/api/firmware',
          channel: 'beta',
          requestTimeout: Duration(seconds: 60),
          autoCheck: true,
        ),
      );

      expect(settings, sameSettings);
      expect(settings.hashCode, sameSettings.hashCode);
      expect(settings, isNot(differentSettings));
    });
  });

  group('ChatOtaSettings', () {
    test('compares settings by value', () {
      const settings = ChatOtaSettings(
        versionPath: '/api/version',
        firmwarePath: '/api/firmware',
        channel: 'beta',
        requestTimeout: Duration(seconds: 60),
        autoCheck: true,
      );

      const sameSettings = ChatOtaSettings(
        versionPath: '/api/version',
        firmwarePath: '/api/firmware',
        channel: 'beta',
        requestTimeout: Duration(seconds: 60),
        autoCheck: true,
      );
      const differentSettings = ChatOtaSettings(
        versionPath: '/api/version',
        firmwarePath: '/api/firmware',
        channel: 'stable',
        requestTimeout: Duration(seconds: 60),
        autoCheck: true,
      );

      expect(settings, sameSettings);
      expect(settings.hashCode, sameSettings.hashCode);
      expect(settings, isNot(differentSettings));
    });
  });
}
