import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';

import '../features/chat/domain/entities/chat_display_settings.dart';

class BareBrainTheme {
  const BareBrainTheme._();

  static ThemeData light({
    ChatDisplaySettings displaySettings = const ChatDisplaySettings(),
  }) {
    final palette = _ThemePalette.light(displaySettings.themePreset);
    const surfaces = _ThemeSurfaces.light;
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
      tertiary: palette.tertiary,
      onTertiary: palette.onTertiary,
      tertiaryContainer: palette.tertiaryContainer,
      onTertiaryContainer: palette.onTertiaryContainer,
      surface: surfaces.surface,
      surfaceContainerLowest: surfaces.surfaceContainerLowest,
      surfaceContainerLow: surfaces.surfaceContainerLow,
      surfaceContainer: surfaces.surfaceContainer,
      surfaceContainerHigh: surfaces.surfaceContainerHigh,
      surfaceContainerHighest: surfaces.surfaceContainerHighest,
      outline: surfaces.outline,
      outlineVariant: surfaces.outlineVariant,
      onSurface: surfaces.onSurface,
      onSurfaceVariant: surfaces.onSurfaceVariant,
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
    const surfaces = _ThemeSurfaces.dark;
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
      tertiary: palette.tertiary,
      onTertiary: palette.onTertiary,
      tertiaryContainer: palette.tertiaryContainer,
      onTertiaryContainer: palette.onTertiaryContainer,
      surface: surfaces.surface,
      surfaceContainerLowest: surfaces.surfaceContainerLowest,
      surfaceContainerLow: surfaces.surfaceContainerLow,
      surfaceContainer: surfaces.surfaceContainer,
      surfaceContainerHigh: surfaces.surfaceContainerHigh,
      surfaceContainerHighest: surfaces.surfaceContainerHighest,
      outline: surfaces.outline,
      outlineVariant: surfaces.outlineVariant,
      onSurface: surfaces.onSurface,
      onSurfaceVariant: surfaces.onSurfaceVariant,
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
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.outlineVariant;
          }

          if (states.contains(WidgetState.selected)) {
            return colors.onPrimary;
          }

