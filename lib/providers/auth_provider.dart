import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../services/social_service.dart';

class AuthProvider with ChangeNotifier {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUsername = 'username';

  bool _isLoggedIn = false;
  bool _isInitializing = true;
  String? _username;

  bool get isLoggedIn => _isLoggedIn;
  bool get isInitializing => _isInitializing;
  String? get username => _username;

  AuthProvider() {
    _loadAuthState();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _loadAuthState() async {
    final user = _auth.currentUser;
    _updateUser(user);

    _auth.authStateChanges().listen((User? user) {
      _updateUser(user);
    });
  }

  void _updateUser(User? user) {
    if (user != null) {
      _isLoggedIn = true;
      final email = user.email;
      if (email != null) {
        if (email.contains("@velocity.app")) {
          _username = email.split("@")[0];
        } else {
          _username = user.displayName ?? email.split("@")[0];
        }
      }
      SocialService().ensureProfileExists();
      _username = null;
    }
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) throw Exception("Fields cannot be empty");
    
    final email = "$username@velocity.app";
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        throw Exception("Invalid username or password");
      }
      throw Exception(e.message ?? "Login failed");
    }
  }

  Future<void> register(String username, String password) async {
    if (username.isEmpty || password.isEmpty) throw Exception("Fields cannot be empty");
    if (username.contains(" ")) throw Exception("Username cannot contain spaces");
    if (username.length < 3) throw Exception("Username must be at least 3 characters");
    
    final email = "$username@velocity.app";
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        // Update Firebase Auth Profile
        await credential.user!.updateDisplayName(username);
        await credential.user!.reload(); // Reload to get the new display name
        
        // Create Firestore Profile
        await SocialService().createUserProfile(credential.user!.uid, username, email);
        
        // Force update local state immediately
        _updateUser(_auth.currentUser); 
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception("Username already exists");
      }
      if (e.code == 'operation-not-allowed') {
        // Fallback: Try Anonymous Auth if Email Auth is disabled
        debugPrint("Email Auth disabled. Trying Anonymous...");
        try {
           final cred = await _auth.signInAnonymously();
           if (cred.user != null) {
              await cred.user!.updateDisplayName(username);
              await SocialService().createUserProfile(cred.user!.uid, username, email);
              _updateUser(cred.user);
              return; // Success via fallback
           }
        } catch (anonError) {
           debugPrint("Anonymous Auth failed too: $anonError");
           throw Exception("Registration unavailable (Provider Disabled)");
        }
      }
      throw Exception(e.message ?? "Registration failed");
    }
  }

  // ... (keeping Google Sign In methods as is) ...
  Future<void> signInWithGoogle() async {
    try {
      UserCredential? credential;
      
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        // Native Android/iOS Sign-In
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
           throw Exception("Sign-In cancelled by user");
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential cred = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        credential = await _auth.signInWithCredential(cred);
      }
      
      if (credential != null && credential.user != null) {
        _updateUser(credential.user);
      }
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      // Clean up error message
      String msg = e.toString().replaceAll("Exception: ", "");
      if (msg.contains("sign_in_failed")) msg = "Configuration Error (Check Firebase/SHA-1)";
      throw Exception(msg);
    }
  }

  Future<void> signInWithGoogleRedirect() async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      await _auth.signInWithRedirect(googleProvider);
    } catch (e) {
      debugPrint("Google Redirect Error: $e");
      throw Exception("Redirect failed");
    }
  }

  void updateLocalUsername(String newName) {
    _username = newName;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _isLoggedIn = false;
    _username = null;
    notifyListeners();
  }
}
