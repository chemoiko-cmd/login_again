import 'package:flutter/material.dart';
import 'package:login_again/theme/app_gradients.dart';

class GradientFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Object? heroTag;
  final String? tooltip;

  const GradientFloatingActionButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.heroTag,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      elevation: 6,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primaryGradient,
          ),
          child: Center(
            child: IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ),
    );

    final msg = tooltip;
    if (msg == null || msg.isEmpty) return button;
    return Tooltip(message: msg, child: button);
  }
}
