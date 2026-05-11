import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/multiplayer_service.dart';
import '../../services/firebase_service.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/numeric_pad.dart';

class DuelScreen extends StatefulWidget {
  final String matchId;
  const DuelScreen({super.key, required this.matchId});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  // Game State
  List<int> _sequence = [];
  int _currentDisplayValue = -1; // -1: hidden
  bool _isInputting = false;
  String _currentInput = "";
  
  // Settings (Defaults, overwritten by Match Params)
  int _speedMs = 800;
  int _sequenceLength = 3;
  int _digits = 1;

  @override
  void initState() {
    super.initState();
    // Start logic moved to _startGameSequence triggered when connected
  }

  void _startNewRound() async {
    if (!mounted) return;
    setState(() {
      _isInputting = false;
      _currentInput = "";
      _currentDisplayValue = -1;
      // Generate random sequence
      int min = pow(10, _digits - 1).toInt();
      int max = pow(10, _digits).toInt() - 1;
      _sequence = List.generate(_sequenceLength, (_) => Random().nextInt(max - min + 1) + min); 
    });

    // Play Sequence
    await Future.delayed(const Duration(milliseconds: 500));
    for (int num in _sequence) {
      if (!mounted) return;
      setState(() => _currentDisplayValue = num);
      await Future.delayed(Duration(milliseconds: (_speedMs * 0.8).round()));
      
      if (!mounted) return;
      setState(() => _currentDisplayValue = -1);
      await Future.delayed(Duration(milliseconds: (_speedMs * 0.2).round()));
    }

    if (!mounted) return;
    setState(() {
      _isInputting = true;
    });
  }

  void _handleDigit(String value) {
    if (!_isInputting) return;
    if (_currentInput.length < 5) {
      setState(() {
        _currentInput += value;
      });
    }
  }

  void _handleDelete() {
    if (!_isInputting) return;
    if (_currentInput.isNotEmpty) {
      setState(() {
        _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      });
    }
  }

  void _handleSubmit() {
    if (!_isInputting) return;
    _verifySum();
  }

