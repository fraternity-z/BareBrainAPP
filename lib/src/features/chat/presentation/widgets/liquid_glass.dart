import 'dart:math' as math;

import 'package:flutter/material.dart';

enum LiquidGlassIntensity {
  subtle,
  balanced,
  prominent,
}

class LiquidGlassBackdrop extends StatefulWidget {
  const LiquidGlassBackdrop({
    required this.baseColor,
    required this.child,
    super.key,
  });

  final Color baseColor;
  final Widget child;

  @override
  State<LiquidGlassBackdrop> createState() => _LiquidGlassBackdropState();
}

class _LiquidGlassBackdropState extends State<LiquidGlassBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: widget.baseColor,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _LiquidGlassBackdropPainter(
                        colors: colors,
                        baseColor: widget.baseColor,
                        progress: _controller.value,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.padding,
    this.tint,
    this.accentColor,
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
  final Color? accentColor;
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
    final effectiveAccent = accentColor ?? colors.primary;
    final effectiveBorder = borderColor ?? colors.outlineVariant;
    final effectiveShadowColor = shadowColor ?? colors.shadow;
    final effectiveShadowAlpha = shadowAlpha ?? tokens.shadowAlpha;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
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
                BoxShadow(
                  color: effectiveAccent.withValues(
                    alpha: effectiveShadowAlpha * 0.38,
                  ),
                  blurRadius: tokens.shadowBlur * 1.28,
                  offset: Offset(0, tokens.shadowOffset * 0.58),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _LiquidGlassFillPainter(
            borderRadius: borderRadius,
            tint: effectiveTint,
            accentColor: effectiveAccent,
            tokens: tokens,
          ),
          foregroundPainter: _LiquidGlassRimPainter(
            borderRadius: borderRadius,
            borderColor: effectiveBorder.withValues(
              alpha: borderOpacity.clamp(0.0, 1.0).toDouble(),
            ),
            accentColor: effectiveAccent,
            tokens: tokens,
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _LiquidGlassBackdropPainter extends CustomPainter {
  const _LiquidGlassBackdropPainter({
    required this.colors,
    required this.baseColor,
    required this.progress,
  });

  final ColorScheme colors;
  final Color baseColor;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final rect = Offset.zero & size;
    final phase = progress * math.pi * 2;
    final isDark = colors.brightness == Brightness.dark;
    canvas.drawRect(rect, Paint()..color = baseColor);

    final wash = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          colors.primary.withValues(alpha: isDark ? 0.10 : 0.06),
          colors.surface.withValues(alpha: 0),
          colors.secondary.withValues(alpha: isDark ? 0.09 : 0.05),
        ],
        stops: const <double>[0, 0.48, 1],
      ).createShader(rect);
    canvas.drawRect(rect, wash);

    _drawRibbon(
      canvas,
      rect,
      phase: phase,
      yFactor: 0.18,
      thickness: 0.23,
      color: colors.primary.withValues(alpha: isDark ? 0.16 : 0.09),
      reverse: false,
    );
    _drawRibbon(
      canvas,
      rect,
      phase: phase + math.pi * 0.78,
      yFactor: 0.64,
      thickness: 0.20,
      color: colors.secondary.withValues(alpha: isDark ? 0.14 : 0.08),
      reverse: true,
    );
    _drawCausticLine(
      canvas,
      rect,
      phase: phase + 0.9,
      yFactor: 0.36,
      alpha: isDark ? 0.13 : 0.20,
    );
    _drawCausticLine(
      canvas,
      rect,
      phase: phase + math.pi,
      yFactor: 0.76,
      alpha: isDark ? 0.10 : 0.15,
    );
  }

  void _drawRibbon(
    Canvas canvas,
    Rect rect, {
    required double phase,
    required double yFactor,
    required double thickness,
    required Color color,
    required bool reverse,
  }) {
    final width = rect.width;
    final height = rect.height;
    final drift = math.sin(phase) * height * 0.025;
    final top = height * yFactor + drift;
    final depth = height * thickness;
    final direction = reverse ? -1.0 : 1.0;
    final path = Path()
      ..moveTo(-width * 0.12, top)
      ..cubicTo(
        width * 0.18,
        top - depth * 0.55 * direction,
        width * 0.42,
        top + depth * 0.68 * direction,
        width * 0.72,
        top + depth * 0.06,
      )
      ..cubicTo(
        width * 0.92,
        top - depth * 0.45 * direction,
        width * 1.05,
        top + depth * 0.24 * direction,
        width * 1.12,
        top,
      )
      ..lineTo(width * 1.12, top + depth)
      ..cubicTo(
        width * 0.82,
        top + depth * 1.12,
        width * 0.52,
        top + depth * 0.55,
        width * 0.22,
        top + depth * 0.98,
      )
      ..cubicTo(
        width * 0.06,
        top + depth * 1.22,
        -width * 0.04,
        top + depth * 0.72,
        -width * 0.12,
        top + depth,
      )
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: reverse ? Alignment.centerRight : Alignment.centerLeft,
        end: reverse ? Alignment.centerLeft : Alignment.centerRight,
        colors: <Color>[
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ],
        stops: const <double>[0, 0.48, 1],
      ).createShader(rect);
    canvas.drawPath(path, paint);
  }

  void _drawCausticLine(
    Canvas canvas,
    Rect rect, {
    required double phase,
    required double yFactor,
    required double alpha,
  }) {
    final width = rect.width;
    final y = rect.height * yFactor + math.sin(phase) * rect.height * 0.018;
    final path = Path()
      ..moveTo(width * 0.07, y)
      ..cubicTo(
        width * 0.24,
        y - 34,
        width * 0.38,
        y + 26,
        width * 0.55,
        y - 4,
      )
      ..cubicTo(
        width * 0.72,
        y - 34,
        width * 0.84,
        y + 22,
        width * 0.96,
        y - 12,
      );
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassBackdropPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.baseColor != baseColor ||
        oldDelegate.progress != progress;
  }
}

