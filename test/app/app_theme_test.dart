import 'package:bare_brain_app/src/app/app_theme.dart';
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

      expect(theme.colorScheme.primary, const Color(0xff1f1f23));
      expect(theme.colorScheme.secondary, const Color(0xffd97745));
      expect(theme.scaffoldBackgroundColor, const Color(0xfffbfafc));
      expect(border, isA<OutlineInputBorder>());
      expect(
        (border as OutlineInputBorder).borderRadius,
        BorderRadius.circular(18),
      );
    });
  });
}
