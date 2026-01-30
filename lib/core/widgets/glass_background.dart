import 'package:flutter/material.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  static const Color _primary = Color(0xFF4C66EE);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // =========================
        // Base Neutral Gradient
        // =========================
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF6F7FD),
                  const Color(0xFFF2F4FB),
                  const Color(0xFFF4F2FA),
                  const Color(0xFFF3F5FD),
                ],
              ),
            ),
          ),
        ),

        // =========================
        // Primary Color Wash (VERY subtle)
        // =========================
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primary.withValues(alpha: 0.08),
                  _primary.withValues(alpha: 0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),

        // =========================
        // Secondary Depth Gradient
        // =========================
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [_primary.withValues(alpha: 0.04), Colors.transparent],
              ),
            ),
          ),
        ),

        // =========================
        // Subtle Noise Overlay
        // =========================
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.035,
              child: CustomPaint(painter: _NoisePainter(primary: _primary)),
            ),
          ),
        ),

        // =========================
        // Child Content
        // =========================
        child,
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  final Color primary;

  const _NoisePainter({required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    const step = 6.0;

    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final v = ((x * 13 + y * 7) % 17) / 17.0;

        paint.color = primary.withValues(
          alpha: v * 0.03, // extremely subtle
        );

        canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
