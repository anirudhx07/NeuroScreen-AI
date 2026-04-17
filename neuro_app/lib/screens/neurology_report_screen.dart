import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:neuro_app/models/neurology_report.dart';
import 'package:neuro_app/models/test_result.dart';
import 'package:neuro_app/services/firestore_test_service.dart';
import 'package:neuro_app/services/neurological_analysis_service.dart';
import 'package:neuro_app/services/ml_api_service.dart';
import 'package:neuro_app/services/pdf_export_service.dart';
import 'package:neuro_app/widgets/report_card_widget.dart';

class NeurologyReportScreen extends StatefulWidget {
  final String userId;

  const NeurologyReportScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<NeurologyReportScreen> createState() => _NeurologyReportScreenState();
}

class _NeurologyReportScreenState extends State<NeurologyReportScreen> {
  final FirestoreTestService _firestoreService = FirestoreTestService();
  final MLApiService _mlApiService = MLApiService();
  NeurologyReport? _report;
  bool _isLoading = true;
  String? _errorMessage;
  bool _usingMLBackend = false;  // Track if ML backend was used

  @override
  void initState() {
    super.initState();
    _loadAndGenerateReport();
  }

  Future<void> _loadAndGenerateReport() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('========== REPORT GENERATION START ==========');
      print('DEBUG: Starting report generation for user: ${widget.userId}');
      print('DEBUG: ML API Endpoint: ${_mlApiService.baseUrl}');

