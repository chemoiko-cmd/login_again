import 'package:flutter/material.dart';

import 'ui_utils.dart';
import 'theme/color_prefs.dart';

class Widgets {
  static bool isLoaderShowing = false;

  static Future<void> showLoader(BuildContext? context) async {
    if (context == null || !context.mounted || isLoaderShowing) return;

    try {
      isLoaderShowing = true;

      await showDialog<dynamic>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return SafeArea(
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Center(
                child: UiUtils.progress(
                  normalProgressColor: Theme.of(
                    context,
                  ).colorScheme.tertiaryColor,
                ),
              ),
            ),
          );
        },
      );
    } on Exception {
      isLoaderShowing = false;
    }
  }

  static void hideLoader(BuildContext? context) {
    if (context == null || !context.mounted || !isLoaderShowing) return;

    try {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
      isLoaderShowing = false;
    } on Exception {
      isLoaderShowing = false;
    }
  }

  static void hideLoder(BuildContext? context) {
    hideLoader(context);
  }
}
