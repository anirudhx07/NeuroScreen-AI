import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:neuro_app/helpers/test_result_helper.dart';
import 'package:neuro_app/screens/neurology_report_screen.dart';

class MemoryTest extends StatefulWidget {
  const MemoryTest({super.key});

  @override
  State<MemoryTest> createState() => _MemoryTestState();
}

class _MemoryTestState extends State<MemoryTest> {
  late List<String> _originalItems;
  late List<String> _allItems;
  late Set<int> _selectedIndices;
  bool _showingPhase1 = true;
  bool _testCompleted = false;
  int _correctAnswers = 0;
  int _remainingTime = 5;
  late Timer _countdownTimer;

  @override
  void initState() {
    super.initState();
    _generateItems();
  }

  void _generateItems() {
    final itemPool = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];

    // Randomly select 6 items for phase 1
    itemPool.shuffle();
    _originalItems = itemPool.sublist(0, 6);

    // Create list of 15 items: 6 original + 9 new ones
    _allItems = List.from(_originalItems);
    itemPool.removeRange(0, 6);
    itemPool.shuffle();
    _allItems.addAll(itemPool.sublist(0, 9));
    _allItems.shuffle();

    _selectedIndices = {};
    _correctAnswers = 0;
    _remainingTime = 5;
    _showPhase1();
  }

  void _showPhase1() {
    setState(() {
      _showingPhase1 = true;
    });

    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _remainingTime--;
      });
      if (_remainingTime == 0) {
        timer.cancel();
        _moveToPhase2();
      }
    });
  }

  void _moveToPhase2() {
    setState(() {
      _showingPhase1 = false;
    });
  }

  void _toggleItemSelection(int index) {
    if (_showingPhase1) return;

    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else if (_selectedIndices.length < 5) {
        _selectedIndices.add(index);
      }
    });

    if (_selectedIndices.length == 5) {
      _calculateScore();
    }
  }

  void _calculateScore() {
    int correct = 0;
    for (int index in _selectedIndices) {
      if (_originalItems.contains(_allItems[index])) {
        correct++;
      }
    }
    setState(() {
      _correctAnswers = correct;
      _testCompleted = true;
    });

    // Store test result in Firestore
    _storeTestResult(correct);
  }

  Future<void> _storeTestResult(int correctAnswers) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      print('DEBUG: currentUser = $currentUser');
      if (currentUser != null) {
        print('DEBUG: Storing test result for user: ${currentUser.uid}');
        await TestResultHelper.storeMemoryTestResult(
          userId: currentUser.uid,
          correctAnswers: correctAnswers,
          totalItems: 5, // User selects 5 items
        );
        print('✅ Memory test result stored: $correctAnswers/5 correct');
      } else {
        print('❌ ERROR: currentUser is null - user not authenticated');
      }
    } catch (e) {
      print('❌ Error storing test result: $e');
      rethrow;
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

  void _restartTest() {
    if (_countdownTimer.isActive) {
      _countdownTimer.cancel();
    }
    setState(() {
      _testCompleted = false;
    });
    _generateItems();
  }

  @override
  void dispose() {
    if (_countdownTimer.isActive) {
      _countdownTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Test'),
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
            colors: [Colors.blue[50]!, Colors.grey[50]!],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_testCompleted)
                    Column(
                      children: [
                        // Phase 1: Show original 6 items
                        if (_showingPhase1)
                          Column(
                            children: [
                              Text(
                                'Remember these items',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Disappears in $_remainingTime seconds',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Display 6 items in circles
                              Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                alignment: WrapAlignment.center,
                                children: List.generate(
                                  _originalItems.length,
                                  (index) => CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.blue[100],
                                    child: Text(
                                      _originalItems[index],
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          // Phase 2: Show 15 items and ask to select 5
                          Column(
                            children: [
                              Text(
                                'Select the 5 items you saw earlier',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selected: ${_selectedIndices.length}/5',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Display 15 items in circles
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: List.generate(
                                  _allItems.length,
                                  (index) {
                                    bool isSelected = _selectedIndices.contains(index);
                                    return GestureDetector(
                                      onTap: () => _toggleItemSelection(index),
                                      child: CircleAvatar(
                                        radius: 38,
                                        backgroundColor: isSelected ? Colors.blue[600] : Colors.white,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _allItems[index],
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    )
                  else
                    // Test completed - show results
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
                                _correctAnswers == 5 ? Icons.check_circle : Icons.info,
                                size: 72,
                                color: _correctAnswers == 5 ? Colors.green : _correctAnswers >= 3 ? Colors.orange : Colors.red,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _correctAnswers == 5
                                    ? 'Perfect! 🎉'
                                    : _correctAnswers >= 3
                                        ? 'Good Job! 👍'
                                        : 'Keep Practicing',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 28),
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
                                    Text(
                                      '$_correctAnswers/5',
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Correct Selections',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: _correctAnswers / 5,
                                        minHeight: 8,
                                        backgroundColor: Colors.blue[100],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue[600]!,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Memory Accuracy: ${((_correctAnswers / 5) * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _viewReport,
                              icon: const Icon(Icons.assessment),
                              label: const Text('View Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.check),
                              label: const Text('Done'),
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
      ),
    );
  }
}

