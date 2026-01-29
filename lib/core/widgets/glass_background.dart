import 'package:flutter/material.dart';

class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // =========================
        // Gradient Base Layer
        // =========================
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF6F6F8),
                  Color(0xFFF1F2F5),
                  Color(0xFFF7EFF3),
                  Color(0xFFF3F4F7),
                ],
              ),
            ),
          ),
        ),

        // =========================
        // Floating Radial Circles
        // =========================
        Positioned(
          top: -120,
          left: -100,
          child: _buildCircle(340, Color(0x66FFFFFF), 0.45),
        ),
        Positioned(
          bottom: -140,
          right: -120,
          child: _buildCircle(420, Color(0x66FFD6E5), 0.34),
        ),
        Positioned(
          top: 100,
          right: -100,
          child: _buildCircle(300, Color(0x66FFFFFF), 0.18),
        ),
        Positioned(
          bottom: 80,
          left: -100,
          child: _buildCircle(260, Color(0x66FFB7D1), 0.16),
        ),

        // =========================
        // Subtle Noise Overlay
        // =========================
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(painter: _NoisePainter()),
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

  Widget _buildCircle(double size, Color color, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withAlpha(0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    const step = 6.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        final v = ((x * 13 + y * 7) % 17) / 17.0;
        paint.color = Colors.white.withValues(alpha: v * 0.08);
        canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
