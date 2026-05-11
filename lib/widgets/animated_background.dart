import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AnimatedBackground extends StatelessWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Deep Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF020205), // Deepest Black
                Color(0xFF0A0A15), // Deep Navy
                Color(0xFF100020), // Deep Purple Haze
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Glowing Orbs / Spots
        Positioned(
          top: -100,
          left: -100,
          child: _buildOrb(AppTheme.primary),
        ),
        Positioned(
          bottom: -100,
          right: -100,
          child: _buildOrb(AppTheme.secondary),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: -50,
          child: _buildOrb(AppTheme.accent).animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: 50, duration: 4.seconds, curve: Curves.easeInOut),
        ),

        // Subtle Grid Overlay
        Positioned.fill(
          child: CustomPaint(
            painter: GridPainter(),
          ).animate().fadeIn(duration: 1.seconds),
        ),

        // Content
        SafeArea(child: child),
      ],
    );
  }

  Widget _buildOrb(Color color) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.0),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 3.seconds);
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    const spacing = 40.0;

    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
