import 'package:flutter/material.dart';
import 'package:login_again/styles/loading/ui_utils.dart';
import 'package:login_again/styles/loading/theme/color_prefs.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double? width;
  final double? height;
  final bool play;
  final bool dimBackground;

  const AppLoadingIndicator({
    super.key,
    this.width,
    this.height,
    this.play = true,
    this.dimBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    UiUtils.setContext(context);
    final indicator = UiUtils.progress(
      width: width,
      height: height,
      play: play,
      normalProgressColor: Theme.of(context).colorScheme.tertiaryColor,
    );

    if (!dimBackground) return indicator;

    return Stack(
      children: [
        Positioned.fill(child: Container(color: const Color(0x66000000))),
        Center(child: indicator),
      ],
    );
  }
}
