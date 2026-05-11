import 'dart:async';
import 'dart:math';

abstract class MultiplayerService {
  Future<void> signIn(); // Simple auth
  Future<String> findMatch(String difficulty, String playerName, [int maxPlayers = 2]);
  Stream<MatchState> streamMatch(String matchId);
  Future<void> updateScore(String matchId, int score);
  String? get currentUserId;
}

class MatchState {
  final String status; // 'waiting', 'playing', 'finished'
  final List<PlayerState> players;
  final Map<String, dynamic>? gameParams;
  final int maxPlayers;
  final String? winnerId;

  MatchState({
    required this.status,
    required this.players,
    this.gameParams,
    this.winnerId,
    this.maxPlayers = 2,
  });
}

class PlayerState {
  final String uid;
  final String name;
  final int score;

  PlayerState({required this.uid, required this.name, required this.score});
}

class MockMultiplayerService implements MultiplayerService {
  final String _userId = "user_${Random().nextInt(1000)}";
  
  // Local state to simulate a match
  final _scoreController = StreamController<MatchState>.broadcast();
  int _myScore = 0;
  int _opponentScore = 0;
  Timer? _opponentTimer;
  String? _currentMatchId;

  @override
  String? get currentUserId => _userId;

  @override
  Future<void> signIn() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<String> findMatch(String difficulty, String playerName, [int maxPlayers = 2]) async {
    // Simulate searching
    await Future.delayed(const Duration(seconds: 2));
    _currentMatchId = "match_${Random().nextInt(1000)}";
    
    // Reset state
    _myScore = 0;
    _opponentScore = 0;
    
    // Start simulating opponent
    _startOpponentSimulation();
    
    return _currentMatchId!;
  }

  void _startOpponentSimulation() {
    _opponentTimer?.cancel();
    // Opponent scores every 2-4 seconds
    _opponentTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (Random().nextBool()) {
        _opponentScore += 10;
         _emitState();
      }
      
      if (_opponentScore >= 500) {
        timer.cancel();
      }
    });
    // Initial emit
    _emitState();
  }

  void _emitState() {
     _scoreController.add(MatchState(
       status: 'playing',
       players: [
         PlayerState(uid: _userId, name: "Me", score: _myScore),
         PlayerState(uid: "bot", name: "Trainer Bot", score: _opponentScore),
       ],
     ));
  }

  @override
  Stream<MatchState> streamMatch(String matchId) {
    return _scoreController.stream;
  }

  @override
  Future<void> updateScore(String matchId, int score) async {
    _myScore = score;
    _emitState();
  }
}
