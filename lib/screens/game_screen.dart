import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/numeric_pad.dart';
import '../widgets/animated_background.dart';
import '../widgets/glass_container.dart';
import '../widgets/neon_button.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  String _input = "";
  int _currentIndex = -1; // -1 means starting delay
  bool _showingResult = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGame();
    });
  }

  void _startGame() {
    final settings = context.read<SettingsProvider>();
    context.read<GameProvider>().startGame(settings.sequenceLength, settings.digits, settings.speedMs);
    
    // Start sequence loop
    _playSequence(settings.speedMs);
  }

  Future<void> _playSequence(int speedMs) async {
    final provider = context.read<GameProvider>();
    final sequence = provider.sequence;

    // Small initial delay
    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i < sequence.length; i++) {
      if (!mounted) return;
      setState(() {
        _currentIndex = i;
      });
      
      // Show number for speedMs active time
      // We can split speedMs into "On" and "Off" time if needed, or just blast them.
      // flashing usually implies a small gap.
      await Future.delayed(Duration(milliseconds: (speedMs * 0.8).round()));
      
      if (!mounted) return;
      setState(() {
        _currentIndex = -2; // Hide
      });
      
      await Future.delayed(Duration(milliseconds: (speedMs * 0.2).round()));
    }

    if (!mounted) return;
    provider.completeSequence();
  }

  void _handleInput(String value) {
    if (_input.length < 10) {
      setState(() {
        _input += value;
      });
    }
  }

  void _handleDelete() {
    if (_input.isNotEmpty) {
      setState(() {
        _input = _input.substring(0, _input.length - 1);
      });
    }
  }

  void _handleSubmit() {
    if (_input.isEmpty) return;
    final sum = int.tryParse(_input);
    if (sum != null) {
      final correct = context.read<GameProvider>().verifySum(sum);
      setState(() {
        _showingResult = true;
        _isCorrect = correct;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameStatus = context.select((GameProvider p) => p.status);
    final sequence = context.select((GameProvider p) => p.sequence);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        backgroundColor: Colors.transparent,
      ),
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: _buildDisplay(gameStatus, sequence),
                ),
              ),
              if (gameStatus == GameStatus.input && !_showingResult)
                GlassContainer(
                  margin: const EdgeInsets.all(0),
                  borderRadius: 24,
                  // Remove default decoration since GlassContainer handles it
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _input.isEmpty ? 'Enter Sum' : _input,
                          style: TextStyle(
                            fontSize: 32,
                            color: _input.isEmpty ? Colors.white54 : AppTheme.text,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      NumericPad(
                        onInput: _handleInput,
                        onDelete: _handleDelete,
                        onSubmit: _handleSubmit,
                      ),
                    ],
                  ),
                ),
              if (_showingResult)
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isCorrect ? 'CORRECT!' : 'WRONG',
                        style: TextStyle(
                          fontSize: 40,
                          color: _isCorrect ? AppTheme.success : AppTheme.error,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: _isCorrect ? AppTheme.success : AppTheme.error, blurRadius: 20),
                          ],
                        ),
                      ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
                      const SizedBox(height: 16),
                      if (!_isCorrect)
                        Text(
                          'Sum was: ${sequence.fold(0, (a, b) => a + b)}',
                          style: const TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      const SizedBox(height: 32),
                      NeonButton(
                        text: 'CONTINUE',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisplay(GameStatus status, List<int> sequence) {
    if (status == GameStatus.playing) {
      if (_currentIndex >= 0 && _currentIndex < sequence.length) {
        return Text(
          '${sequence[_currentIndex]}',
          key: ValueKey(_currentIndex),
          style: const TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ).animate().scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 200.ms,
              curve: Curves.easeOutBack,
            ).fadeIn(duration: 100.ms);
      } else {
        return const SizedBox();
      }
    } else if (status == GameStatus.input || status == GameStatus.roundOver) {
      if (_showingResult) return const SizedBox(); // Result shown below
      return const Text(
        '?',
        style: TextStyle(fontSize: 96, color: AppTheme.accent),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds)
          .fade(begin: 0.5, end: 1.0);
    }
    return const SizedBox();
  }
}