class _LiquidGlassFillPainter extends CustomPainter {
  const _LiquidGlassFillPainter({
    required this.borderRadius,
    required this.tint,
    required this.accentColor,
    required this.tokens,
  });

  final BorderRadius borderRadius;
  final Color tint;
  final Color accentColor;
  final _LiquidGlassTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    canvas.save();
    canvas.clipRRect(rrect);

    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color.alphaBlend(
            Colors.white.withValues(alpha: tokens.lightLiftAlpha),
            tint,
          ).withValues(alpha: tokens.baseAlpha),
          tint.withValues(alpha: tokens.baseAlpha * 0.88),
          Color.alphaBlend(
            accentColor.withValues(alpha: tokens.accentMixAlpha),
            tint,
          ).withValues(alpha: tokens.baseAlpha),
        ],
        stops: const <double>[0, 0.56, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, basePaint);

    _drawFluidSheet(
      canvas,
      rect,
      color: accentColor.withValues(alpha: tokens.sheetAlpha),
      upper: true,
    );
    _drawFluidSheet(
      canvas,
      rect,
      color: Colors.white.withValues(alpha: tokens.lightSheetAlpha),
      upper: false,
    );
    _drawSpecularPool(canvas, rect, rrect);

    canvas.restore();
  }

  void _drawFluidSheet(
    Canvas canvas,
    Rect rect, {
    required Color color,
    required bool upper,
  }) {
    final width = rect.width;
    final height = rect.height;
    final top = upper ? height * 0.12 : height * 0.50;
    final depth = upper ? height * 0.34 : height * 0.30;
    final path = Path()
      ..moveTo(0, top)
      ..cubicTo(
        width * 0.28,
        top + depth * (upper ? -0.46 : 0.42),
        width * 0.52,
        top + depth * (upper ? 0.66 : -0.24),
        width,
        top + depth * (upper ? 0.10 : 0.32),
      )
      ..lineTo(width, top + depth)
      ..cubicTo(
        width * 0.70,
        top + depth * 0.68,
        width * 0.34,
        top + depth * 1.18,
        0,
        top + depth * 0.76,
      )
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: upper ? Alignment.topLeft : Alignment.bottomLeft,
        end: upper ? Alignment.bottomRight : Alignment.topRight,
        colors: <Color>[
          color.withValues(alpha: 0),
          color,
          color.withValues(alpha: 0),
        ],
        stops: const <double>[0, 0.46, 1],
      ).createShader(rect);
    canvas.drawPath(path, paint);
  }

  void _drawSpecularPool(Canvas canvas, Rect rect, RRect rrect) {
    final shortSide = math.min(rect.width, rect.height);
    if (shortSide < 14) {
      return;
    }

    final topPool = Rect.fromLTWH(
      rect.left - rect.width * 0.16,
      rect.top - rect.height * 0.52,
      rect.width * 0.82,
      rect.height * 0.92,
    );
    final bottomPool = Rect.fromLTWH(
      rect.right - rect.width * 0.46,
      rect.bottom - rect.height * 0.42,
      rect.width * 0.58,
      rect.height * 0.54,
    );
    canvas.drawOval(
      topPool,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: tokens.specularAlpha),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(topPool),
    );
    canvas.drawOval(
      bottomPool,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            accentColor.withValues(alpha: tokens.bottomGlowAlpha),
            accentColor.withValues(alpha: 0),
          ],
        ).createShader(bottomPool),
    );
    canvas.drawRRect(
      rrect.deflate(1),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: tokens.innerWashAlpha),
            Colors.white.withValues(alpha: 0),
            Colors.black.withValues(alpha: tokens.innerShadeAlpha),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassFillPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.tint != tint ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.tokens != tokens;
  }
}

