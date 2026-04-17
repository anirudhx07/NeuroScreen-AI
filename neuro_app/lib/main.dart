import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } on FirebaseException catch (e) {
    print('Firebase initialization failed: ${e.code} - ${e.message}');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

/// Main application widget that configures the MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroScreen',
      // Configure app theme with deep blue seed color
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Start app with splash screen
      home: const SplashScreen(),
    );
  }
}
