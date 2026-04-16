import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_screen.dart';

/// Splash Screen displayed when app starts
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Pulse animation for icon
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Progress bar animation
    _progressAnimation = Tween<double>(begin: 0, end: 0.66).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.3, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    // Navigate to onboarding after splash duration
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D47A1),
              const Color(0xFF1A73E8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative blur circles
            Positioned(
              top: -96,
              left: -96,
              child: Container(
                width: 384,
                height: 384,
                decoration: BoxDecoration(
                  color: Colors.blue[400]?.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 120,
                      spreadRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -192,
              right: -96,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.lightBlue[300]?.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.lightBlue.withOpacity(0.1),
                      blurRadius: 120,
                      spreadRadius: 100,
                    ),
                  ],
                ),
              ),
            ),
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 80),
                // Center: Icon with pulse rings
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulse rings
                            _buildPulseRing(120, 0.3, Colors.cyan),
                            _buildPulseRing(160, 0.2, Colors.white),
                            _buildPulseRing(200, 0.1, Colors.cyan),
                            // Center icon container
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue[900]!.withOpacity(0.4),
                                    blurRadius: 32,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.psychology,
                                size: 64,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom: Title, subtitle, and progress
                Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    children: [
                      // Title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'NeuroScreen AI',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Early Detection in Minutes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFFB3E5FC),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 64),
                      // Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 6,
                                color: Colors.white.withOpacity(0.2),
                                child: AnimatedBuilder(
                                  animation: _progressAnimation,
                                  builder: (context, child) {
                                    return Stack(
                                      children: [
                                        Container(
                                          height: 6,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.66 *
                                              _progressAnimation.value,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Version
                            const Text(
                              'v2.4.0-stable',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0x80FFFFFF),
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseRing(double size, double opacity, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(opacity),
          width: 2,
        ),
      ),
    );
  }
}