          return colors.surfaceContainerLowest;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return colors.surfaceContainerHigh;
          }

          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }

          return colors.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colors.primary;
          }

          return colors.outlineVariant;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.primary,
        inactiveTrackColor: colors.surfaceContainerHighest,
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
        overlayColor: colors.primary.withValues(alpha: 0.14),
        thumbColor: colors.primary,
        trackHeight: 7,
        valueIndicatorColor: colors.primary,
        valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
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
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outline,
    required this.outlineVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
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
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color outline;
  final Color outlineVariant;
  final Color onSurface;
  final Color onSurfaceVariant;

  static _ThemePalette light(ChatThemePreset preset) {
    return switch (preset) {
      ChatThemePreset.monochrome => const _ThemePalette(
          seed: Color(0xff202020),
          primary: Color(0xff202020),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffe9e9e9),
          onPrimaryContainer: Color(0xff202020),
          secondary: Color(0xff666666),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffeeeeee),
          onSecondaryContainer: Color(0xff303030),
          tertiary: Color(0xff8a8a8a),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xfff0f0f0),
          onTertiaryContainer: Color(0xff242424),
          surface: Color(0xfffafafa),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xfff6f6f6),
          surfaceContainer: Color(0xffefefef),
          surfaceContainerHigh: Color(0xffe8e8e8),
          surfaceContainerHighest: Color(0xffdddddd),
          outline: Color(0xffc8c8c8),
          outlineVariant: Color(0xffe3e3e3),
          onSurface: Color(0xff171717),
          onSurfaceVariant: Color(0xff6f6f6f),
        ),
      ChatThemePreset.defaultTheme => const _ThemePalette(
          seed: Color(0xff8f3fe0),
          primary: Color(0xff8f3fe0),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffead9ff),
          onPrimaryContainer: Color(0xff3d126b),
          secondary: Color(0xff0ea69a),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffc8f4ed),
          onSecondaryContainer: Color(0xff063f3a),
          tertiary: Color(0xff64748b),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xffe2e8f0),
          onTertiaryContainer: Color(0xff1e293b),
          surface: Color(0xfffbf8ff),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xfff6efff),
          surfaceContainer: Color(0xfff0e9fb),
          surfaceContainerHigh: Color(0xffe8ddf5),
          surfaceContainerHighest: Color(0xffded0eb),
          outline: Color(0xffb6abc8),
          outlineVariant: Color(0xffded3ec),
          onSurface: Color(0xff1b1720),
          onSurfaceVariant: Color(0xff6f657c),
        ),
      ChatThemePreset.claude => const _ThemePalette(
          seed: Color(0xffd97706),
          primary: Color(0xffc45f00),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffffdfb7),
          onPrimaryContainer: Color(0xff4c2700),
          secondary: Color(0xff13977f),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffc6f2e8),
          onSecondaryContainer: Color(0xff063f36),
          tertiary: Color(0xffdc2626),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xffffdad4),
          onTertiaryContainer: Color(0xff5f140c),
          surface: Color(0xfffffbf5),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xfffff1e0),
          surfaceContainer: Color(0xfffce7cf),
          surfaceContainerHigh: Color(0xfff4d7ba),
          surfaceContainerHighest: Color(0xffecc7a3),
          outline: Color(0xffc7a27e),
          outlineVariant: Color(0xffead3bd),
          onSurface: Color(0xff24180f),
          onSurfaceVariant: Color(0xff78634d),
        ),
      ChatThemePreset.natural => const _ThemePalette(
          seed: Color(0xff31572c),
          primary: Color(0xff31572c),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffd8edc9),
          onPrimaryContainer: Color(0xff112f0f),
          secondary: Color(0xff7a6546),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffeadcc6),
          onSecondaryContainer: Color(0xff332511),
          tertiary: Color(0xff8aa37a),
          onTertiary: Color(0xff13270f),
          tertiaryContainer: Color(0xffdceccb),
          onTertiaryContainer: Color(0xff26351d),
          surface: Color(0xfffbfbf2),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xfff0f3e5),
          surfaceContainer: Color(0xffe8ecd8),
          surfaceContainerHigh: Color(0xffdfe5cd),
          surfaceContainerHighest: Color(0xffd2dabc),
          outline: Color(0xffa9b197),
          outlineVariant: Color(0xffd7ddc6),
          onSurface: Color(0xff171b12),
          onSurfaceVariant: Color(0xff667057),
        ),
      ChatThemePreset.futureTech => const _ThemePalette(
          seed: Color(0xff5271ff),
          primary: Color(0xff5271ff),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffdbe3ff),
          onPrimaryContainer: Color(0xff112a78),
          secondary: Color(0xff7c4dff),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffe8ddff),
          onSecondaryContainer: Color(0xff2a1366),
          tertiary: Color(0xff00a7c7),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xffc7f4ff),
          onTertiaryContainer: Color(0xff003b47),
          surface: Color(0xfff7f9ff),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xffeef3ff),
          surfaceContainer: Color(0xffe6ecff),
          surfaceContainerHigh: Color(0xffdce5ff),
          surfaceContainerHighest: Color(0xffd0d9f5),
          outline: Color(0xffa8b3d6),
          outlineVariant: Color(0xffd4dcf4),
          onSurface: Color(0xff151a24),
          onSurfaceVariant: Color(0xff657089),
        ),
      ChatThemePreset.gentleGradient => const _ThemePalette(
          seed: Color(0xffef4ca2),
          primary: Color(0xffef4ca2),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffffd8eb),
          onPrimaryContainer: Color(0xff671642),
          secondary: Color(0xff11aaa4),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffc8f5f1),
          onSecondaryContainer: Color(0xff073f3c),
          tertiary: Color(0xffff8a00),
          onTertiary: Color(0xff321300),
          tertiaryContainer: Color(0xffffddb6),
          onTertiaryContainer: Color(0xff522900),
          surface: Color(0xfffff7fb),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xffffeef7),
          surfaceContainer: Color(0xffffe3f1),
          surfaceContainerHigh: Color(0xffffd6ea),
          surfaceContainerHighest: Color(0xffffc7e2),
          outline: Color(0xffd8a6c1),
          outlineVariant: Color(0xfff2cfdf),
          onSurface: Color(0xff23151d),
          onSurfaceVariant: Color(0xff7b6070),
        ),
      ChatThemePreset.ocean => const _ThemePalette(
          seed: Color(0xff00a7d8),
          primary: Color(0xff0098cf),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffc8f0ff),
          onPrimaryContainer: Color(0xff00394d),
          secondary: Color(0xff0bb7c9),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffc8f6fb),
          onSecondaryContainer: Color(0xff003f46),
          tertiary: Color(0xff14b8a6),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xffc9f5ec),
          onTertiaryContainer: Color(0xff06453e),
          surface: Color(0xfff4fcff),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xffe6f8fb),
          surfaceContainer: Color(0xffd9f2f7),
          surfaceContainerHigh: Color(0xffcceaf1),
          surfaceContainerHighest: Color(0xffbae0ea),
          outline: Color(0xff8abaca),
          outlineVariant: Color(0xffc5e4ec),
          onSurface: Color(0xff101c20),
          onSurfaceVariant: Color(0xff58717a),
        ),
      ChatThemePreset.sunset => const _ThemePalette(
          seed: Color(0xffff6f1a),
          primary: Color(0xffff6f1a),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffffdbc7),
          onPrimaryContainer: Color(0xff5b1e00),
          secondary: Color(0xffffa92e),
          onSecondary: Color(0xff321900),
          secondaryContainer: Color(0xffffe2ae),
          onSecondaryContainer: Color(0xff4b2a00),
          tertiary: Color(0xffffd34a),
          onTertiary: Color(0xff302100),
          tertiaryContainer: Color(0xffffedac),
          onTertiaryContainer: Color(0xff4a3500),
          surface: Color(0xfffffbf7),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xfffff0e7),
          surfaceContainer: Color(0xffffe4d0),
          surfaceContainerHigh: Color(0xffffd6b8),
          surfaceContainerHighest: Color(0xffffc69d),
          outline: Color(0xffd39a73),
          outlineVariant: Color(0xfff1ccb4),
          onSurface: Color(0xff25160d),
          onSurfaceVariant: Color(0xff80624f),
        ),
      ChatThemePreset.cinnamonBoard => const _ThemePalette(
          seed: Color(0xff9a765f),
          primary: Color(0xff9a765f),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffead7c9),
          onPrimaryContainer: Color(0xff3e2618),
          secondary: Color(0xff6d4f3d),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffe3d2c5),
          onSecondaryContainer: Color(0xff2e2118),
          tertiary: Color(0xffb99880),
          onTertiary: Color(0xff342015),
          tertiaryContainer: Color(0xffead8ca),
          onTertiaryContainer: Color(0xff3d281b),
          surface: Color(0xfffffaf6),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xfff4ebe4),
          surfaceContainer: Color(0xffeadfd7),
          surfaceContainerHigh: Color(0xffded0c7),
          surfaceContainerHighest: Color(0xffd2c0b5),
          outline: Color(0xffb99f8f),
          outlineVariant: Color(0xffe3d2c9),
          onSurface: Color(0xff211813),
          onSurfaceVariant: Color(0xff756458),
        ),
      ChatThemePreset.horizonGreen => const _ThemePalette(
          seed: Color(0xff5fb5a6),
          primary: Color(0xff4aa99b),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffcdeee6),
          onPrimaryContainer: Color(0xff093f37),
          secondary: Color(0xff91c9ba),
          onSecondary: Color(0xff12362f),
          secondaryContainer: Color(0xffdcefe8),
          onSecondaryContainer: Color(0xff243b35),
          tertiary: Color(0xff7ad7c8),
          onTertiary: Color(0xff063f38),
          tertiaryContainer: Color(0xffd1f3ee),
          onTertiaryContainer: Color(0xff143b35),
          surface: Color(0xfff7fffb),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xffe9f7f1),
          surfaceContainer: Color(0xffdef1ea),
          surfaceContainerHigh: Color(0xffd0e8df),
          surfaceContainerHighest: Color(0xffbfddd3),
          outline: Color(0xff96bcb1),
          outlineVariant: Color(0xffcce4dc),
          onSurface: Color(0xff111d19),
          onSurfaceVariant: Color(0xff58736b),
        ),
      ChatThemePreset.cherryCoding => const _ThemePalette(
          seed: Color(0xffd7194a),
          primary: Color(0xffd7194a),
          onPrimary: Colors.white,
          primaryContainer: Color(0xffffd7df),
          onPrimaryContainer: Color(0xff67001f),
          secondary: Color(0xfff35b8f),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xffffd8e5),
          onSecondaryContainer: Color(0xff641232),
          tertiary: Color(0xffff78b3),
          onTertiary: Color(0xff611335),
          tertiaryContainer: Color(0xffffd8e8),
          onTertiaryContainer: Color(0xff661339),
          surface: Color(0xfffff7f9),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Color(0xffffedf2),
          surfaceContainer: Color(0xffffe2eb),
          surfaceContainerHigh: Color(0xffffd5e2),
          surfaceContainerHighest: Color(0xffffc6d8),
          outline: Color(0xffd5a1b0),
          outlineVariant: Color(0xfff0ccd6),
          onSurface: Color(0xff25151a),
          onSurfaceVariant: Color(0xff7d5f68),
        ),
    };
  }

  static _ThemePalette dark(ChatThemePreset preset) {
    return switch (preset) {
      ChatThemePreset.monochrome => const _ThemePalette(
          seed: Color(0xfff1f1f1),
          primary: Color(0xfff1f1f1),
          onPrimary: Color(0xff171717),
          primaryContainer: Color(0xff323232),
          onPrimaryContainer: Color(0xfff3f3f3),
          secondary: Color(0xffb3b3b3),
          onSecondary: Color(0xff202020),
          secondaryContainer: Color(0xff383838),
          onSecondaryContainer: Color(0xfff0f0f0),
          tertiary: Color(0xffc8c8c8),
          onTertiary: Color(0xff171717),
          tertiaryContainer: Color(0xff3f3f3f),
          onTertiaryContainer: Color(0xfff1f1f1),
          surface: Color(0xff101010),
          surfaceContainerLowest: Color(0xff171717),
          surfaceContainerLow: Color(0xff101010),
          surfaceContainer: Color(0xff1f1f1f),
          surfaceContainerHigh: Color(0xff2a2a2a),
          surfaceContainerHighest: Color(0xff343434),
          outline: Color(0xff575757),
          outlineVariant: Color(0xff373737),
          onSurface: Color(0xfff3f3f3),
          onSurfaceVariant: Color(0xffababab),
        ),
      ChatThemePreset.defaultTheme => const _ThemePalette(
          seed: Color(0xffc9a4ff),
          primary: Color(0xffc9a4ff),
          onPrimary: Color(0xff241133),
          primaryContainer: Color(0xff4a2470),
          onPrimaryContainer: Color(0xfff0dcff),
          secondary: Color(0xff65d9ce),
          onSecondary: Color(0xff073431),
          secondaryContainer: Color(0xff164d49),
          onSecondaryContainer: Color(0xffc7f5ef),
          tertiary: Color(0xffaeb8cc),
          onTertiary: Color(0xff1b2433),
          tertiaryContainer: Color(0xff344055),
          onTertiaryContainer: Color(0xffe2e8f0),
          surface: Color(0xff17121d),
          surfaceContainerLowest: Color(0xff20162a),
          surfaceContainerLow: Color(0xff17121d),
          surfaceContainer: Color(0xff241a2e),
          surfaceContainerHigh: Color(0xff30223d),
          surfaceContainerHighest: Color(0xff3d2b4e),
          outline: Color(0xff765c8d),
          outlineVariant: Color(0xff4f3d61),
          onSurface: Color(0xfff7f0fb),
          onSurfaceVariant: Color(0xffcdbdd9),
        ),
      ChatThemePreset.claude => const _ThemePalette(
          seed: Color(0xffffb366),
          primary: Color(0xffffb366),
          onPrimary: Color(0xff3a1b00),
          primaryContainer: Color(0xff713a00),
          onPrimaryContainer: Color(0xffffdfb7),
          secondary: Color(0xff75d9c7),
          onSecondary: Color(0xff063a34),
          secondaryContainer: Color(0xff164f46),
          onSecondaryContainer: Color(0xffc6f2e8),
          tertiary: Color(0xffff9b8c),
          onTertiary: Color(0xff4b1008),
          tertiaryContainer: Color(0xff7b2317),
          onTertiaryContainer: Color(0xffffdad4),
          surface: Color(0xff1c130d),
          surfaceContainerLowest: Color(0xff261a11),
          surfaceContainerLow: Color(0xff1c130d),
          surfaceContainer: Color(0xff2c2016),
          surfaceContainerHigh: Color(0xff3a2a1d),
          surfaceContainerHighest: Color(0xff483424),
          outline: Color(0xff8f6a48),
          outlineVariant: Color(0xff5d432d),
          onSurface: Color(0xfffff1e3),
          onSurfaceVariant: Color(0xffdcc0a4),
        ),
      ChatThemePreset.natural => const _ThemePalette(
          seed: Color(0xff9ac987),
          primary: Color(0xff9ac987),
          onPrimary: Color(0xff173713),
          primaryContainer: Color(0xff264d21),
          onPrimaryContainer: Color(0xffd8edc9),
          secondary: Color(0xffd3bc92),
          onSecondary: Color(0xff382913),
          secondaryContainer: Color(0xff55432a),
          onSecondaryContainer: Color(0xffeadcc6),
          tertiary: Color(0xffadc79b),
          onTertiary: Color(0xff21331a),
          tertiaryContainer: Color(0xff394d2e),
          onTertiaryContainer: Color(0xffdceccb),
          surface: Color(0xff12180f),
          surfaceContainerLowest: Color(0xff192214),
          surfaceContainerLow: Color(0xff12180f),
          surfaceContainer: Color(0xff202b1b),
          surfaceContainerHigh: Color(0xff2b3724),
          surfaceContainerHighest: Color(0xff36452c),
          outline: Color(0xff748060),
          outlineVariant: Color(0xff49553b),
          onSurface: Color(0xfff1f6e9),
          onSurfaceVariant: Color(0xffc7d2b7),
        ),
      ChatThemePreset.futureTech => const _ThemePalette(
          seed: Color(0xff9fb3ff),
          primary: Color(0xff9fb3ff),
          onPrimary: Color(0xff13255c),
          primaryContainer: Color(0xff2644a5),
          onPrimaryContainer: Color(0xffdbe3ff),
          secondary: Color(0xffc3adff),
          onSecondary: Color(0xff27145a),
          secondaryContainer: Color(0xff3b2682),
          onSecondaryContainer: Color(0xffe8ddff),
          tertiary: Color(0xff72dcf2),
          onTertiary: Color(0xff00343f),
          tertiaryContainer: Color(0xff005265),
          onTertiaryContainer: Color(0xffc7f4ff),
          surface: Color(0xff101522),
          surfaceContainerLowest: Color(0xff161d31),
          surfaceContainerLow: Color(0xff101522),
          surfaceContainer: Color(0xff1a2340),
          surfaceContainerHigh: Color(0xff243056),
          surfaceContainerHighest: Color(0xff2e3c69),
          outline: Color(0xff68769e),
          outlineVariant: Color(0xff404d73),
          onSurface: Color(0xfff2f5ff),
          onSurfaceVariant: Color(0xffc4cce5),
        ),
      ChatThemePreset.gentleGradient => const _ThemePalette(
          seed: Color(0xffff9bd0),
          primary: Color(0xffff9bd0),
          onPrimary: Color(0xff561035),
          primaryContainer: Color(0xff8a2359),
          onPrimaryContainer: Color(0xffffd8eb),
          secondary: Color(0xff69dbd4),
          onSecondary: Color(0xff073835),
          secondaryContainer: Color(0xff15524e),
          onSecondaryContainer: Color(0xffc8f5f1),
          tertiary: Color(0xffffba6b),
          onTertiary: Color(0xff4a2600),
          tertiaryContainer: Color(0xff744000),
          onTertiaryContainer: Color(0xffffddb6),
          surface: Color(0xff21131b),
          surfaceContainerLowest: Color(0xff2c1925),
          surfaceContainerLow: Color(0xff21131b),
          surfaceContainer: Color(0xff35202d),
          surfaceContainerHigh: Color(0xff432839),
          surfaceContainerHighest: Color(0xff523045),
          outline: Color(0xff95647e),
          outlineVariant: Color(0xff663d53),
          onSurface: Color(0xffffeff6),
          onSurfaceVariant: Color(0xffe6bfd1),
        ),
      ChatThemePreset.ocean => const _ThemePalette(
          seed: Color(0xff7cdbff),
          primary: Color(0xff7cdbff),
          onPrimary: Color(0xff003549),
          primaryContainer: Color(0xff00516d),
          onPrimaryContainer: Color(0xffc8f0ff),
          secondary: Color(0xff70dce8),
          onSecondary: Color(0xff00363c),
          secondaryContainer: Color(0xff00525b),
          onSecondaryContainer: Color(0xffc8f6fb),
          tertiary: Color(0xff73dacb),
          onTertiary: Color(0xff053832),
          tertiaryContainer: Color(0xff07544b),
          onTertiaryContainer: Color(0xffc9f5ec),
          surface: Color(0xff0e181d),
          surfaceContainerLowest: Color(0xff132128),
          surfaceContainerLow: Color(0xff0e181d),
          surfaceContainer: Color(0xff182a32),
          surfaceContainerHigh: Color(0xff203844),
          surfaceContainerHighest: Color(0xff294755),
          outline: Color(0xff5f8290),
          outlineVariant: Color(0xff395764),
          onSurface: Color(0xffedf8fb),
          onSurfaceVariant: Color(0xffbdd4dc),
        ),
      ChatThemePreset.sunset => const _ThemePalette(
          seed: Color(0xffffa26b),
          primary: Color(0xffffa26b),
          onPrimary: Color(0xff4a1b00),
          primaryContainer: Color(0xff7b3500),
          onPrimaryContainer: Color(0xffffdbc7),
          secondary: Color(0xffffc36d),
          onSecondary: Color(0xff402400),
          secondaryContainer: Color(0xff6d4700),
          onSecondaryContainer: Color(0xffffe2ae),
          tertiary: Color(0xffffdd69),
          onTertiary: Color(0xff3c2a00),
          tertiaryContainer: Color(0xff665000),
          onTertiaryContainer: Color(0xffffedac),
          surface: Color(0xff21140c),
          surfaceContainerLowest: Color(0xff2d1b10),
          surfaceContainerLow: Color(0xff21140c),
          surfaceContainer: Color(0xff382315),
          surfaceContainerHigh: Color(0xff462c1a),
          surfaceContainerHighest: Color(0xff573822),
          outline: Color(0xff9a6f50),
          outlineVariant: Color(0xff674831),
          onSurface: Color(0xfffff0e7),
          onSurfaceVariant: Color(0xffe5c1aa),
        ),
      ChatThemePreset.cinnamonBoard => const _ThemePalette(
          seed: Color(0xffd8b69e),
          primary: Color(0xffd8b69e),
          onPrimary: Color(0xff3b2517),
          primaryContainer: Color(0xff5a3d2b),
          onPrimaryContainer: Color(0xffead7c9),
          secondary: Color(0xffcbb4a3),
          onSecondary: Color(0xff34261d),
          secondaryContainer: Color(0xff4d392c),
          onSecondaryContainer: Color(0xffe3d2c5),
          tertiary: Color(0xffdfbea5),
          onTertiary: Color(0xff3d281b),
          tertiaryContainer: Color(0xff614631),
          onTertiaryContainer: Color(0xffead8ca),
          surface: Color(0xff1a130f),
          surfaceContainerLowest: Color(0xff241a15),
          surfaceContainerLow: Color(0xff1a130f),
          surfaceContainer: Color(0xff2d211a),
          surfaceContainerHigh: Color(0xff3a2b22),
          surfaceContainerHighest: Color(0xff47352a),
          outline: Color(0xff7f6657),
          outlineVariant: Color(0xff564238),
          onSurface: Color(0xfffff0e8),
          onSurfaceVariant: Color(0xffd8c3b6),
        ),
      ChatThemePreset.horizonGreen => const _ThemePalette(
          seed: Color(0xff91d8c8),
          primary: Color(0xff91d8c8),
          onPrimary: Color(0xff103a34),
          primaryContainer: Color(0xff1b564e),
          onPrimaryContainer: Color(0xffcdeee6),
          secondary: Color(0xffb6dfd2),
          onSecondary: Color(0xff213931),
          secondaryContainer: Color(0xff314f46),
          onSecondaryContainer: Color(0xffdcefe8),
          tertiary: Color(0xff9ee6dc),
          onTertiary: Color(0xff0f3b36),
          tertiaryContainer: Color(0xff1e5953),
          onTertiaryContainer: Color(0xffd1f3ee),
          surface: Color(0xff101b17),
          surfaceContainerLowest: Color(0xff17241f),
          surfaceContainerLow: Color(0xff101b17),
          surfaceContainer: Color(0xff1d2d27),
          surfaceContainerHigh: Color(0xff263a32),
          surfaceContainerHighest: Color(0xff30483f),
          outline: Color(0xff66857b),
          outlineVariant: Color(0xff405b52),
          onSurface: Color(0xffeffaf5),
          onSurfaceVariant: Color(0xffc5d9d2),
        ),
      ChatThemePreset.cherryCoding => const _ThemePalette(
          seed: Color(0xffff9ab5),
          primary: Color(0xffff9ab5),
          onPrimary: Color(0xff5b0b26),
          primaryContainer: Color(0xff8c173a),
          onPrimaryContainer: Color(0xffffd7df),
          secondary: Color(0xffffa6c3),
          onSecondary: Color(0xff5b1730),
          secondaryContainer: Color(0xff862449),
          onSecondaryContainer: Color(0xffffd8e5),
          tertiary: Color(0xffffabc9),
          onTertiary: Color(0xff5c1534),
          tertiaryContainer: Color(0xff8b2652),
          onTertiaryContainer: Color(0xffffd8e8),
          surface: Color(0xff211217),
          surfaceContainerLowest: Color(0xff2c181f),
          surfaceContainerLow: Color(0xff211217),
          surfaceContainer: Color(0xff351f27),
          surfaceContainerHigh: Color(0xff442832),
          surfaceContainerHighest: Color(0xff53313e),
          outline: Color(0xff986676),
          outlineVariant: Color(0xff67404c),
          onSurface: Color(0xffffeef3),
          onSurfaceVariant: Color(0xffe7bdca),
        ),
    };
  }
}

