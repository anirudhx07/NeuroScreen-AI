import 'package:flutter/material.dart';
import 'package:neuro_app/services/firestore_test_service.dart';
import 'package:neuro_app/models/neurology_report.dart';
import 'package:neuro_app/services/pdf_export_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class DownloadReportsScreen extends StatefulWidget {
  const DownloadReportsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadReportsScreen> createState() => _DownloadReportsScreenState();
}

class _DownloadReportsScreenState extends State<DownloadReportsScreen> {
  final FirestoreTestService _firestoreService = FirestoreTestService();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Download Reports')),
        body: const Center(child: Text('Please log in to download reports')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Reports'),
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
                    Icon(Icons.download_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No reports to download',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
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
                return _buildDownloadCard(report);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDownloadCard(NeurologyReport report) {
    final riskColor = _getRiskColor(report.riskLevel);
    final riskText = _getRiskLevelText(report.riskLevel);

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      riskText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${report.overallRiskScore.toStringAsFixed(1)}/100',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(report.generatedAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${report.overallRiskScore.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: riskColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportPDF(report),
                    icon: const Icon(Icons.download),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareReport(report),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPDF(NeurologyReport report) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...')),
    );

    try {
      final pdfFile = await PDFExportService.generatePDFReport(report);
      if (pdfFile != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved: ${report.overallRiskScore.toStringAsFixed(0)}_report.pdf'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF export not available on web')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _shareReport(NeurologyReport report) async {
    try {
      final pdfFile = await PDFExportService.generatePDFReport(report);
      if (pdfFile != null) {
        await Share.shareXFiles(
          [pdfFile],
          subject: 'NeuroScreen AI - Assessment Report',
          text: 'My neurological assessment report from NeuroScreen AI',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share not available on web')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
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
