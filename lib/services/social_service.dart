import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // --- USER PROFILES & TICKETS ---

  static const int maxTickets = 5;
  static const int ticketRegenMinutes = 5;

  Future<void> createUserProfile(String uid, String username, String email) async {
    await _firestore.collection('users').doc(uid).set({
      'username': username,
      'email': email,
      'searchKey': username.toLowerCase(),
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      // Ticket System
      'tickets': maxTickets,
      'isPremium': false,
      'lastTicketUpdate': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> ensureProfileExists() async {
    // Backfill if needed
    final user = _auth.currentUser;
    if (user == null) return;
    
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();
    
    if (!doc.exists) {
      // Use "Guest-AbCd" instead of "Unknown"
      String suffix = user.uid.length >= 4 ? user.uid.substring(0, 4) : "User";
      String username = user.displayName ?? user.email?.split('@')[0] ?? "Guest-$suffix";
      await createUserProfile(user.uid, username, user.email ?? "");
    } else {
      // Check for missing ticket fields (Schema Migration)
      final data = doc.data();
      if (data != null && !data.containsKey('tickets')) {
        await docRef.update({
          'tickets': maxTickets,
          'isPremium': false,
          'lastTicketUpdate': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // --- RANKING & POINTS SYSTEM ---
  
  static const int pointsEasy = 10;
  static const int pointsMedium = 25;
  static const int pointsHard = 50;
  static const int pointsExtreme = 100;

  /// Centralized difficulty logic based on game parameters
  static String calculateDifficulty(int digits, int speedMs, int length) {
    // 1. Extreme Cases
    if (digits >= 3) return 'Extreme';
    if (digits == 2 && speedMs <= 500) return 'Extreme';

    // 2. Hard Cases
    if (digits == 2) return 'Hard';
    if (digits == 1 && speedMs <= 400) return 'Hard'; // Very fast single digit

    // 3. Medium Cases
    if (digits == 1 && speedMs <= 800) return 'Medium';

    // 4. Default Easy
    return 'Easy';
  }

  String getRank(int points) {
    if (points >= 2000) return "Diamond";
    if (points >= 1000) return "Gold";
    if (points >= 500) return "Silver";
    if (points >= 100) return "Bronze";
    return "Newbie";
  }

  Future<void> updateUsername(String newName) async {
    final uid = currentUserId;
    if (uid == null) return;
    
    await _firestore.collection('users').doc(uid).update({
      'username': newName,
      'searchKey': newName.toLowerCase(),
    });
  }
  
  // --- LEADERBOARD & STATS ---

  /// Records a win/loss and updates monthly points
  /// [difficulty]: 'Easy', 'Medium', 'Hard', 'Extreme'
  Future<void> recordMatchResult({required bool isWin, required String difficulty}) async {
    final uid = currentUserId;
    if (uid == null) return;

    final now = DateTime.now();
    final monthKey = "${now.year}_${now.month.toString().padLeft(2, '0')}"; // e.g., 2025_12

    int pointsEarned = 0;
    if (isWin) {
      switch (difficulty) {
        case 'Easy': pointsEarned = pointsEasy; break;
        case 'Medium': pointsEarned = pointsMedium; break;
        case 'Hard': pointsEarned = pointsHard; break;
        case 'Extreme': pointsEarned = pointsExtreme; break;
        default: pointsEarned = 10;
      }
    } else {
      // Optional: Deduct points for loss? For now, 0.
      pointsEarned = 0; 
    }

    final userRef = _firestore.collection('users').doc(uid);
    final statsRef = userRef.collection('monthly_stats').doc(monthKey);

    await _firestore.runTransaction((transaction) async {
      // Update Global User Stats (Total)
      transaction.update(userRef, {
        'totalWins': isWin ? FieldValue.increment(1) : FieldValue.increment(0),
        'totalPoints': FieldValue.increment(pointsEarned),
      });

      // Update Monthly Stats
      final statsSnap = await transaction.get(statsRef);
      if (!statsSnap.exists) {
        transaction.set(statsRef, {
          'wins': isWin ? 1 : 0,
          'points': pointsEarned,
          'month': monthKey,
          'uid': uid, // Redundant but useful for collection group queries
        });
      } else {
        transaction.update(statsRef, {
          'wins': isWin ? FieldValue.increment(1) : FieldValue.increment(0),
          'points': FieldValue.increment(pointsEarned),
        });
      }
      
      // We also need to update a root-level collection for efficient global leaderboard querying
      // "leaderboards/{monthKey}/users/{uid}"
      final globalLbRef = _firestore.collection('leaderboards').doc(monthKey).collection('users').doc(uid);
      transaction.set(globalLbRef, {
        'uid': uid,
        'points': FieldValue.increment(pointsEarned),
        'wins': isWin ? FieldValue.increment(1) : FieldValue.increment(0),
        'username': (await transaction.get(userRef)).data()?['username'] ?? 'Unknown', // Keep name synced roughly
      }, SetOptions(merge: true));
    });
  }

  Future<List<Map<String, dynamic>>> getMonthlyLeaderboard() async {
    final now = DateTime.now();
    final monthKey = "${now.year}_${now.month.toString().padLeft(2, '0')}";

    final snapshot = await _firestore.collection('leaderboards')
        .doc(monthKey)
        .collection('users')
        .orderBy('points', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  // --- TICKET LOGIC ---

  Future<bool> consumeTicket() async {
    final uid = currentUserId;
    if (uid == null) return false;

    final docRef = _firestore.collection('users').doc(uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return false;

    final data = snapshot.data()!;
    final isPremium = data['isPremium'] == true;

    if (isPremium) return true; // Premium has unlimited tickets

    // Regenerate first to be fair
    await checkAndRegenerateTickets(uid);
    
    // Fetch fresh after regen
    final freshSnap = await docRef.get();
    int tickets = freshSnap.data()?['tickets'] ?? 0;

    if (tickets > 0) {
      await docRef.update({
        'tickets': FieldValue.increment(-1),
        // If we were at max, start the timer now
        if (tickets == maxTickets) 'lastTicketUpdate': FieldValue.serverTimestamp(), 
      });
      return true;
    } else {
      return false; 
    }
  }

  Future<void> checkAndRegenerateTickets(String? uid) async {
    final targetUid = uid ?? currentUserId;
    if (targetUid == null) return;

    final docRef = _firestore.collection('users').doc(targetUid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data();
    if (data == null) return;

    final int currentTickets = data['tickets'] ?? 0;
    if (currentTickets >= maxTickets) return; // Already full

    final Timestamp? lastUpdate = data['lastTicketUpdate'];
    if (lastUpdate == null) {
       // Init timestamp if missing
       await docRef.update({'lastTicketUpdate': FieldValue.serverTimestamp()});
       return;
    }

    final DateTime lastTime = lastUpdate.toDate();
    final DateTime now = DateTime.now();
    final int diffMinutes = now.difference(lastTime).inMinutes;

    if (diffMinutes >= ticketRegenMinutes) {
      // Calculate how many tickets to grant
      int ticketsToAdd = (diffMinutes / ticketRegenMinutes).floor();
      int newTotal = currentTickets + ticketsToAdd;
      
      if (newTotal > maxTickets) newTotal = maxTickets;
      
      // Update timestamp: Advance it by the exact consumed time-blocks to keep the remainder
      // e.g. if 7 minutes passed (regen 5), we add 1 ticket and keep the 2 extra minutes credit.
      // New Time = Old Time + (TicketsAdded * 5 mins)
      final DateTime newLastTime = lastTime.add(Duration(minutes: ticketsToAdd * ticketRegenMinutes));

      await docRef.update({
        'tickets': newTotal,
        'lastTicketUpdate': Timestamp.fromDate(newLastTime), // Preserve "remainder" time
      });
    }
  }

  Future<void> grantPremium() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({'isPremium': true});
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    final snapshot = await _firestore.collection('users')
        .where('searchKey', isGreaterThanOrEqualTo: query.toLowerCase())
        .where('searchKey', isLessThan: query.toLowerCase() + 'z')
        .limit(10)
        .get();

    return snapshot.docs
        .map((doc) => doc.data())
        .where((data) => data['uid'] != currentUserId) // Exclude self
        .toList();
  }

  // --- FRIEND SYSTEM ---

  Future<void> sendFriendRequest(String toUid) async {
    final fromUid = currentUserId;
    if (fromUid == null) throw Exception("Not signed in");
    
    // Ensure I have a profile so they can see me
    await ensureProfileExists();

    // 1. Add to recipient's "requests" subcollection
    await _firestore.collection('users').doc(toUid).collection('friend_requests').doc(fromUid).set({
      'fromUid': fromUid,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(String fromUid) async {
    final myUid = currentUserId;
    if (myUid == null) throw Exception("Not signed in");

    final batch = _firestore.batch();

    // 1. Remove request
    final requestRef = _firestore.collection('users').doc(myUid).collection('friend_requests').doc(fromUid);
    batch.delete(requestRef);

    // 2. Add to my friends
    final myFriendRef = _firestore.collection('users').doc(myUid).collection('friends').doc(fromUid);
    batch.set(myFriendRef, {
      'uid': fromUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. Add me to their friends
    final theirFriendRef = _firestore.collection('users').doc(fromUid).collection('friends').doc(myUid);
    batch.set(theirFriendRef, {
      'uid': myUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Stream<List<String>> getFriendRequests() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    return _firestore.collection('users').doc(uid).collection('friend_requests').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList(); // Returns UIDs of requesters
    });
  }

  Stream<List<String>> getFriends() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

    return _firestore.collection('users').doc(uid).collection('friends').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.id).toList(); // Returns UIDs of friends
    });
  }

  // Helper to get user details for a list of UIDs
  Future<Map<String, Map<String, dynamic>>> getUsersDetails(List<String> uids) async {
    if (uids.isEmpty) return {};
    // Firestore only allows 10 items in 'whereIn', so we might need to batch or fetch individually.
    // Ideally use whereIn if list is short.
    if (uids.length > 10) uids = uids.sublist(0, 10); 
    
    final snapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: uids).get();
    
    return {for (var doc in snapshot.docs) doc.id: doc.data()};
  }

  // --- CHAT SYSTEM ---

  String getChatId(String uid1, String uid2) {
    // Sort to ensure consistent ID regardless of who started chat
    return uid1.compareTo(uid2) < 0 ? "${uid1}_$uid2" : "${uid2}_$uid1";
  }

  Stream<List<Map<String, dynamic>>> getMessages(String friendUid) {
    final myUid = currentUserId;
    if (myUid == null) return const Stream.empty();
    
    final chatId = getChatId(myUid, friendUid);
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> sendMessage(String friendUid, String text) async {
    final myUid = currentUserId;
    if (myUid == null) return;

    final chatId = getChatId(myUid, friendUid);
    
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': myUid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Optional: Update 'lastMessage' on the chat doc for a list view
    await _firestore.collection('chats').doc(chatId).set({
      'lastMessage': text,
      'lastTimestamp': FieldValue.serverTimestamp(),
      'participants': [myUid, friendUid],
    }, SetOptions(merge: true));
  }

  // --- ADMIN SYSTEM ---

  bool get isAdmin {
    // Basic protection. Ideally use Custom Claims.
    final email = _auth.currentUser?.email;
    return email?.trim().toLowerCase() == "amin.aa.aeid@gmail.com";
  }

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore.collection('users').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getActiveMatches() {
    return _firestore.collection('matches')
        .where('status', whereIn: ['waiting', 'playing'])
        .snapshots()
        .map((snapshot) {
           return snapshot.docs.map((doc) {
             final data = doc.data();
             data['matchId'] = doc.id;
             return data;
           }).toList();
        });
  }

  Future<void> forceEndMatch(String matchId) async {
    await _firestore.collection('matches').doc(matchId).update({
      'status': 'finished',
      'winner': 'admin_terminated',
    });
  }
}
