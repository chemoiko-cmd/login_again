import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'constant.dart';
import 'theme/color_prefs.dart';

class UiUtils {
  static BuildContext? _context;

  static void setContext(BuildContext context) {
    _context = context;
  }

  static Widget progress({
    double? width,
    double? height,
    Color? normalProgressColor,
    bool play = true,
  }) {
    final scheme = _context == null ? null : Theme.of(_context!).colorScheme;
    final primaryColor = scheme?.tertiaryColor;
    final secondaryColor = scheme?.buttonColor;

    if (Constant.useLottieProgress) {
      return LottieBuilder.asset(
        'assets/lottie/${Constant.progressLottieFile}',
        width: width ?? 45,
        height: height ?? 45,
        animate: play,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.color([
              'Layer 5 Outlines',
              'Group 1',
              '**',
            ], value: primaryColor),
            ValueDelegate.color([
              'cube 4 Outlines',
              'Group 1',
              '**',
            ], value: primaryColor),
            ValueDelegate.color([
              'cube 2 Outlines',
              'Group 1',
              '**',
            ], value: secondaryColor),
            ValueDelegate.color([
              'cube 3 Outlines',
              'Group 1',
              '**',
            ], value: secondaryColor),
          ],
        ),
      );
    }

    return CircularProgressIndicator(color: normalProgressColor);
  }
}
