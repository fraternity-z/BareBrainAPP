import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';

class BareBrainTheme {
  const BareBrainTheme._();

  static ThemeData light() {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xff1f1f23),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xff1f1f23),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xffececef),
      onPrimaryContainer: const Color(0xff1f1f23),
      secondary: const Color(0xffd97745),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xffffece4),
      onSecondaryContainer: const Color(0xff7a3418),
      tertiary: const Color(0xff5b6472),
      surface: const Color(0xfffbfafc),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xfffbfafc),
      surfaceContainer: const Color(0xfff4f3f6),
      surfaceContainerHigh: const Color(0xffeeeeef),
      surfaceContainerHighest: const Color(0xffe4e4e7),
      outline: const Color(0xffd7d6dc),
      outlineVariant: const Color(0xffe3e2e8),
      onSurface: const Color(0xff17171a),
      onSurfaceVariant: const Color(0xff7d7d86),
    );

    return _build(colors).useSystemChineseFont(Brightness.light);
  }

  static ThemeData dark() {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xfff1f1f4),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xfff1f1f4),
      onPrimary: const Color(0xff17171a),
      primaryContainer: const Color(0xff323236),
      onPrimaryContainer: const Color(0xfff3f3f5),
      secondary: const Color(0xffffa071),
      onSecondary: const Color(0xff3a1607),
      secondaryContainer: const Color(0xff5a2714),
      onSecondaryContainer: const Color(0xffffdccd),
      tertiary: const Color(0xffa7aab2),
      surface: const Color(0xff101012),
      surfaceContainerLowest: const Color(0xff17171a),
      surfaceContainerLow: const Color(0xff101012),
      surfaceContainer: const Color(0xff1f1f23),
      surfaceContainerHigh: const Color(0xff2a2a2f),
      surfaceContainerHighest: const Color(0xff34343a),
      outline: const Color(0xff575760),
      outlineVariant: const Color(0xff37373d),
      onSurface: const Color(0xfff3f3f5),
      onSurfaceVariant: const Color(0xffaaaab2),
    );

    return _build(colors).useSystemChineseFont(Brightness.dark);
  }

  static ThemeData _build(ColorScheme colors) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surfaceContainerLow,
    );
    final textTheme = _textTheme(base.textTheme, colors);

    return base.copyWith(
      textTheme: textTheme,
      dividerColor: colors.outlineVariant,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        showDragHandle: true,
        dragHandleColor: colors.outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surface,
        shape: const RoundedRectangleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.outline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          fixedSize: const Size.square(40),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          foregroundColor: colors.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: TextStyle(color: colors.onSurfaceVariant),
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        floatingLabelStyle: TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.error, width: 1.4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        iconColor: colors.onSurfaceVariant,
        textColor: colors.onSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme source, ColorScheme colors) {
    return source
        .apply(
          bodyColor: colors.onSurface,
          displayColor: colors.onSurface,
        )
        .copyWith(
          headlineSmall: source.headlineSmall?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          titleLarge: source.titleLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          titleMedium: source.titleMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          bodyMedium: source.bodyMedium?.copyWith(
            color: colors.onSurface,
            height: 1.42,
            letterSpacing: 0,
          ),
          bodySmall: source.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.35,
            letterSpacing: 0,
          ),
          labelLarge: source.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
          labelSmall: source.labelSmall?.copyWith(letterSpacing: 0),
        );
  }
}
