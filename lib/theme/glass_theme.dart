import 'dart:ui';
import 'package:flutter/material.dart';

class GlassTheme extends ThemeExtension<GlassTheme> {
  final double blurSigma;
  final Color tint;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadow;

  const GlassTheme({
    required this.blurSigma,
    required this.tint,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.shadow,
  });

  static GlassTheme light() {
    return GlassTheme(
      blurSigma: 18,
      tint: const Color(0xFFFFFFFF).withValues(alpha: 0.68),
      borderColor: const Color(0xFFFFFFFF).withValues(alpha: 0.45),
      borderWidth: 1,
      borderRadius: BorderRadius.circular(24),
      shadow: [
        BoxShadow(
          color: const Color(0xFF000000).withValues(alpha: 0.10),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  @override
  ThemeExtension<GlassTheme> copyWith({
    double? blurSigma,
    Color? tint,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
  }) {
    return GlassTheme(
      blurSigma: blurSigma ?? this.blurSigma,
      tint: tint ?? this.tint,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  ThemeExtension<GlassTheme> lerp(
    covariant ThemeExtension<GlassTheme>? other,
    double t,
  ) {
    if (other is! GlassTheme) return this;

    return GlassTheme(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
      tint: Color.lerp(tint, other.tint, t) ?? tint,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t) ?? borderWidth,
      borderRadius:
          BorderRadius.lerp(borderRadius, other.borderRadius, t) ??
          borderRadius,
      shadow: t < 0.5 ? shadow : other.shadow,
    );
  }
}

extension GlassThemeX on BuildContext {
  GlassTheme get glass {
    final ext = Theme.of(this).extension<GlassTheme>();
    if (ext == null) {
      return GlassTheme.light();
    }
    return ext;
  }
}
