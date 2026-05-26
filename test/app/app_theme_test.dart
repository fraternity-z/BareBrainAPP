import 'package:bare_brain_app/src/app/app_theme.dart';
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
  });
}
