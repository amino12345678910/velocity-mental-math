import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/social_service.dart';
import '../services/sound_service.dart';

enum GameStatus { idle, playing, input, roundOver }

class GameProvider with ChangeNotifier {
  GameStatus _status = GameStatus.idle;
  List<int> _sequence = [];
  int _currentNumberIndex = 0;
  int? _currentNumber;
  int _highScore = 0;
  
  // Game Configuration (passed from settings when starting)
  int _digits = 1;
  int _speedMs = 1000;
  int _sequenceLength = 5;
  
  GameStatus get status => _status;
  int? get currentNumber => _currentNumber;
  int get highScore => _highScore;

  GameProvider() {
    _loadHighScore();
  }

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt('high_score') ?? 0;
    notifyListeners();
  }

  Future<void> _updateHighScore(int score) async {
    if (score > _highScore) {
      _highScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('high_score', _highScore);
      notifyListeners();
    }
  }

  void startGame(int sequenceLength, int digits, int speedMs) {
    _digits = digits;
    _speedMs = speedMs;
    _sequenceLength = sequenceLength;
    _status = GameStatus.playing;
    _generateSequence(sequenceLength, digits);
    _currentNumberIndex = 0;
    notifyListeners();
    _playSequence();
  }

  void _generateSequence(int length, int digits) {
    final random = Random();
    int max;
    if (digits == 1) max = 10;
    else if (digits == 2) max = 100;
    else max = 1000;

    _sequence = List.generate(length, (_) => random.nextInt(max));
  }

  Future<void> _playSequence() async {
    // This method is called by the UI to advance, or handled via a timer in UI 
    // For MVVM, we'll expose the stream or let the UI drive the animation timing via a callback/controller
    // But to keep logic here, let's provide a method to get next number
  }

  // Actually, UI `flutter_animate` needs the list or a stream.
  // Let's expose the full sequence and let the UI iterate through it with animations.
  List<int> get sequence => _sequence;

  void completeSequence() {
    _status = GameStatus.input;
    notifyListeners();
  }

  bool verifySum(int userSum) {
    int actualSum = _sequence.reduce((a, b) => a + b);
    bool isCorrect = actualSum == userSum;
     
    // Calculate Score & Record Result
    int points = 0;
    String difficulty = SocialService.calculateDifficulty(_digits, _speedMs, _sequenceLength);

    if (isCorrect) {
      SoundService().playCorrect();
      // Calculate points based on difficulty constants from SocialService?
      // Or simply let SocialService handle point allocation based on the recorded difficulty.
      // We explicitly record the result now.
      SocialService().recordMatchResult(isWin: true, difficulty: difficulty);

      // Local High Score Logic (Legacy/Simpler)
      // We can also let the UI show the synced points, but for now perform local calc for immediate feedback if needed.
      // But mainly we rely on SocialService for the permanent record.

      // Keep legacy high score simply as a "max sum achieved" or similar? 
      // The original code was: int scoreForRound = _sequence.length * _digits * 10;
      // Let's stick to that for local display if meaningful, or just track Leaderboard points.
      // For simplicity, let's just save the "score" as the sum of correct answers?
      // Actually, let's align with the new Point system.
      // If we want to show 'High Score' on Home, we should probably fetch it from Firestore (total points).
      // But for backward compat with the provider's `_highScore`, let's update it if valid.
       
      int roundPoints = 0;
      switch(difficulty) {
        case 'Easy': roundPoints = 10; break;
        case 'Medium': roundPoints = 25; break;
        case 'Hard': roundPoints = 50; break;
        case 'Extreme': roundPoints = 100; break;
      }
      
      // Accumulate score? The current provider looks like "Single Game High Score". 
      // If we want "Total Score", that's different.
      // Let's treat _highScore as "Session Score" or "Best Single Game Score".
      // Let's just update it if this round was massive? No, the game is one round.
      // So verifySum ends the "Game".
      if (roundPoints > _highScore) {
         _updateHighScore(roundPoints);
         SoundService().playWin(); // High score beat or good performance
      }
    } else {
      SoundService().playWrong();
      SocialService().recordMatchResult(isWin: false, difficulty: difficulty);
      SoundService().playLose(); // Game over/wrong
    }
    
    _status = GameStatus.roundOver;
    notifyListeners();
    return isCorrect;
  }
  
  void resetGame() {
    _status = GameStatus.idle;
    _sequence = [];
    notifyListeners();
  }
}
