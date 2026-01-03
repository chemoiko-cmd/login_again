import 'package:flutter/material.dart';

/// App brand color palette (copied from bloc_nav_app styles)
/// Plain color constants for use across widgets without theme wiring.
class AppColors {
  AppColors._();

  // Brand & accents
  static const Color primary = Color(0xFF4C66EE); // buttonColor
  static const Color secondary = Color(0xFF4BACF7); // blueColor

  // Light surfaces
  static const Color backgroundLight = Color(0xFFFFFFFF); // white
  static const Color surface = Color(0xFFFFFFFF); // cards, tiles
  static const Color border = Color(0xFFE6E8E8); // dividers, outlines

  // Feedback
  static const Color success = Color(0xFF024751);
  static const Color warning = Color(0xFFDFE94B);
  static const Color error = Color(0xFFEF4444);

  // Text neutrals
  static const Color textPrimary = Color(0xFF161D28);
  static const Color textSecondary = Color(0xFF212E3E);

  // Dark (kept for completeness)
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color backgroundDark = Color(0xFF0F1115);
}