class _LiquidGlassRimPainter extends CustomPainter {
  const _LiquidGlassRimPainter({
    required this.borderRadius,
    required this.borderColor,
    required this.accentColor,
    required this.tokens,
  });

  final BorderRadius borderRadius;
  final Color borderColor;
  final Color accentColor;
  final _LiquidGlassTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(0.5);
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Colors.white.withValues(alpha: tokens.rimLightAlpha),
          borderColor,
          accentColor.withValues(alpha: tokens.rimAccentAlpha),
          Colors.black.withValues(alpha: tokens.rimShadeAlpha),
        ],
        stops: const <double>[0, 0.34, 0.72, 1],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tokens.rimWidth;
    canvas.drawRRect(rrect, rimPaint);

    final inner = rrect.deflate(1.45);
    if (inner.width > 0 && inner.height > 0) {
      canvas.drawRRect(
        inner,
        Paint()
          ..color = Colors.white.withValues(alpha: tokens.innerRimAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }

    final highlight = Path()
      ..moveTo(rect.left + rect.width * 0.12, rect.top + 2)
      ..cubicTo(
        rect.left + rect.width * 0.28,
        rect.top + rect.height * 0.08,
        rect.left + rect.width * 0.46,
        rect.top + rect.height * 0.02,
        rect.left + rect.width * 0.62,
        rect.top + rect.height * 0.10,
      );
    canvas.drawPath(
      highlight,
      Paint()
        ..color = Colors.white.withValues(alpha: tokens.edgeGlintAlpha)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.0, tokens.rimWidth),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassRimPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.tokens != tokens;
  }
}

class _LiquidGlassTokens {
  const _LiquidGlassTokens({
    required this.baseAlpha,
    required this.lightLiftAlpha,
    required this.accentMixAlpha,
    required this.sheetAlpha,
    required this.lightSheetAlpha,
    required this.specularAlpha,
    required this.bottomGlowAlpha,
    required this.innerWashAlpha,
    required this.innerShadeAlpha,
    required this.rimLightAlpha,
    required this.rimAccentAlpha,
    required this.rimShadeAlpha,
    required this.innerRimAlpha,
    required this.edgeGlintAlpha,
    required this.rimWidth,
    required this.shadowAlpha,
    required this.shadowBlur,
    required this.shadowOffset,
  });

