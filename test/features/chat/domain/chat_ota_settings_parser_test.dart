import 'package:bare_brain_app/src/core/errors/chat_exception.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_ota_settings.dart';
import 'package:bare_brain_app/src/features/chat/domain/services/chat_ota_settings_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatOtaSettingsParser', () {
    test('parses and normalizes OTA settings', () {
      final settings = ChatOtaSettingsParser.parse(
        versionPathInput: ' /api/ota/version ',
        firmwarePathInput: ' /api/ota/firmware ',
        channelInput: ' beta ',
        timeoutSecondsInput: '180',
        autoCheck: true,
      );

      expect(settings.versionPath, '/api/ota/version');
      expect(settings.firmwarePath, '/api/ota/firmware');
      expect(settings.channel, 'beta');
      expect(settings.requestTimeout, const Duration(seconds: 180));
      expect(settings.autoCheck, isTrue);
    });

    test('rejects invalid paths, channels, and timeout bounds', () {
      expect(
        () => ChatOtaSettingsParser.validate(
          const ChatOtaSettings(versionPath: 'ota/version'),
        ),
        throwsA(isA<ChatValidationException>()),
      );

      expect(
        () => ChatOtaSettingsParser.validate(
          const ChatOtaSettings(channel: 'bad channel'),
        ),
        throwsA(isA<ChatValidationException>()),
      );

      expect(
        () => ChatOtaSettingsParser.parse(
          versionPathInput: '/ota/version',
          firmwarePathInput: '/ota/firmware',
          channelInput: 'stable',
          timeoutSecondsInput: '5',
          autoCheck: false,
        ),
        throwsA(isA<ChatValidationException>()),
      );
    });
  });
}
