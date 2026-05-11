import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../services/multiplayer_service.dart';
import '../../services/social_service.dart';
import '../../theme/app_theme.dart';
import 'duel_screen.dart';
import '../../services/sound_service.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}


class _LobbyScreenState extends State<LobbyScreen> {
  bool _isSearching = false;
  String _difficulty = 'Medium';
  int _maxPlayers = 2; // Default to duel
  String? _statusMessage;
  late TextEditingController _nameController;

  String _rank = "Loading...";
  
  @override
  void initState() {
    super.initState();
    final username = context.read<AuthProvider>().username ?? "Player";
    _nameController = TextEditingController(text: username);
    _loadRank();
  }

  void _loadRank() async {
    final uid = context.read<MultiplayerService>().currentUserId;
    if (uid != null) {
      // Use SocialService from context or instance? It's a singleton usually or passed.
      // The file imports it.
      final profile = await SocialService().getUserProfile(uid);
      if (profile != null) {
         final points = profile['totalPoints'] ?? 0; // Check field name in SocialService recordMatchResult
         // Actually recordMatchResult updates 'totalPoints'.
         setState(() {
           _rank = SocialService().getRank(points);
         });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _findMatch() async {
    SoundService().playClick();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _statusMessage = "Please enter a nickname");
      return;
    }

    setState(() {
      _isSearching = true;
      _statusMessage = "Authenticating...";
    });

    try {
      final service = context.read<MultiplayerService>();
      
      setState(() => _statusMessage = "Authenticating...");
      await service.signIn().timeout(const Duration(seconds: 10));

      // Sync name with Social Profile so friends see this name
      try {
        setState(() => _statusMessage = "Syncing profile...");
        await SocialService().updateUsername(name).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint("Failed to sync username: $e");
      }

      setState(() {
        _statusMessage = "Searching for $_difficulty opponent (${_maxPlayers}p)...";
      });

      // Pass _maxPlayers to findMatch
      final matchId = await service.findMatch(_difficulty, name, _maxPlayers).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException("Matchmaking timed out. Please check your connection."),
      );

      if (!mounted) return;

      SoundService().playMatchFound();
      setState(() {
        _statusMessage = "Match found! Starting...";
      });

      // Navigate to Duel Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DuelScreen(matchId: matchId)),
      );

    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = "Connection failed";
      if (e is TimeoutException) {
        errorMessage = "Request timed out. Please check your internet.";
      } else if (e.toString().contains("User not signed in")) {
        errorMessage = "Authentication failed";
      }

      setState(() {
        _isSearching = false;
        _statusMessage = errorMessage;
      });
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Connection Failed", style: TextStyle(color: AppTheme.error)),
          content: Text(e.toString().replaceAll("Exception: ", "")),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONLINE LOBBY v2.2'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSearching) ...[
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 32),
                Text(
                  _statusMessage ?? "",
                  style: const TextStyle(color: AppTheme.text, fontSize: 18),
                ).animate().fade().slideY(begin: 1.0, end: 0.0),
                const SizedBox(height: 32),
                OutlinedButton(
                   onPressed: () {
                     setState(() {
                       _isSearching = false;
                       _statusMessage = null;
                     });
                   },
                   style: OutlinedButton.styleFrom(
                     foregroundColor: AppTheme.error,
                     side: const BorderSide(color: AppTheme.error),
                   ),
                   child: const Text("CANCEL"),
                )
              ] else ...[
                const Icon(Icons.group, size: 80, color: AppTheme.primary)
                    .animate()
                    .scale(duration: 1.seconds, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accent),
                  ),
                  child: Text(
                    "RANK: $_rank",
                    style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MULTIPLAYER LOBBY',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Race to 500 points!',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                
                // Name Input
                 Container(
                  width: 300,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppTheme.text),
                    decoration: const InputDecoration(
                      labelText: "Your Nickname",
                      labelStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      icon: Icon(Icons.person, color: AppTheme.primary),
                    ),
                  ),
                ),

                // Difficulty Selector
                Container(
                  width: 300,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _difficulty,
                      dropdownColor: AppTheme.background,
                      style: const TextStyle(color: AppTheme.text, fontSize: 18),
                      icon: const Icon(Icons.speed, color: AppTheme.primary),
                      onChanged: (String? newValue) {
                        setState(() {
                          _difficulty = newValue!;
                        });
                      },
                      items: <String>['Easy', 'Medium', 'Hard', 'Extreme']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Player Count Selector
                Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _maxPlayers,
                      dropdownColor: AppTheme.background,
                      style: const TextStyle(color: AppTheme.text, fontSize: 18),
                      icon: const Icon(Icons.people, color: AppTheme.accent),
                      onChanged: (int? newValue) {
                        setState(() {
                          _maxPlayers = newValue!;
                        });
                      },
                      items: <int>[2, 3, 4]
                          .map<DropdownMenuItem<int>>((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text("$value Players"),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: 250,
                  child: ElevatedButton(
                    onPressed: _findMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('FIND MATCH'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