  final double baseAlpha;
  final double lightLiftAlpha;
  final double accentMixAlpha;
  final double sheetAlpha;
  final double lightSheetAlpha;
  final double specularAlpha;
  final double bottomGlowAlpha;
  final double innerWashAlpha;
  final double innerShadeAlpha;
  final double rimLightAlpha;
  final double rimAccentAlpha;
  final double rimShadeAlpha;
  final double innerRimAlpha;
  final double edgeGlintAlpha;
  final double rimWidth;
  final double shadowAlpha;
  final double shadowBlur;
  final double shadowOffset;

  static _LiquidGlassTokens resolve(
    LiquidGlassIntensity intensity,
    bool isDark,
  ) {
    return switch (intensity) {
      LiquidGlassIntensity.subtle => _LiquidGlassTokens(
          baseAlpha: isDark ? 0.70 : 0.76,
          lightLiftAlpha: isDark ? 0.08 : 0.26,
          accentMixAlpha: isDark ? 0.10 : 0.08,
          sheetAlpha: isDark ? 0.07 : 0.05,
          lightSheetAlpha: isDark ? 0.06 : 0.13,
          specularAlpha: isDark ? 0.13 : 0.30,
          bottomGlowAlpha: isDark ? 0.10 : 0.08,
          innerWashAlpha: isDark ? 0.06 : 0.10,
          innerShadeAlpha: isDark ? 0.18 : 0.04,
          rimLightAlpha: isDark ? 0.24 : 0.64,
          rimAccentAlpha: isDark ? 0.14 : 0.18,
          rimShadeAlpha: isDark ? 0.28 : 0.05,
          innerRimAlpha: isDark ? 0.06 : 0.16,
          edgeGlintAlpha: isDark ? 0.18 : 0.40,
          rimWidth: 0.9,
          shadowAlpha: isDark ? 0.16 : 0.07,
          shadowBlur: 18,
          shadowOffset: 8,
        ),
      LiquidGlassIntensity.balanced => _LiquidGlassTokens(
          baseAlpha: isDark ? 0.74 : 0.80,
          lightLiftAlpha: isDark ? 0.11 : 0.34,
          accentMixAlpha: isDark ? 0.16 : 0.12,
          sheetAlpha: isDark ? 0.10 : 0.07,
          lightSheetAlpha: isDark ? 0.08 : 0.18,
          specularAlpha: isDark ? 0.18 : 0.38,
          bottomGlowAlpha: isDark ? 0.14 : 0.11,
          innerWashAlpha: isDark ? 0.08 : 0.14,
          innerShadeAlpha: isDark ? 0.20 : 0.05,
          rimLightAlpha: isDark ? 0.30 : 0.74,
          rimAccentAlpha: isDark ? 0.18 : 0.24,
          rimShadeAlpha: isDark ? 0.34 : 0.06,
          innerRimAlpha: isDark ? 0.08 : 0.20,
          edgeGlintAlpha: isDark ? 0.22 : 0.48,
          rimWidth: 1.1,
          shadowAlpha: isDark ? 0.20 : 0.10,
          shadowBlur: 24,
          shadowOffset: 10,
        ),
      LiquidGlassIntensity.prominent => _LiquidGlassTokens(
          baseAlpha: isDark ? 0.82 : 0.88,
          lightLiftAlpha: isDark ? 0.13 : 0.42,
          accentMixAlpha: isDark ? 0.22 : 0.18,
          sheetAlpha: isDark ? 0.14 : 0.11,
          lightSheetAlpha: isDark ? 0.10 : 0.24,
          specularAlpha: isDark ? 0.22 : 0.46,
          bottomGlowAlpha: isDark ? 0.18 : 0.15,
          innerWashAlpha: isDark ? 0.10 : 0.18,
          innerShadeAlpha: isDark ? 0.22 : 0.06,
          rimLightAlpha: isDark ? 0.36 : 0.82,
          rimAccentAlpha: isDark ? 0.24 : 0.30,
          rimShadeAlpha: isDark ? 0.38 : 0.08,
          innerRimAlpha: isDark ? 0.10 : 0.24,
          edgeGlintAlpha: isDark ? 0.26 : 0.56,
          rimWidth: 1.25,
          shadowAlpha: isDark ? 0.24 : 0.14,
          shadowBlur: 30,
          shadowOffset: 12,
        ),
    };
  }
}
