// REPLACE THIS FILE — run 'flutterfire configure' against your own Firebase project.
//
// Install the CLI: dart pub global activate flutterfire_cli
// Then run:        flutterfire configure
//
// This stub exists only so the starter compiles. Calls to Firebase.initializeApp
// with these placeholder values WILL fail at runtime until you regenerate this
// file against your own Firebase project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _placeholder;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _placeholder;
      case TargetPlatform.iOS:
        return _placeholder;
      case TargetPlatform.macOS:
        return _placeholder;
      case TargetPlatform.windows:
        return _placeholder;
      case TargetPlatform.linux:
        return _placeholder;
      default:
        return _placeholder;
    }
  }

  static const FirebaseOptions _placeholder = FirebaseOptions(
   apiKey: "AIzaSyAOrpMpLgqNLTBKHiFsiCWQiHiWFXIRoaw",
  authDomain: "just-chat-69e37.firebaseapp.com",
  projectId: "just-chat-69e37",
  storageBucket: "just-chat-69e37.firebasestorage.app",
  messagingSenderId: "1061320172505",
  appId: "1:1061320172505:web:39818267c634d572872fc8"
  );
}
