import 'package:flutter/material.dart';

extension ColorPrefs on ColorScheme {
  Color get tertiaryColor => primary;

  Color get buttonColor =>
      brightness == Brightness.light ? Colors.white : Colors.black;

  Color get borderColor => outline;

  Color get backgroundColor => surface;
}
