import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuro_app/helpers/test_result_helper.dart';
import 'package:neuro_app/screens/neurology_report_screen.dart';

class ReactionTimeTest extends StatefulWidget {
  const ReactionTimeTest({super.key});

  @override
  State<ReactionTimeTest> createState() => _ReactionTimeTestState();
}

class _ReactionTimeTestState extends State<ReactionTimeTest> {
  bool _colorChanged = false;
  int _reactionTime = 0; // in milliseconds
  bool _testStarted = false;
  bool _testCompleted = false;
  late Stopwatch _stopwatch;
  late Timer _delayTimer;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _startTest();
  }

  void _startTest() {
    _testStarted = true;
    final randomDelay = Random().nextInt(15) + 1; // 1-15 seconds

    _delayTimer = Timer(Duration(seconds: randomDelay), () {
      if (mounted) {
        setState(() {
          _colorChanged = true;
        });
        _stopwatch.start();
      }
    });
  }

  void _onStopPressed() {
    if (!_colorChanged) {
      // User pressed too early
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait for the screen to turn red!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_testCompleted) {
      _stopwatch.stop();
      setState(() {
        _reactionTime = _stopwatch.elapsedMilliseconds;
        _testCompleted = true;
      });
    }
  }

  void _restartTest() {
    _stopwatch.reset();
    setState(() {
      _colorChanged = false;
      _reactionTime = 0;
      _testStarted = false;
      _testCompleted = false;
    });
    _startTest();
  }

  Future<void> _storeTestResult(int reactionTimeMs) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await TestResultHelper.storeReactionTimeTestResult(
          userId: currentUser.uid,
          reactionTimeMs: reactionTimeMs.toDouble(),
        );
        print('Reaction time test result stored: $reactionTimeMs ms');
      }
    } catch (e) {
      print('Error storing test result: $e');
    }
  }

  void _viewReport() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NeurologyReportScreen(userId: currentUser.uid),
        ),
      );
    }
  }

  @override
  void dispose() {
    _delayTimer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reaction Time Test'),
        backgroundColor: Colors.blue[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: _colorChanged ? Colors.red[700] : Colors.green[700],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_testCompleted)
                Column(
                  children: [
                    if (!_colorChanged)
                      Column(
                        children: [
                          Text(
                            'Wait for the color change...',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Text(
                            'NOW!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    GestureDetector(
                      onTap: _onStopPressed,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'STOP',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Your Reaction Time',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${_reactionTime}ms',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_reactionTime / 1000).toStringAsFixed(2)}s',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildPerformanceIndicator(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _restartTest,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            _storeTestResult(_reactionTime);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    String performance;
    Color color;

    if (_reactionTime < 200) {
      performance = 'Excellent!';
      color = Colors.green;
    } else if (_reactionTime < 300) {
      performance = 'Very Good';
      color = Colors.blue;
    } else if (_reactionTime < 400) {
      performance = 'Good';
      color = Colors.orange;
    } else {
      performance = 'Average';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
      ),
      child: Text(
        performance,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
