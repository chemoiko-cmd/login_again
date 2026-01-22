import 'dart:math' as math;
import 'package:flutter/material.dart';

class LoadingDots extends StatefulWidget {
  final double? width;
  final double? height;
  final Color? colorPrimary;
  final Color? colorSecondary;
  final Duration period;
  final bool play;

  const LoadingDots({
    super.key,
    this.width,
    this.height,
    this.colorPrimary,
    this.colorSecondary,
    this.period = const Duration(milliseconds: 1000),
    this.play = true,
  });

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    if (widget.play) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LoadingDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play != oldWidget.play) {
      if (widget.play) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary =
        widget.colorPrimary ?? Theme.of(context).colorScheme.primary;
    final secondary =
        widget.colorSecondary ?? Theme.of(context).colorScheme.secondary;
    final dots = [primary, secondary, primary];

    final width = widget.width ?? 60;
    final height = widget.height ?? 24;
    final dotSize = math.max(6.0, math.min(12.0, height - 8));

    return Stack(
      children: [
        // Fullscreen dimmed background
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.4), // background dim
          ),
        ),

        // Centered loading dots
        Center(
          child: SizedBox(
            width: width,
            height: height,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(3, (i) {
                      final phase = i * (2 * math.pi / 3);
                      final t = _controller.value * 2 * math.pi;

                      final scale = 0.7 + 0.3 * math.sin(t + phase);
                      final opacity = 0.6 + 0.4 * math.sin(t + phase);

                      return Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: scale.clamp(0.7, 1.0),
                          child: Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              color: dots[i],
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
