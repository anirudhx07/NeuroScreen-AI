import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:neuro_app/models/neurology_report.dart';
import 'package:neuro_app/services/firestore_test_service.dart';
import 'package:neuro_app/services/neurological_analysis_service.dart';
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
  NeurologyReport? _report;
  bool _isLoading = true;
  String? _errorMessage;

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

      // Get recent test results (last 30 days)
      final recentTests = await _firestoreService.getRecentTestResults(
        widget.userId,
        days: 30,
      );

      if (recentTests.isEmpty) {
        setState(() {
          _errorMessage = 'No recent test results found. Please complete some tests first.';
          _isLoading = false;
        });
        return;
      }

      // Get all historical tests for trend analysis
      final allTests = await _firestoreService.getUserTestResults(widget.userId);

      // Generate report using analysis service
      final report = NeurologicalAnalysisService.analyzeResults(
        widget.userId,
        recentTests,
        historicalTests: allTests,
      );

      // Store report in Firestore
      await _firestoreService.storeNeurologyReport(report);

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating report: $e';
        _isLoading = false;
      });
      print('Error in _loadAndGenerateReport: $e');
    }
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
