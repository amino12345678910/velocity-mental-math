import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class NeonButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final bool isPrimary;
  final double width;

  const NeonButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color,
    this.isPrimary = true,
    this.width = double.infinity,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? (widget.isPrimary ? AppTheme.primary : AppTheme.accent);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        SoundService().playClick();
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: 100.ms,
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: widget.isPrimary 
              ? baseColor.withOpacity(_isPressed ? 0.3 : 0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: baseColor.withOpacity(_isPressed ? 1.0 : 0.7),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(_isPressed ? 0.6 : 0.2),
              blurRadius: _isPressed ? 20 : 10,
              spreadRadius: _isPressed ? 2 : 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            widget.text.toUpperCase(),
            style: TextStyle(
              color: widget.isPrimary ? Colors.white : baseColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: baseColor,
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
