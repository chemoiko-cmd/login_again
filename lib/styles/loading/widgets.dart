import 'package:flutter/material.dart';

import 'theme/color_prefs.dart';
import 'ui_utils.dart';

class Widgets {
  static bool isLoaderShowing = false;
  static OverlayEntry? _loaderOverlay;

  static Future<void> showLoader(BuildContext? context) async {
    if (context == null || !context.mounted || isLoaderShowing) return;

    try {
      isLoaderShowing = true;

      final overlayState = Overlay.of(context, rootOverlay: true);
      if (overlayState == null) {
        isLoaderShowing = false;
        return;
      }

      _loaderOverlay = OverlayEntry(
        builder: (overlayContext) {
          return SafeArea(
            child: Stack(
              children: [
                const ModalBarrier(dismissible: false, color: Colors.black54),
                Center(
                  child: UiUtils.progress(
                    normalProgressColor: Theme.of(
                      context,
                    ).colorScheme.tertiaryColor,
                  ),
                ),
              ],
            ),
          );
        },
      );

      overlayState.insert(_loaderOverlay!);
    } on Exception {
      isLoaderShowing = false;
    }
  }

  static void hideLoader(BuildContext? context) {
    if (!isLoaderShowing) return;

    try {
      _loaderOverlay?.remove();
      _loaderOverlay = null;
      isLoaderShowing = false;
    } on Exception {
      isLoaderShowing = false;
    }
  }

  static void hideLoder(BuildContext? context) {
    hideLoader(context);
  }
}