class _ThemeSurfaces {
  const _ThemeSurfaces({
    required this.surface,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outline,
    required this.outlineVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
  });

  final Color surface;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color outline;
  final Color outlineVariant;
  final Color onSurface;
  final Color onSurfaceVariant;

  static const light = _ThemeSurfaces(
    surface: Color(0xfffafafa),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xfff6f6f6),
    surfaceContainer: Color(0xffefefef),
    surfaceContainerHigh: Color(0xffe8e8e8),
    surfaceContainerHighest: Color(0xffdddddd),
    outline: Color(0xffc8c8c8),
    outlineVariant: Color(0xffe3e3e3),
    onSurface: Color(0xff171717),
    onSurfaceVariant: Color(0xff6f6f6f),
  );

  static const dark = _ThemeSurfaces(
    surface: Color(0xff101010),
    surfaceContainerLowest: Color(0xff171717),
    surfaceContainerLow: Color(0xff101010),
    surfaceContainer: Color(0xff1f1f1f),
    surfaceContainerHigh: Color(0xff2a2a2a),
    surfaceContainerHighest: Color(0xff343434),
    outline: Color(0xff575757),
    outlineVariant: Color(0xff373737),
    onSurface: Color(0xfff3f3f3),
    onSurfaceVariant: Color(0xffababab),
  );
}
