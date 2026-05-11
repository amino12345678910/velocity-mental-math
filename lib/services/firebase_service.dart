import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'multiplayer_service.dart';

class FirebaseService implements MultiplayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Future<void> signIn() async {
    // Check if configuration is valid
    if (Firebase.app().options.apiKey.contains('REPLACE')) {
       throw Exception("Firebase Keys Missing! Please update firebase_options.dart");
    }

    if (_auth.currentUser == null) {
      debugPrint("DEBUG: User not signed in. Attempting Anonymously...");
      try {
        await _auth.signInAnonymously();
        debugPrint("DEBUG: Signed in Anonymously. UID: ${_auth.currentUser?.uid}");
      } catch (e) {
        debugPrint("Auth Error: $e");
        rethrow; // Pass error to UI
      }
    } else {
       debugPrint("DEBUG: User already signed in. UID: ${_auth.currentUser?.uid}");
    }
  }

  @override
  Future<String> findMatch(String difficulty, String playerName, [int maxPlayers = 2]) async {
    final user = currentUserId;
    if (user == null) throw Exception("User not signed in");

    // 1. Try to find a WAITING match with < maxPlayers
    debugPrint("DEBUG: Searching for existing matches (Difficulty: $difficulty, Max: $maxPlayers)...");
    QuerySnapshot? snapshot;
    try {
      // ABSOLUTE MINIMUM QUERY: Just get recent matches and filter in memory.
      // This avoids ALL index requirements.
      snapshot = await _firestore
          .collection('matches')
          .limit(50) 
          .get();
      
      debugPrint("DEBUG: Query complete. Found ${snapshot.docs.length} raw matches.");
    } catch (e) {
      debugPrint("Error searching for match: $e");
    }

    if (snapshot != null) {
      for (final doc in snapshot.docs) {
        // Double check it's not full
        final data = doc.data() as Map<String, dynamic>;
        
        // Manual Filter (Since we removed query filters)
        // Check Status, Difficulty, AND Max Players config
        final int docMaxPlayers = data['maxPlayers'] ?? 4; // Default to 4 for old matches or treat as variable? Let's say default 4.
        
        if (data['status'] != 'waiting' || 
            data['difficulty'] != difficulty || 
            docMaxPlayers != maxPlayers) {
           continue;
        }

        final players = List.from(data['players'] ?? []);
        
        if (players.length < docMaxPlayers) { // Use dynamic max
          // Check if I'm already in it? (Optional)
          
          try {
             await _firestore.runTransaction((transaction) async {
                final freshSnap = await transaction.get(doc.reference);
                if (!freshSnap.exists) throw Exception("sf");
                final freshData = freshSnap.data() as Map<String, dynamic>;
                List<dynamic> freshPlayers = List.from(freshData['players'] ?? []);
                
                final int freshMax = freshData['maxPlayers'] ?? 4;

                if (freshData['status'] != 'waiting' || freshPlayers.length >= freshMax) {
                   throw Exception("Full or started");
                }
                
                freshPlayers.add({
                  'uid': user,
                  'name': playerName,
                  'score': 0
                });

                transaction.update(doc.reference, {
                  'players': freshPlayers,
                });
             });
             return doc.id;
          } catch (e) {
             continue; // Try next match
          }
        }
      }
    }

    // 2. Create Match
    return _createMatch(difficulty, user, playerName, maxPlayers);
  }

  Future<String> _createMatch(String difficulty, String uid, String name, int maxPlayers) async {
    debugPrint("DEBUG: Creating new match...");
    try {
      final newDoc = _firestore.collection('matches').doc();
      await newDoc.set({
        'status': 'waiting',
        'difficulty': difficulty,
        'maxPlayers': maxPlayers, // Store the limit
        'players': [
          {
            'uid': uid,
            'name': name,
            'score': 0
          }
        ],
        'hostId': uid, // Track who created it
        'createdAt': FieldValue.serverTimestamp(),
        'sequenceParams': _getParamsForDifficulty(difficulty),
      });
      debugPrint("DEBUG: Match created! ID: ${newDoc.id}");
      return newDoc.id;
    } catch (e) {
       debugPrint("DEBUG: Error creating match: $e");
       rethrow;
    }
  }

  Map<String, dynamic> _getParamsForDifficulty(String diff) {
    switch (diff) {
      case 'Easy':
        return {'speed': 1200, 'length': 3, 'digits': 1};
      case 'Hard':
        return {'speed': 600, 'length': 7, 'digits': 2};
      case 'Extreme':
        return {'speed': 400, 'length': 10, 'digits': 2}; 
      case 'Medium':
      default:
        return {'speed': 800, 'length': 5, 'digits': 1};
    }
  }

  @override
  Stream<MatchState> streamMatch(String matchId) {
    return _firestore.collection('matches').doc(matchId).snapshots().map((doc) {
      if (!doc.exists) {
        return MatchState(status: 'error', players: []);
      }
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'waiting';
      final winnerId = data['winner'];
      
      final List<dynamic> rawPlayers = data['players'] ?? [];
      final List<PlayerState> players = rawPlayers.map((p) => PlayerState(
        uid: p['uid'],
        name: p['name'],
        score: p['score'] ?? 0,
      )).toList();

      return MatchState(
        status: status,
        players: players,
        gameParams: data['sequenceParams'],
        winnerId: winnerId,
        maxPlayers: data['maxPlayers'] ?? 2,
      );
    });
  }

  @override
  Future<void> updateScore(String matchId, int newScore) async {
    final uid = currentUserId;
    if (uid == null) return;
    
    final docRef = _firestore.collection('matches').doc(matchId);
    
    await _firestore.runTransaction((transaction) async {
       final snapshot = await transaction.get(docRef);
       if(!snapshot.exists) return;
       
       final data = snapshot.data() as Map<String, dynamic>;
       if (data['status'] == 'finished') return;

       final List<dynamic> players = List.from(data['players'] ?? []);
       bool updated = false;
       for (var i = 0; i < players.length; i++) {
         if (players[i]['uid'] == uid) {
           players[i]['score'] = newScore;
           updated = true;
           break;
         }
       }
       
       if (updated) {
         Map<String, dynamic> updates = {'players': players};
         if (newScore >= 500) {
            updates['status'] = 'finished';
            updates['winner'] = uid;
         }
         transaction.update(docRef, updates);
       }
    });
  }
  
  // Method to Force Start (for Host)
  Future<void> startGame(String matchId) async {
    await _firestore.collection('matches').doc(matchId).update({
      'status': 'playing',
      'startTime': FieldValue.serverTimestamp(),
    });
  }
}
