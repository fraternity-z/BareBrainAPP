import 'package:flutter/material.dart';

enum LiquidGlassIntensity {
  subtle,
  balanced,
  prominent,
}

class LiquidGlassBackdrop extends StatelessWidget {
  const LiquidGlassBackdrop({
    required this.baseColor,
    required this.child,
    super.key,
  });

  final Color baseColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: baseColor,
      child: child,
    );
  }
}

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.tint,
    this.borderColor,
    this.shadowColor,
    this.shadowAlpha,
    this.borderOpacity = 1,
    this.intensity = LiquidGlassIntensity.balanced,
    super.key,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final Color? borderColor;
  final Color? shadowColor;
  final double? shadowAlpha;
  final double borderOpacity;
  final LiquidGlassIntensity intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = _LiquidGlassTokens.resolve(
      intensity,
      theme.brightness == Brightness.dark,
    );
    final effectiveTint = tint ?? colors.surfaceContainerLowest;
    final effectiveBorder = borderColor ?? colors.outlineVariant;
    final effectiveShadowColor = shadowColor ?? colors.shadow;
    final effectiveShadowAlpha = shadowAlpha ?? tokens.shadowAlpha;
    final effectiveBorderOpacity = borderOpacity.clamp(0.0, 1.0).toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveTint,
        borderRadius: borderRadius,
        border: Border.all(
          color: effectiveBorder.withValues(alpha: effectiveBorderOpacity),
          width: tokens.borderWidth,
        ),
        boxShadow: effectiveShadowAlpha <= 0
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: effectiveShadowColor.withValues(
                    alpha: effectiveShadowAlpha,
                  ),
                  blurRadius: tokens.shadowBlur,
                  offset: Offset(0, tokens.shadowOffset),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

class _LiquidGlassTokens {
  const _LiquidGlassTokens({
    required this.borderWidth,
    required this.shadowAlpha,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  final double borderWidth;
  final double shadowAlpha;
  final double shadowBlur;
  final double shadowOffset;

  static _LiquidGlassTokens resolve(
    LiquidGlassIntensity intensity,
    bool isDark,
  ) {
    return switch (intensity) {
      LiquidGlassIntensity.subtle => _LiquidGlassTokens(
          borderWidth: 0.9,
          shadowAlpha: isDark ? 0.16 : 0.07,
          shadowBlur: 18,
          shadowOffset: 8,
        ),
      LiquidGlassIntensity.balanced => _LiquidGlassTokens(
          borderWidth: 1.1,
          shadowAlpha: isDark ? 0.20 : 0.10,
          shadowBlur: 24,
          shadowOffset: 10,
        ),
      LiquidGlassIntensity.prominent => _LiquidGlassTokens(
          borderWidth: 1.25,
          shadowAlpha: isDark ? 0.24 : 0.14,
          shadowBlur: 30,
          shadowOffset: 12,
        ),
    };
  }
}
