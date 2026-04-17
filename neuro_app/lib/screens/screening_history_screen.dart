import 'package:flutter/material.dart';
import 'package:neuro_app/services/firestore_test_service.dart';
import 'package:neuro_app/models/test_result.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScreeningHistoryScreen extends StatefulWidget {
  const ScreeningHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ScreeningHistoryScreen> createState() => _ScreeningHistoryScreenState();
}

class _ScreeningHistoryScreenState extends State<ScreeningHistoryScreen> {
  final FirestoreTestService _firestoreService = FirestoreTestService();
  String _selectedFilter = 'all'; // 'all', 'memory', 'reaction_time', etc.

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Screening History')),
        body: const Center(child: Text('Please log in to view history')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening History'),
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
        child: Column(
          children: [
            // Filter buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterButton('All', 'all'),
                    _buildFilterButton('Memory', 'memory'),
                    _buildFilterButton('Reaction', 'reaction_time'),
                    _buildFilterButton('Motor', 'motor_skills'),
                    _buildFilterButton('Voice', 'voice_analysis'),
                    _buildFilterButton('Eye', 'eye_tracking'),
                  ],
                ),
              ),
            ),
            // History list
            Expanded(
              child: StreamBuilder<List<TestResult>>(
                stream: _firestoreService.getTestResultsStream(currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  var results = snapshot.data ?? [];

                  // Filter results
                  if (_selectedFilter != 'all') {
                    results = results
                        .where((r) => r.testType == _selectedFilter)
                        .toList();
                  }

                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No screening history',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      return _buildHistoryCard(result);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(TestResult result) {
    final testName = _getTestName(result.testType);
    final scoreColor = _getScoreColor(result.score);
    final statusText = _getStatusText(result.score);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${result.score.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
                Text(
                  '/100',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        title: Text(
          testName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(
                color: scoreColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(result.timestamp),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        onTap: () {
          // Show test details
          _showTestDetails(result);
        },
      ),
    );
  }

  void _showTestDetails(TestResult result) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getTestName(result.testType),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Score', '${result.score.toStringAsFixed(1)}/100'),
              _buildDetailRow('Status', _getStatusText(result.score)),
              _buildDetailRow('Date', _formatDate(result.timestamp)),
              if (result.details.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...result.details.entries
                    .map((e) => _buildDetailRow(e.key, e.value.toString()))
                    .toList(),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getTestName(String testType) {
    switch (testType) {
      case 'memory':
        return 'Memory Test';
      case 'reaction_time':
        return 'Reaction Time Test';
      case 'motor_skills':
        return 'Motor Skills Test';
      case 'voice_analysis':
        return 'Voice Analysis Test';
      case 'eye_tracking':
        return 'Eye Tracking Test';
      default:
        return testType;
    }
  }

  String _getStatusText(double score) {
    if (score >= 70) return 'Normal';
    if (score >= 40) return 'At Risk';
    return 'High Risk';
  }

  Color _getScoreColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
