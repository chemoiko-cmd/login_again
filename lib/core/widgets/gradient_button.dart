import 'package:flutter/material.dart';
import 'package:login_again/theme/app_gradients.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double minHeight;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.minHeight = 48,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled ? AppGradients.primaryGradient : null,
            color: enabled ? null : Colors.black.withOpacity(0.12),
            borderRadius: borderRadius,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: padding,
              child: Center(
                child: IconTheme.merge(
                  data: const IconThemeData(color: Colors.white),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double minHeight;
  final double borderWidth;

  const GradientOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.minHeight = 48,
    this.borderWidth = 1.6,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Padding(
            padding: EdgeInsets.all(borderWidth),
            child: Ink(
              decoration: BoxDecoration(
                gradient: enabled ? AppGradients.primaryGradient : null,
                color: enabled ? null : Colors.black.withOpacity(0.12),
                borderRadius: borderRadius,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: borderRadius,
                ),
                child: Padding(
                  padding: padding,
                  child: Center(
                    child: enabled
                        ? ShaderMask(
                            shaderCallback: (rect) =>
                                AppGradients.primaryGradient.createShader(
                                  Rect.fromLTWH(0, 0, rect.width, rect.height),
                                ),
                            child: DefaultTextStyle.merge(
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              child: IconTheme.merge(
                                data: const IconThemeData(color: Colors.white),
                                child: child,
                              ),
                            ),
                          )
                        : DefaultTextStyle.merge(
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                            child: IconTheme.merge(
                              data: IconThemeData(color: Colors.grey.shade600),
                              child: child,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return button;
  }
}

class GradientTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  const GradientTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return InkWell(
      onTap: onPressed,
      borderRadius: borderRadius,
      child: Padding(
        padding: padding,
        child: enabled
            ? ShaderMask(
                shaderCallback: (rect) => AppGradients.primaryGradient
                    .createShader(Rect.fromLTWH(0, 0, rect.width, rect.height)),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: Colors.white),
                    child: child,
                  ),
                ),
              )
            : DefaultTextStyle.merge(
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
                child: IconTheme.merge(
                  data: IconThemeData(color: Colors.grey.shade600),
                  child: child,
                ),
              ),
      ),
    );
  }
}
