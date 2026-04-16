import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

/// Home page - Screening Tests interface
class HomePage extends StatefulWidget {
  final User? user;

  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening Tests'),
        backgroundColor: Colors.blue[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => _logout(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.user?.displayName ?? 'Guest User',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
            child: Column(
              children: [
                // Progress Tracker
                _buildProgressTracker(),
                const SizedBox(height: 32),

                // Progress Description
                Text(
                  'Complete all 4 tests in any order',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Test Cards Grid
                _buildTestCard(
                  icon: Icons.mic,
                  title: 'Voice Analysis',
                  description: 'Read a sentence aloud for AI analysis',
                  duration: '~2 min',
                  status: 'Completed',
                  statusColor: Colors.green,
                  isCompleted: true,
                ),
                const SizedBox(height: 16),

                _buildTestCard(
                  icon: Icons.touch_app,
                  title: 'Motor Skills',
                  description: 'Tap rapidly to measure motor control',
                  duration: '~2 min',
                  status: 'In Progress',
                  statusColor: Colors.blue,
                  isInProgress: true,
                ),
                const SizedBox(height: 16),

                _buildTestCard(
                  icon: Icons.psychology,
                  title: 'Memory Test',
                  description: 'Remember and recall a word sequence',
                  duration: '~2 min',
                  status: 'Not Started',
                  statusColor: Colors.grey,
                ),
                const SizedBox(height: 16),

                _buildTestCard(
                  icon: Icons.bolt,
                  title: 'Reaction Time',
                  description: 'Tap when the screen changes color',
                  duration: '~2 min',
                  status: 'Not Started',
                  statusColor: Colors.grey,
                ),
                const SizedBox(height: 32),

                // Offline Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, color: Colors.grey[500], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'All tests offline — no internet required',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Bottom Navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomNavigation(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    return Row(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressCircle(1, isCompleted: true),
              _buildProgressLine(true),
              _buildProgressCircle(2, isActive: true),
              _buildProgressLine(false),
              _buildProgressCircle(3),
              _buildProgressLine(false),
              _buildProgressCircle(4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCircle(int number, {bool isCompleted = false, bool isActive = false}) {
    if (isCompleted) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8),
          ],
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 24),
      );
    }

    if (isActive) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 2),
          color: Colors.white,
        ),
        child: Center(
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 2),
        color: Colors.grey[100],
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressLine(bool isFilled) {
    return Expanded(
      child: Container(
        height: 2,
        color: isFilled ? Colors.blue : Colors.grey[300],
      ),
    );
  }

  Widget _buildTestCard({
    required IconData icon,
    required String title,
    required String description,
    required String duration,
    required String status,
    required Color statusColor,
    bool isCompleted = false,
    bool isInProgress = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isInProgress
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Duration and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isInProgress
                      ? Colors.blue[100]
                      : isCompleted
                          ? Colors.green[100]
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (isCompleted)
                      const Icon(Icons.check_circle, size: 14, color: Colors.green),
                    if (isCompleted) const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard, 'Home', 0),
          _buildNavItem(Icons.assessment, 'Tests', 1),
          _buildNavItem(Icons.psychology, 'Results', 2),
          _buildNavItem(Icons.account_circle, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNavIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.blue : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
