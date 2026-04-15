import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLogin
          ? LoginScreen(onSwitchToSignup: () {
              setState(() {
                _isLogin = false;
              });
            })
          : SignupScreen(onSwitchToLogin: () {
              setState(() {
                _isLogin = true;
              });
            }),
    );
  }
}
