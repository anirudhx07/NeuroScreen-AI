import 'package:flutter/material.dart';
import 'package:neuro_app/services/firestore_test_service.dart';
import 'package:neuro_app/models/neurology_report.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({Key? key}) : super(key: key);

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  final FirestoreTestService _firestoreService = FirestoreTestService();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Reports')),
        body: const Center(child: Text('Please log in to view reports')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
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
        child: StreamBuilder<List<NeurologyReport>>(
          stream: _firestoreService.getReportsStream(currentUser!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final reports = snapshot.data ?? [];

            if (reports.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No reports yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete a test to generate your first report',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                return _buildReportCard(report);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildReportCard(NeurologyReport report) {
    final riskColor = _getRiskColor(report.riskLevel);
    final riskText = _getRiskLevelText(report.riskLevel);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context, report);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: riskColor.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Overall Risk Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: riskColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: riskColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${report.overallRiskScore.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          riskText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(report.generatedAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
            // Test Scores Breakdown
            if (report.testScores.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...report.testScores.entries.map((entry) {
                      final testScore = entry.value;
                      final testColor = _getTestStatusColor(testScore.status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    testScore.testName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    testScore.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: testColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: testColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${testScore.score.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: testColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTestStatusColor(String status) {
    switch (status) {
      case 'Normal':
        return Colors.green;
      case 'At Risk':
        return Colors.orange;
      case 'High Risk':
        return Colors.red;
      case 'Not Completed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getRiskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  String _getRiskLevelText(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