      // Check ML backend health first
      print('DEBUG: Checking ML backend health...');
      bool mlBackendHealthy = false;
      try {
        mlBackendHealthy = await _mlApiService.healthCheck().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('DEBUG: Health check timeout');
            return false;
          },
        );
        print('DEBUG: ML backend health check result: $mlBackendHealthy');
      } catch (e) {
        print('ERROR: Health check failed: $e');
        mlBackendHealthy = false;
      }

      // Add timeout to prevent hanging
      final recentTests = await _firestoreService
          .getRecentTestResults(widget.userId, days: 30)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('DEBUG: getRecentTestResults timeout');
              return [];
            },
          );

      print('DEBUG: Found ${recentTests.length} recent test results');

      if (recentTests.isEmpty) {
        print('DEBUG: No recent tests found');
        setState(() {
          _errorMessage = 'No test results found yet. Complete the Memory Test first.';
          _isLoading = false;
        });
        return;
      }

      for (var test in recentTests) {
        print('DEBUG: Test - ${test.testType}: ${test.score}');
      }

      // Get all historical tests
      final allTests = await _firestoreService
          .getUserTestResults(widget.userId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('DEBUG: getUserTestResults timeout');
              return [];
            },
          );

      print('DEBUG: Found ${allTests.length} total historical tests');

      // Try to generate report using ML backend if healthy
      if (mlBackendHealthy) {
        print('DEBUG: ML backend is healthy - Calling ML backend API for risk prediction');
        try {
          final mlPrediction = await _mlApiService
              .predictRisk(recentTests)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () => throw TimeoutException('ML API timeout'),
              );

          print('DEBUG: ML prediction received - Score: ${mlPrediction.overallRiskScore}, Level: ${mlPrediction.riskLevel}');

          // Create report from ML predictions
          final report = NeurologyReport(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: widget.userId,
            generatedAt: DateTime.now(),
            overallRiskScore: mlPrediction.overallRiskScore,
            riskLevel: mlPrediction.riskLevel == 'low'
                ? RiskLevel.low
                : (mlPrediction.riskLevel == 'medium' ? RiskLevel.medium : RiskLevel.high),
            testScores: _createTestBreakdowns(recentTests, mlPrediction),
            trendData: _calculateTrends(recentTests, allTests),
            interpretation: mlPrediction.confidence > 0.8
                ? 'ML-powered assessment (${(mlPrediction.confidence * 100).toStringAsFixed(1)}% confidence)'
                : 'ML assessment',
            recommendations: mlPrediction.recommendations,
          );

          _usingMLBackend = true;
          print('DEBUG: Report created from ML backend');

          // Store report
          print('DEBUG: Storing report to Firestore');
          await _firestoreService.storeNeurologyReport(report).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('DEBUG: storeNeurologyReport timeout');
              return;
            },
          );

          if (mounted) {
            setState(() {
              _report = report;
              _isLoading = false;
            });
            print('DEBUG: UI updated with ML-powered report');
            print('========== REPORT GENERATION COMPLETE (ML) ==========');
          }
        } on TimeoutException catch (e) {
          print('ERROR: ML API timeout ($e), falling back to local analysis');
          await _generateLocalReport(recentTests, allTests);
        } catch (e) {
          print('ERROR: ML API failed ($e), falling back to local analysis');
          await _generateLocalReport(recentTests, allTests);
        }
      } else {
        print('DEBUG: ML backend not healthy - Using local analysis');
        await _generateLocalReport(recentTests, allTests);
      }
    } catch (e) {
      print('ERROR: Report generation failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error generating report: $e';
          _isLoading = false;
        });
      }
      print('========== REPORT GENERATION FAILED ==========');
    }
  }

  /// Fallback method if ML API is unavailable
  Future<void> _generateLocalReport(
    List<TestResult> recentTests,
    List<TestResult> allTests,
  ) async {
    try {
      print('DEBUG: Generating local report (fallback)');
      final report = NeurologicalAnalysisService.analyzeResults(
        widget.userId,
        recentTests,
        historicalTests: allTests,
      );

      print('DEBUG: Local report generated - Score: ${report.overallRiskScore}');

      // Store report
      await _firestoreService.storeNeurologyReport(report).timeout(
        const Duration(seconds: 10),
        onTimeout: () => print('DEBUG: storeNeurologyReport timeout'),
      );

      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
          _usingMLBackend = false;
        });
        print('DEBUG: UI updated with local analysis report');
        print('========== REPORT GENERATION COMPLETE (LOCAL) ==========');
      }
    } catch (e) {
      print('ERROR: Local report generation failed: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error generating report: $e';
          _isLoading = false;
        });
      }
      print('========== REPORT GENERATION FAILED ==========');
    }
  }

  /// Create test score breakdowns from ML predictions
  Map<String, TestScoreBreakdown> _createTestBreakdowns(
    List<TestResult> recentTests,
    RiskPredictionResponse mlPrediction,
  ) {
    final breakdowns = <String, TestScoreBreakdown>{};

    for (var test in recentTests) {
      final categoryRisk = mlPrediction.riskCategories[test.testType] ?? 0.0;
      final status = categoryRisk < 33
          ? 'Normal'
          : (categoryRisk < 66 ? 'At Risk' : 'High Risk');

      breakdowns[test.testType] = TestScoreBreakdown(
        testName: test.testType,
        score: test.score,
        status: status,
        feedback: 'Score: ${test.score.toStringAsFixed(1)}/100',
      );
    }

    return breakdowns;
  }

  /// Calculate trends from test history
  Map<String, double> _calculateTrends(
    List<TestResult> recentTests,
    List<TestResult> allTests,
  ) {
    final trends = <String, double>{};

    // Group by test type
    final byTestType = <String, List<TestResult>>{};
    for (var test in allTests) {
      if (!byTestType.containsKey(test.testType)) {
        byTestType[test.testType] = [];
      }
      byTestType[test.testType]!.add(test);
    }

    // Calculate trend for each test type
    for (var entry in byTestType.entries) {
      final tests = entry.value;
      if (tests.length >= 2) {
        final scores = tests.map((t) => t.score).whereType<double>().toList();
        if (scores.isNotEmpty) {
          final avg = scores.reduce((a, b) => a + b) / scores.length;
          final recent = recentTests
              .where((t) => t.testType == entry.key)
              .map((t) => t.score)
              .whereType<double>()
              .toList();

          if (recent.isNotEmpty) {
            final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
            trends[entry.key] = ((recentAvg - avg) / avg * 100);
          }
        }
      }
    }

    return trends;
  }

  Future<void> _exportToPDF() async {
    if (_report == null) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      final pdfFile = await PDFExportService.generatePDFReport(_report!);

      if (pdfFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to: ${pdfFile.path}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  Future<void> _shareReport() async {
    if (_report == null) return;

    try {
      final pdfFile = await PDFExportService.generatePDFReport(_report!);

      if (pdfFile != null) {
        await Share.shareXFiles(
          [XFile(pdfFile.path)],
          subject: 'NeuroScreen AI - Neurology Assessment Report',
          text: 'My cognitive assessment report from NeuroScreen AI',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Report'),
        backgroundColor: Colors.blue[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_report != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.blue),
              onPressed: _loadAndGenerateReport,
              tooltip: 'Refresh Report',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.grey[50]!],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Generating your assessment report...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAndGenerateReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_report == null) {
      return const Center(
        child: Text('No report available'),
      );
    }

    return ReportCardWidget(
      report: _report!,
      onPdfExport: _exportToPDF,
      onShareReport: _shareReport,
    );
  }
}
