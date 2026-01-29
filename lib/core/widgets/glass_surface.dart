import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:login_again/theme/glass_theme.dart';

class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final bool enableBlur;
  final Color? tint;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? shadow;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.enableBlur = true,
    this.tint,
    this.borderColor,
    this.borderWidth,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final resolvedBorderRadius = borderRadius ?? glass.borderRadius;

    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: (tint ?? glass.tint),
        borderRadius: resolvedBorderRadius,
        border: Border.all(
          color: (borderColor ?? glass.borderColor),
          width: borderWidth ?? glass.borderWidth,
        ),
        boxShadow: shadow ?? glass.shadow,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (!enableBlur) {
      return ClipRRect(borderRadius: resolvedBorderRadius, child: surface);
    }

    return ClipRRect(
      borderRadius: resolvedBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: surface,
      ),
    );
  }
}
