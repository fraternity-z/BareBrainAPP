import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';

import '../features/chat/domain/entities/chat_display_settings.dart';

class BareBrainTheme {
  const BareBrainTheme._();

  static ThemeData light({
    ChatDisplaySettings displaySettings = const ChatDisplaySettings(),
  }) {
    final palette = _ThemePalette.light(displaySettings.themePreset);
    final colors = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: Brightness.light,
    ).copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      secondaryContainer: palette.secondaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
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

    final theme = _build(colors, appFont: displaySettings.appFont);
    return displaySettings.appFont == ChatAppFont.system
        ? theme.useSystemChineseFont(Brightness.light)
        : theme;
  }

  static ThemeData dark({
    ChatDisplaySettings displaySettings = const ChatDisplaySettings(),
  }) {
    final palette = _ThemePalette.dark(displaySettings.themePreset);
    final colors = ColorScheme.fromSeed(
      seedColor: palette.seed,
      brightness: Brightness.dark,
    ).copyWith(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      primaryContainer: palette.primaryContainer,
      onPrimaryContainer: palette.onPrimaryContainer,
      secondary: palette.secondary,
      onSecondary: palette.onSecondary,
      secondaryContainer: palette.secondaryContainer,
      onSecondaryContainer: palette.onSecondaryContainer,
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

    final theme = _build(colors, appFont: displaySettings.appFont);
    return displaySettings.appFont == ChatAppFont.system
        ? theme.useSystemChineseFont(Brightness.dark)
        : theme;
  }

  static ThemeData _build(
    ColorScheme colors, {
    required ChatAppFont appFont,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surfaceContainerLow,
      fontFamily: appFont.fontFamily,
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

class _ThemePalette {
  const _ThemePalette({
    required this.seed,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
  });

  final Color seed;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;

  static _ThemePalette light(ChatThemePreset preset) {
    return switch (preset) {
      ChatThemePreset.seaFog => const _ThemePalette(
          seed: Color(0xff2f6879),
          primary: Color(0xff244f5d),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffdceff4),
          onPrimaryContainer: Color(0xff12333d),
          secondary: Color(0xff3f7886),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffe3f2f5),
          onSecondaryContainer: Color(0xff1e4c57),
        ),
      ChatThemePreset.graphite => const _ThemePalette(
          seed: Color(0xff1f1f23),
          primary: Color(0xff1f1f23),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffececef),
          onPrimaryContainer: Color(0xff1f1f23),
          secondary: Color(0xff5b6472),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffeceef2),
          onSecondaryContainer: Color(0xff2c3139),
        ),
      ChatThemePreset.warmSun => const _ThemePalette(
          seed: Color(0xffd97745),
          primary: Color(0xff38251d),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffffece4),
          onPrimaryContainer: Color(0xff7a3418),
          secondary: Color(0xffd97745),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffffece4),
          onSecondaryContainer: Color(0xff7a3418),
        ),
    };
  }

  static _ThemePalette dark(ChatThemePreset preset) {
    return switch (preset) {
      ChatThemePreset.seaFog => const _ThemePalette(
          seed: Color(0xffd9eef2),
          primary: Color(0xffd9eef2),
          onPrimary: Color(0xff0d2831),
          primaryContainer: Color(0xff1d424d),
          onPrimaryContainer: Color(0xffe8f8fb),
          secondary: Color(0xff8fcbd4),
          onSecondary: Color(0xff0f3038),
          secondaryContainer: Color(0xff234953),
          onSecondaryContainer: Color(0xffd7f2f7),
        ),
      ChatThemePreset.graphite => const _ThemePalette(
          seed: Color(0xfff1f1f4),
          primary: Color(0xfff1f1f4),
          onPrimary: Color(0xff17171a),
          primaryContainer: Color(0xff323236),
          onPrimaryContainer: Color(0xfff3f3f5),
          secondary: Color(0xffa7aab2),
          onSecondary: Color(0xff202126),
          secondaryContainer: Color(0xff34363d),
          onSecondaryContainer: Color(0xffeff0f4),
        ),
      ChatThemePreset.warmSun => const _ThemePalette(
          seed: Color(0xffffd2bd),
          primary: Color(0xffffeadf),
          onPrimary: Color(0xff3a1607),
          primaryContainer: Color(0xff5a2714),
          onPrimaryContainer: Color(0xffffdccd),
          secondary: Color(0xffffa071),
          onSecondary: Color(0xff3a1607),
          secondaryContainer: Color(0xff5a2714),
          onSecondaryContainer: Color(0xffffdccd),
        ),
    };
  }
}
