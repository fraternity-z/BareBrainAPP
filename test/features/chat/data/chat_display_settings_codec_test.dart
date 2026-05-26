import 'package:bare_brain_app/src/features/chat/data/models/chat_display_settings_codec.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_display_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatDisplaySettingsCodec', () {
    test('round trips all display settings', () {
      const settings = ChatDisplaySettings(
        colorMode: ChatColorMode.dark,
        themePreset: ChatThemePreset.warmSun,
        showMessageTimestamps: false,
        showMessageActions: false,
        compactMessageSpacing: true,
        selectableMessageText: false,
        hapticFeedback: false,
        messageBackground: ChatMessageBackground.soft,
        appFont: ChatAppFont.sans,
        codeFont: ChatCodeFont.mono,
        messageFontScale: 1.25,
        autoScrollDelay: Duration(seconds: 2),
        backgroundMaskOpacity: 0.75,
      );

      final restored = ChatDisplaySettingsCodec.decode(
        ChatDisplaySettingsCodec.encode(settings),
      );

      expect(restored.colorMode, ChatColorMode.dark);
      expect(restored.themePreset, ChatThemePreset.warmSun);
      expect(restored.showMessageTimestamps, isFalse);
      expect(restored.showMessageActions, isFalse);
      expect(restored.compactMessageSpacing, isTrue);
      expect(restored.selectableMessageText, isFalse);
      expect(restored.hapticFeedback, isFalse);
      expect(restored.messageBackground, ChatMessageBackground.soft);
      expect(restored.appFont, ChatAppFont.sans);
      expect(restored.codeFont, ChatCodeFont.mono);
      expect(restored.messageFontScale, 1.25);
      expect(restored.autoScrollDelay, const Duration(seconds: 2));
      expect(restored.backgroundMaskOpacity, 0.75);
    });

    test('uses defaults for unknown enum values and missing fields', () {
      final restored = ChatDisplaySettingsCodec.fromJson(
        <String, dynamic>{
          'colorMode': 'unknown',
          'themePreset': 'unknown',
          'messageFontScale': 9.0,
          'autoScrollDelayMs': -1000,
          'backgroundMaskOpacity': -1.0,
        },
      );

      expect(restored.colorMode, ChatColorMode.system);
      expect(restored.themePreset, ChatThemePreset.seaFog);
      expect(restored.messageFontScale, 1.4);
      expect(restored.autoScrollDelay, Duration.zero);
      expect(restored.backgroundMaskOpacity, 0.0);
    });

    test('rejects non-object payloads', () {
      expect(
        () => ChatDisplaySettingsCodec.decode('[]'),
        throwsFormatException,
      );
    });
  });
}
