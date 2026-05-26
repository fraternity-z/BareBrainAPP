import 'package:bare_brain_app/src/features/chat/domain/entities/chat_display_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatDisplaySettings', () {
    test('clamps values when copied', () {
      const settings = ChatDisplaySettings();

      final copied = settings.copyWith(
        messageFontScale: 9,
        autoScrollDelay: const Duration(seconds: -1),
        backgroundMaskOpacity: -1,
      );

      expect(copied.messageFontScale, 1.4);
      expect(copied.autoScrollDelay, Duration.zero);
      expect(copied.backgroundMaskOpacity, 0.0);
    });

    test('compares settings by value', () {
      const settings = ChatDisplaySettings(
        colorMode: ChatColorMode.dark,
        themePreset: ChatThemePreset.graphite,
        messageFontScale: 1.25,
      );

      const sameSettings = ChatDisplaySettings(
        colorMode: ChatColorMode.dark,
        themePreset: ChatThemePreset.graphite,
        messageFontScale: 1.25,
      );
      const differentSettings = ChatDisplaySettings(
        colorMode: ChatColorMode.light,
        themePreset: ChatThemePreset.graphite,
        messageFontScale: 1.25,
      );

      expect(settings, sameSettings);
      expect(settings.hashCode, sameSettings.hashCode);
      expect(settings, isNot(differentSettings));
    });
  });
}
