import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';

class BareBrainTheme {
  const BareBrainTheme._();

  static ThemeData light() {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xff3157d7),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xff1d4ed8),
      onPrimary: Colors.white,
      secondary: const Color(0xff0f766e),
      tertiary: const Color(0xff7c3aed),
      surface: Colors.white,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xfff8fafc),
      surfaceContainer: const Color(0xfff1f5f9),
      surfaceContainerHigh: const Color(0xffe9eef5),
      surfaceContainerHighest: const Color(0xffe2e8f0),
      outline: const Color(0xffcbd5e1),
      outlineVariant: const Color(0xffe2e8f0),
    );

    return _build(colors).useSystemChineseFont(Brightness.light);
  }

  static ThemeData dark() {
    final colors = ColorScheme.fromSeed(
      seedColor: const Color(0xff6ea8ff),
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xff8bb4ff),
      onPrimary: const Color(0xff09204f),
      secondary: const Color(0xff5eead4),
      tertiary: const Color(0xffc4b5fd),
      surface: const Color(0xff111318),
      surfaceContainerLowest: const Color(0xff090b10),
      surfaceContainerLow: const Color(0xff14171f),
      surfaceContainer: const Color(0xff1b1f29),
      surfaceContainerHigh: const Color(0xff242936),
      surfaceContainerHighest: const Color(0xff303746),
      outline: const Color(0xff505867),
      outlineVariant: const Color(0xff323947),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colors.surfaceContainerLow,
        shape: const RoundedRectangleBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          fixedSize: const Size.square(40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: colors.onSurfaceVariant,
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
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.error, width: 1.4),
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
