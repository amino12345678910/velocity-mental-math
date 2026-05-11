// File: lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
         // TODO: User must replace these with real values from Firebase Console
        return const FirebaseOptions(
          apiKey: 'REPLACE_WITH_YOUR_API_KEY',
          appId: 'REPLACE_WITH_YOUR_APP_ID',
          messagingSenderId: 'REPLACE_WITH_YOUR_SENDER_ID',
          projectId: 'REPLACE_WITH_YOUR_PROJECT_ID',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDXsPdHINNuR5mhFXggMTrfI2QSQYckpzI',
    appId: '1:951868438580:web:6738716c8044ceb00db261',
    messagingSenderId: '951868438580',
    projectId: 'velocity-af89b',
    authDomain: 'velocity-af89b.firebaseapp.com',
    storageBucket: 'velocity-af89b.firebasestorage.app',
    measurementId: 'G-ZBJNR9GQ9Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDXsPdHINNuR5mhFXggMTrfI2QSQYckpzI',
    appId: 'REPLACE_WITH_ANDROID_APP_ID', // User needs to create Android App in console if they want this.
    messagingSenderId: '951868438580',
    projectId: 'velocity-af89b',
    storageBucket: 'velocity-af89b.firebasestorage.app',
  );
}
