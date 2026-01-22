import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';
import 'loading_dots.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double? width;
  final double? height;
  final bool play;
  final String assetPath;
  final bool dimBackground;

  const AppLoadingIndicator({
    super.key,
    this.width,
    this.height,
    this.play = true,
    this.assetPath = 'assets/lottie/loading.json',
    this.dimBackground = false,
  });

  Future<bool> _assetExists() async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final secondary = const Color(0xFFE6E6E6);
    return FutureBuilder<bool>(
      future: _assetExists(),
      builder: (context, snapshot) {
        final hasLottie = snapshot.data == true;
        late final Widget indicator;
        if (hasLottie) {
          indicator = LottieBuilder.asset(
            assetPath,
            width: width ?? 45,
            height: height ?? 45,
            animate: play,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color([
                  'Layer 5 Outlines',
                  'Group 1',
                  '**',
                ], value: primary),
                ValueDelegate.color([
                  'cube 4 Outlines',
                  'Group 1',
                  '**',
                ], value: primary),
                ValueDelegate.color([
                  'cube 2 Outlines',
                  'Group 1',
                  '**',
                ], value: secondary),
                ValueDelegate.color([
                  'cube 3 Outlines',
                  'Group 1',
                  '**',
                ], value: secondary),
              ],
            ),
          );
        } else {
          indicator = LoadingDots(
            width: width,
            height: height,
            colorPrimary: primary,
            colorSecondary: secondary,
            play: play,
          );
        }

        if (!dimBackground) return indicator;

        return Stack(
          children: [
            Positioned.fill(child: Container(color: const Color(0x66000000))),
            Center(child: indicator),
          ],
        );
      },
    );
  }
}
