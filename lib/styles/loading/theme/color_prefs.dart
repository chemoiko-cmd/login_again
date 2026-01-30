import 'package:flutter/material.dart';
import 'package:login_again/styles/colors.dart';

extension ColorPrefs on ColorScheme {
  Color get tertiaryColor => AppColors.primary;

  Color get buttonColor =>
      brightness == Brightness.light ? Colors.white : Colors.black;

  Color get borderColor => outline;

  Color get backgroundColor => surface;
}
