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
      tertiary: const Color(0xff666666),
      tertiaryContainer: const Color(0xffeeeeee),
      onTertiaryContainer: const Color(0xff303030),
      surface: const Color(0xfffafafa),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xfff5f5f5),
      surfaceContainer: const Color(0xffefefef),
      surfaceContainerHigh: const Color(0xffe8e8e8),
      surfaceContainerHighest: const Color(0xffdddddd),
      outline: const Color(0xffd0d0d0),
      outlineVariant: const Color(0xffe4e4e4),
      onSurface: const Color(0xff171717),
      onSurfaceVariant: const Color(0xff737373),
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
      tertiary: const Color(0xffb8b8b8),
      surface: const Color(0xff101010),
      surfaceContainerLowest: const Color(0xff171717),
      surfaceContainerLow: const Color(0xff101010),
      surfaceContainer: const Color(0xff1f1f1f),
      surfaceContainerHigh: const Color(0xff2a2a2a),
      surfaceContainerHighest: const Color(0xff343434),
      outline: const Color(0xff575757),
      outlineVariant: const Color(0xff373737),
      onSurface: const Color(0xfff3f3f3),
      onSurfaceVariant: const Color(0xffababab),
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
          seed: Color(0xff4a4a4a),
          primary: Color(0xff4a4a4a),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffeeeeee),
          onPrimaryContainer: Color(0xff2f2f2f),
          secondary: Color(0xff737373),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xfff5f5f5),
          onSecondaryContainer: Color(0xff3d3d3d),
        ),
      ChatThemePreset.graphite => const _ThemePalette(
          seed: Color(0xff202020),
          primary: Color(0xff202020),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffe9e9e9),
          onPrimaryContainer: Color(0xff202020),
          secondary: Color(0xff666666),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffeeeeee),
          onSecondaryContainer: Color(0xff303030),
        ),
      ChatThemePreset.warmSun => const _ThemePalette(
          seed: Color(0xff2b2b2b),
          primary: Color(0xff2b2b2b),
          onPrimary: Colors.white,
          primaryContainer: Color(0xfff0f0f0),
          onPrimaryContainer: Color(0xff242424),
          secondary: Color(0xff8a8a8a),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xfff4f4f4),
          onSecondaryContainer: Color(0xff3a3a3a),
        ),
    };
  }

  static _ThemePalette dark(ChatThemePreset preset) {
    return switch (preset) {
      ChatThemePreset.seaFog => const _ThemePalette(
          seed: Color(0xffd4d4d4),
          primary: Color(0xffd4d4d4),
          onPrimary: Color(0xff242424),
          primaryContainer: Color(0xff3a3a3a),
          onPrimaryContainer: Color(0xfff5f5f5),
          secondary: Color(0xffb8b8b8),
          onSecondary: Color(0xff202020),
          secondaryContainer: Color(0xff444444),
          onSecondaryContainer: Color(0xfff0f0f0),
        ),
      ChatThemePreset.graphite => const _ThemePalette(
          seed: Color(0xfff1f1f1),
          primary: Color(0xfff1f1f1),
          onPrimary: Color(0xff171717),
          primaryContainer: Color(0xff323232),
          onPrimaryContainer: Color(0xfff3f3f3),
          secondary: Color(0xffb3b3b3),
          onSecondary: Color(0xff202020),
          secondaryContainer: Color(0xff383838),
          onSecondaryContainer: Color(0xfff0f0f0),
        ),
      ChatThemePreset.warmSun => const _ThemePalette(
          seed: Color(0xffffffff),
          primary: Color(0xffffffff),
          onPrimary: Color(0xff111111),
          primaryContainer: Color(0xff2b2b2b),
          onPrimaryContainer: Color(0xfff7f7f7),
          secondary: Color(0xffc8c8c8),
          onSecondary: Color(0xff171717),
          secondaryContainer: Color(0xff3f3f3f),
          onSecondaryContainer: Color(0xfff1f1f1),
        ),
    };
  }
}
