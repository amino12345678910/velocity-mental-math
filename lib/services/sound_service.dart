import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _player = AudioPlayer();
  
  // Settings
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
    if (_isMuted) {
      _player.stop();
    }
  }

  Future<void> _playSound(String fileName) async {
    if (_isMuted) return;
    try {
      // For web, sometimes 'assets/' prefix is needed depending on setup,
      // but Audioplayers usually handles 'Source.asset' relative to assets.
      // We will assume files are in 'assets/sounds/'
      await _player.play(AssetSource('sounds/$fileName'), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint("Error playing sound $fileName: $e");
    }
  }

  Future<void> playClick() async => _playSound('click.wav');
  Future<void> playCorrect() async => _playSound('correct.wav');
  Future<void> playWrong() async => _playSound('wrong.wav');
  Future<void> playWin() async => _playSound('win.wav');
  Future<void> playLose() async => _playSound('lose.wav');
  Future<void> playMatchFound() async => _playSound('match_found.wav');
  Future<void> playStart() async => _playSound('start.wav');
  Future<void> playSwitch() async => _playSound('switch.wav');
}
