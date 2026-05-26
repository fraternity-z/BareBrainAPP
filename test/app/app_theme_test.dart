import 'package:bare_brain_app/src/app/app_theme.dart';
import 'package:bare_brain_app/src/features/chat/domain/entities/chat_display_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BareBrainTheme', () {
    test('applies system Chinese font fallbacks to light theme', () {
      final theme = BareBrainTheme.light();

      expect(
        theme.textTheme.bodyMedium?.fontFamilyFallback,
        contains('Microsoft YaHei'),
      );
    });

    test('applies system Chinese font fallbacks to dark theme', () {
      final theme = BareBrainTheme.dark();

      expect(
        theme.textTheme.bodyMedium?.fontFamilyFallback,
        contains('Microsoft YaHei'),
      );
    });

    test('uses clean light colors and rounded fields', () {
      final theme = BareBrainTheme.light();
      final border = theme.inputDecorationTheme.border;

      expect(theme.colorScheme.primary, const Color(0xff244f5d));
      expect(theme.colorScheme.secondary, const Color(0xff3f7886));
      expect(theme.scaffoldBackgroundColor, const Color(0xfffbfafc));
      expect(border, isA<OutlineInputBorder>());
      expect(
        (border as OutlineInputBorder).borderRadius,
        BorderRadius.circular(18),
      );
    });

    test('applies the graphite theme preset', () {
      final theme = BareBrainTheme.light(
        displaySettings: const ChatDisplaySettings(
          themePreset: ChatThemePreset.graphite,
        ),
      );

      expect(theme.colorScheme.primary, const Color(0xff1f1f23));
      expect(theme.colorScheme.secondary, const Color(0xff5b6472));
    });

    test('applies configured app font without system fallback override', () {
      final theme = BareBrainTheme.light(
        displaySettings: const ChatDisplaySettings(appFont: ChatAppFont.sans),
      );

      expect(theme.textTheme.bodyMedium?.fontFamily, 'Microsoft YaHei');
      expect(theme.textTheme.bodyMedium?.fontFamilyFallback, isNull);
    });
  });
}
