import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class EyeTrackingTest extends StatefulWidget {
  const EyeTrackingTest({super.key});

  @override
  State<EyeTrackingTest> createState() => _EyeTrackingTestState();
}

class _EyeTrackingTestState extends State<EyeTrackingTest>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<Offset> _dotAnimation;

  int _currentPhase = 0; // 0: horizontal, 1: vertical, 2: circular, 3: random
  bool _testStarted = false;
  bool _testCompleted = false;
  int _totalTracks = 0;
  int _successfulTracks = 0;
  double _averageLatency = 0;
  double _trackingAccuracy = 0;

  late List<EyeTrackPhase> _phases;
  int _currentPhaseIndex = 0;
  late Timer _phaseTimer;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _phases = [
      EyeTrackPhase(
        name: 'Horizontal Tracking',
        duration: 8,
        direction: 'horizontal',
      ),
      EyeTrackPhase(
        name: 'Vertical Tracking',
        duration: 8,
        direction: 'vertical',
      ),
      EyeTrackPhase(
        name: 'Circular Tracking',
        duration: 8,
        direction: 'circular',
      ),
      EyeTrackPhase(
        name: 'Random Tracking',
        duration: 10,
        direction: 'random',
      ),
    ];
  }

  void _startTest() {
    setState(() {
      _testStarted = true;
      _currentPhaseIndex = 0;
    });
    _runPhase();
  }

  void _runPhase() {
    if (_currentPhaseIndex >= _phases.length) {
      _finishTest();
      return;
    }

    EyeTrackPhase phase = _phases[_currentPhaseIndex];

    // Animate the dot
    _dotController.forward(from: 0.0);

    // Simulate tracking accuracy
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _successfulTracks++;
          _averageLatency =
              (_averageLatency * (_totalTracks - 1) + 150 + _random.nextInt(100)) /
                  _totalTracks;
        });
      }
    });

    _totalTracks++;

    _phaseTimer = Timer(Duration(seconds: phase.duration), () {
      if (mounted) {
        setState(() {
          _currentPhaseIndex++;
        });
        _runPhase();
      }
    });
  }

  void _finishTest() {
    _dotController.stop();
    _trackingAccuracy = (_successfulTracks / _totalTracks) * 100;

    setState(() {
      _testCompleted = true;
    });
  }

  void _restartTest() {
    setState(() {
      _testStarted = false;
      _testCompleted = false;
      _currentPhase = 0;
      _totalTracks = 0;
      _successfulTracks = 0;
      _averageLatency = 0;
      _trackingAccuracy = 0;
      _currentPhaseIndex = 0;
    });
  }

  Offset _getAnimationTarget() {
    if (_currentPhaseIndex >= _phases.length) {
      return Offset.zero;
    }

    String direction = _phases[_currentPhaseIndex].direction;

    if (direction == 'horizontal') {
      return _dotController.value < 0.5
          ? const Offset(-0.8, 0)
          : const Offset(0.8, 0);
    } else if (direction == 'vertical') {
      return _dotController.value < 0.5
          ? const Offset(0, -0.7)
          : const Offset(0, 0.7);
    } else if (direction == 'circular') {
      double angle = _dotController.value * 2 * pi;
      return Offset(
        0.7 * cos(angle),
        0.7 * sin(angle),
      );
    } else {
      // Random
      if (_dotController.value < 0.3) {
        return Offset(_random.nextDouble() * 1.6 - 0.8,
            _random.nextDouble() * 1.4 - 0.7);
      } else {
        return const Offset(0, 0);
      }
    }
  }

  @override
  void dispose() {
    _dotController.dispose();
    if (_testStarted) {
      _phaseTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eye-Tracking Test'),
        backgroundColor: Colors.blue[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.purple[50]!],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_testStarted && !_testCompleted)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.remove_red_eye,
                              size: 72,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Eye-Tracking Test',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Track the moving dot with your eyes',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Test Phases:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._phases.map((phase) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 18,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              phase.name,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _startTest,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start Test'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (_testStarted && !_testCompleted)
                  Column(
                    children: [
                      if (_currentPhaseIndex < _phases.length)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                _phases[_currentPhaseIndex].name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (_currentPhaseIndex + 1) / _phases.length,
                                minHeight: 4,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue[600]!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      // Tracking area
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.blue[300]!,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Center crosshair
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 2,
                                  height: 20,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 20,
                                  height: 2,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 2,
                                  height: 20,
                                  color: Colors.grey[300],
                                ),
                              ],
                            ),
                            // Animated dot
                            AnimatedBuilder(
                              animation: _dotController,
                              builder: (context, child) {
                                Offset target = _getAnimationTarget();
                                return Transform.translate(
                                  offset: Offset(
                                    target.dx * 100,
                                    target.dy * 100,
                                  ),
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue[600],
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else if (_testCompleted)
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 72,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Test Completed!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Results
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue[200]!,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildResultRow(
                                    'Tracking Accuracy',
                                    '${_trackingAccuracy.toStringAsFixed(1)}%',
                                    Colors.blue,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildResultRow(
                                    'Average Latency',
                                    '${_averageLatency.toStringAsFixed(0)}ms',
                                    Colors.purple,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildResultRow(
                                    'Successful Tracks',
                                    '$_successfulTracks/$_totalTracks',
                                    Colors.green,
                                  ),
                                ],
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
                              side: BorderSide(color: Colors.blue[700]!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
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
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicator() {
    String performance;
    Color color;

    if (_trackingAccuracy >= 85) {
      performance = 'Excellent Eye Tracking';
      color = Colors.green;
    } else if (_trackingAccuracy >= 75) {
      performance = 'Good Eye Tracking';
      color = Colors.blue;
    } else if (_trackingAccuracy >= 65) {
      performance = 'Average Eye Tracking';
      color = Colors.orange;
    } else {
      performance = 'Needs Improvement';
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
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class EyeTrackPhase {
  final String name;
  final int duration;
  final String direction;

  EyeTrackPhase({
    required this.name,
    required this.duration,
    required this.direction,
  });
}
