import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Initialize Firebase before running the app
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Handle Firebase initialization errors (e.g., on web with no connection)
    print('Firebase initialization failed: $e');
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
