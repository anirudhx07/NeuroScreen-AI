import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCiWyAKfmOwS5NId8Hx8N2HLcqg-K85fd8',
    appId: '1:554316239785:android:d185d7c08a9a8e93682ab8',
    messagingSenderId: '554316239785',
    projectId: 'neuroscreen-5002d',
    storageBucket: 'neuroscreen-5002d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCiWyAKfmOwS5NId8Hx8N2HLcqg-K85fd8',
    appId: '1:554316239785:ios:d185d7c08a9a8e93682ab8',
    messagingSenderId: '554316239785',
    projectId: 'neuroscreen-5002d',
    storageBucket: 'neuroscreen-5002d.firebasestorage.app',
    iosBundleId: 'com.example.neuroApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCiWyAKfmOwS5NId8Hx8N2HLcqg-K85fd8',
    appId: '1:554316239785:web:d185d7c08a9a8e93682ab8',
    messagingSenderId: '554316239785',
    projectId: 'neuroscreen-5002d',
    storageBucket: 'neuroscreen-5002d.firebasestorage.app',
    authDomain: 'neuroscreen-5002d.firebaseapp.com',
  );
}