  void _verifySum() {
    final int? userSum = int.tryParse(_currentInput);
    if (userSum == null) return;

    final int actualSum = _sequence.fold(0, (sum, item) => sum + item);
    final service = context.read<MultiplayerService>();
    
    // We need current score to add to it. 
    // Ideally service handles atomic increment, but for MVP/Mock we read stream.
    // However, StreamBuilder is below, we don't have direct access to 'state'.
    // We can track 'myLocalScore' or fetch from service.
    // For MockService, updateScore sets the absolute value.
    // Let's assume we track it via the stream logic. 
    // *Hack*: We'll assume the internal state of the widget builds from stream, so we rely on optimistic update 
    // or just fetch most recent known score if possible. 
    // Better: MockService.updateScore(..., score). 
    
    // To solve this properly without refactoring Service:
    // We passed the score to the UI. We need it here.
    // Let's rely on a variable we update when stream updates? No, SetState race.
    // Let's just track `_cumulativeScore` locally for the update call, assuming sync.
    // Actually, `MockMultiplayerService` is simple.
    
    // Let's read the current stream value? Not easy synchronously.
    // We'll keep a local `_myScore` updated by the stream build for reference.
    
    if (userSum == actualSum) {
       // Correct!
       HapticFeedback.mediumImpact();
       // +100 points
       final newScore = _lastKnownMyScore + 100;
       service.updateScore(widget.matchId, newScore);
       
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Correct! +100"), duration: Duration(milliseconds: 500), backgroundColor: Colors.green),
       );
    } else {
       // Wrong
       HapticFeedback.heavyImpact();
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Wrong!"), duration: Duration(milliseconds: 500), backgroundColor: Colors.red),
       );
    }

    // Always next round
    _startNewRound();
  }

  int _lastKnownMyScore = 0;

  bool _showIntro = true;
  bool _gameStarted = false;
  bool _inviteSent = false;

  @override
  Widget build(BuildContext context) {
    final service = context.read<MultiplayerService>();
    final myUid = service.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DUEL MODE'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, 
      ),
      body: StreamBuilder<MatchState>(
        stream: service.streamMatch(widget.matchId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final state = snapshot.data!;
          
          // Find my state
          final myState = state.players.firstWhere((p) => p.uid == myUid, 
             orElse: () => PlayerState(uid: "", name: "Me", score: 0));
          _lastKnownMyScore = myState.score;

          // 1. WAITING FOR OPPONENT
          if (state.status == 'waiting') {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const CircularProgressIndicator(color: AppTheme.primary),
                   const SizedBox(height: 32),
                   Text("Waiting for Players... (${state.players.length}/${state.maxPlayers})", style: const TextStyle(color: AppTheme.text, fontSize: 20)),
                   const SizedBox(height: 16),
                   // List Players
                   ...state.players.map((p) => Text(p.name, style: const TextStyle(color: Colors.grey))),
                   const SizedBox(height: 32),
                   Text("Difficulty: ${_getDifficultyLabel(_digits, _speedMs)}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                   const SizedBox(height: 8),
                   Text("LOBBY: ${widget.matchId.substring(0, 4)}", style: const TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.bold)),
                   
                   if (state.players.length > 1) ...[ // Allow start if >1 player
                     const SizedBox(height: 32),
                     ElevatedButton(
                       onPressed: () async {
                         // Only host should ideally start, but for MVP anyone can trigger
                         // Need a method in service to force start
                         // Cast to FirebaseService or add to interface
                         // For now, let's assume specific implementation know-how or add to interface
                         // We'll cast carefully
                         if (service is FirebaseService) {
                           await service.startGame(widget.matchId);
                         }
                       },
                       style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                       child: const Text("START GAME NOW"),
                     )
                   ]
                 ],
               ),
             );
          }

          // 2. INTRO (Once connected)
          if (_showIntro && !_gameStarted) {
            if (state.gameParams != null) {
              _digits = state.gameParams!['digits'];
              _speedMs = state.gameParams!['speed'];
              _sequenceLength = state.gameParams!['length'];
              _startGameSequence();
            }
            
            return Center(
              child: const Text("FIRST TO 500 WINS!", 
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.primary, fontSize: 48, fontWeight: FontWeight.bold)
              ).animate().fade(duration: 500.ms).scale(delay: 500.ms),
            );
          }

          // 3. GAME OVER
          if (state.status == 'finished' || state.winnerId != null) {
             final bool iWon = state.winnerId == myUid;
             
             // Trigger Result Recording ONCE
             _recordResultOnce(iWon, state);

             return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(iWon ? Icons.emoji_events : Icons.thumb_down, 
                         size: 80, 
                         color: iWon ? Colors.yellow : Colors.red),
                    const SizedBox(height: 24),
                    Text(iWon ? "YOU WON!" : "GAME OVER", 
                         style: TextStyle(color: iWon ? Colors.yellow : Colors.red, fontSize: 48, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text("Winner: ${state.players.firstWhere((p) => p.uid == state.winnerId).name}", 
                      style: const TextStyle(color: Colors.white, fontSize: 20)),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("BACK TO LOBBY"),
                    ),
                  ],
                ),
             );
          }

          // 4. PLAYING - Multi-User Scoreboard
          return Column(
            children: [
              // Scoreboard (Row for 2 players, cleaner VS style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Player 1 (Me)
                    Expanded(
                      child: _buildScoreCard(
                        "YOU", 
                        _lastKnownMyScore, 
                        AppTheme.primary,
                        Alignment.centerLeft
                      ),
                    ),
                    
                    // VS Divider
                    Column(
                      children: [
                        const Text("VS", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(width: 1, height: 20, color: Colors.grey.withOpacity(0.5)),
                      ],
                    ),

                    // Player 2 (Opponent)
                    // Simplified for 1v1. If >2, we might need a different view, but Duel implies 2.
                    Expanded(
                      child: _buildScoreCard(
                        state.players.firstWhere((p) => p.uid != myUid, orElse: () => PlayerState(uid: "", name: "Waiting...", score: 0)).name,
                        state.players.firstWhere((p) => p.uid != myUid, orElse: () => PlayerState(uid: "", name: "Waiting...", score: 0)).score,
                        AppTheme.accent,
                        Alignment.centerRight
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Game Area
              if (_isInputting) 
                Column(
                  children: [
                     Text(
                      _currentInput.isEmpty ? "?" : _currentInput,
                      style: const TextStyle(fontSize: 64, color: AppTheme.text, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text("ENTER SUM", style: TextStyle(color: Colors.grey)),
                  ],
                )
              else if (_currentDisplayValue != -1)
                Text(
                  "$_currentDisplayValue",
                  style: const TextStyle(fontSize: 80, color: AppTheme.primary, fontWeight: FontWeight.bold),
                ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack)
              else 
                const Text("WATCH...", style: TextStyle(fontSize: 24, color: Colors.grey))
                    .animate(onPlay: (c) => c.repeat())
                    .fade(duration: 500.ms),

              const Spacer(),

              // Keypad
              AbsorbPointer(
                absorbing: !_isInputting,
                child: Opacity(
                  opacity: _isInputting ? 1.0 : 0.5,
                  child: NumericPad(
                    onInput: _handleDigit,
                    onDelete: _handleDelete,
                    onSubmit: _handleSubmit,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  bool _resultRecorded = false;
  void _recordResultOnce(bool iWon, MatchState state) {
    if (_resultRecorded) return;
    _resultRecorded = true;

    String difficulty = 'Medium';
    if (state.gameParams != null) {
      final d = state.gameParams!['digits'];
      final s = state.gameParams!['speed'];
      difficulty = _getDifficultyLabel(d, s);
    }
    
    // Fire and forget
    SocialService().recordMatchResult(isWin: iWon, difficulty: difficulty);
  }

  void _startGameSequence() async {
     if (_gameStarted) return;
     _gameStarted = true;
     
     // Consume Ticket
     final success = await SocialService().consumeTicket();
     if (!success) {
       if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: No Tickets!"), backgroundColor: Colors.red));
          Navigator.pop(context); // Kick out
       }
       return;
     }

     // Show intro for 2 seconds
     await Future.delayed(const Duration(seconds: 3));
     if (!mounted) return;
     setState(() {
       _showIntro = false;
     });
     
     _startNewRound();
  }

  String _getDifficultyLabel(int digits, int speed) {
    // Length isn't critical for the label if we want a quick summary, 
    // but better to align exactly. 
    // However, the helper might need instance access or we just pass a default.
    // Let's rely on the passed params.
    // Length is implicitly 3 or passed via state.
    // Let's just use the static method with current state or input.
    // But the signature is (digits, speed).
    // Let's assume length 5 or similar for the display label or pass 0 if unused for label logic (though logic uses it?)
    // Actually logic doesn't use length in my current implementation of SocialService.calculateDifficulty.
    // Wait, I defined: calculateDifficulty(int digits, int speedMs, int length)
    // But I didn't use length in the implementation I wrote.
    return SocialService.calculateDifficulty(digits, speed, 3);
  }

  Widget _buildScoreCard(String label, int score, Color color, Alignment alignment) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignment == Alignment.centerLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(label.length > 10 ? "${label.substring(0, 8)}.." : label, 
             style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          "$score",
          style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
