import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

class NumericPad extends StatelessWidget {
  final Function(String) onInput;
  final VoidCallback onDelete;
  final VoidCallback onSubmit;

  const NumericPad({
    super.key,
    required this.onInput,
    required this.onDelete,
    required this.onSubmit,
  });

  void _handlePress(String value) {
    HapticFeedback.lightImpact();
    SoundService().playClick();
    onInput(value);
  }

  void _handleDelete() {
    HapticFeedback.mediumImpact();
    SoundService().playClick();
    onDelete();
  }

  void _handleSubmit() {
    HapticFeedback.heavyImpact();
    SoundService().playClick();
    onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton('1'),
              _buildButton('2'),
              _buildButton('3'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton('4'),
              _buildButton('5'),
              _buildButton('6'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildButton('7'),
              _buildButton('8'),
              _buildButton('9'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.backspace_outlined, _handleDelete, color: AppTheme.error),
              _buildButton('0'),
              _buildActionButton(Icons.check, _handleSubmit, color: AppTheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text) {
    return _PadButton(
      child: Text(text, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      onPressed: () => _handlePress(text),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed, {Color? color}) {
    return _PadButton(
      borderColor: color,
      onPressed: onPressed,
      child: Icon(icon, size: 28, color: color),
    );
  }
}

class _PadButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color? borderColor;

  const _PadButton({required this.child, required this.onPressed, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: borderColor ?? AppTheme.text.withOpacity(0.5), width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Center(child: child),
        ),
      ),
    );
  }
}
