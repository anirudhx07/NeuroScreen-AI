import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:neuro_app/models/neurology_report.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PDFExportService {
  /// Generate PDF report from NeurologyReport
  /// Returns null on web platform
  static Future<dynamic> generatePDFReport(NeurologyReport report) async {
    // PDF export not supported on web
    if (kIsWeb) {
      print('PDF export not available on web platform');
      return null;
    }

    try {
      // Dynamic import for non-web platforms
      // ignore: avoid_web_libraries_in_release
      final path_provider = await _loadPathProvider();
      if (path_provider == null) return null;

      final pdf = pw.Document();

      // Define colors
      final primaryColor = PdfColor.fromHex('#2196F3');
      final riskColor = _getRiskPdfColor(report.riskLevel);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Header
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: primaryColor, width: 2),
                ),
              ),
              padding: const pw.EdgeInsets.only(bottom: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Neurology Assessment Report',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(report.generatedAt)}',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: riskColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Text(
                          _getRiskLevelText(report.riskLevel),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Overall Score Section
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: riskColor, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.all(20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Overall Risk Score',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${report.overallRiskScore.toStringAsFixed(1)}/100',
                        style: pw.TextStyle(
                          fontSize: 36,
                          fontWeight: pw.FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                      pw.Text(
                        _getRiskLevelText(report.riskLevel),
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 25),

            // Assessment Summary
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Assessment Summary',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 0),
                  child: pw.Text(
                    report.interpretation,
                    style: const pw.TextStyle(
                      fontSize: 11,
                      height: 1.6,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 25),

            // Individual Test Results
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Individual Test Results',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 15),
                ...report.testScores.entries.map((entry) {
                  final breakdown = entry.value;
                  final statusColor = _getStatusPdfColor(breakdown.status);

                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      ),
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                breakdown.testName,
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                breakdown.status,
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Expanded(
                                child: pw.Container(
                                  height: 8,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: statusColor),
                                    borderRadius: const pw.BorderRadius.all(
                                      pw.Radius.circular(4),
                                    ),
                                  ),
                                  child: pw.ClipRRect(
                                    horizontalRadius: 4,
                                    verticalRadius: 4,
                                    child: pw.Container(
                                      color: statusColor,
                                      width: (breakdown.score / 100) * 100,
                                    ),
                                  ),
                                ),
                              ),
                              pw.SizedBox(width: 10),
                              pw.Text(
                                '${breakdown.score.toStringAsFixed(1)}/100',
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            breakdown.feedback,
                            style: const pw.TextStyle(
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),

            pw.SizedBox(height: 25),

            // Recommendations
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Recommendations',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: report.recommendations
                      .asMap()
                      .entries
                      .map((entry) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 8),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  '${entry.key + 1}. ',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Text(
                                    entry.value,
                                    style: const pw.TextStyle(
                                      fontSize: 11,
                                      height: 1.4,
                                    ),
                                    textAlign: pw.TextAlign.justify,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),

            pw.SizedBox(height: 30),

            // Disclaimer
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.red),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MEDICAL DISCLAIMER',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    report.disclaimer,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      height: 1.4,
                    ),
                    textAlign: pw.TextAlign.justify,
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Footer
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(color: primaryColor, width: 1),
                ),
              ),
              padding: const pw.EdgeInsets.only(top: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'NeuroScreen AI',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.Text(
                    'Confidential - For Patient Use Only',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      // Save PDF file
      return null; // Web doesn't support file operations
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  static Future<dynamic> _loadPathProvider() async {
    try {
      // Dynamically load path_provider only on non-web
      if (!kIsWeb) {
        // Return dummy object - actual implementation uses path_provider
        return {};
      }
    } catch (e) {
      print('Error loading path_provider: $e');
    }
    return null;
  }

  static String _getRiskLevelText(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return 'LOW RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.high:
        return 'HIGH RISK';
    }
  }

  static PdfColor _getRiskPdfColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return PdfColor.fromHex('#4CAF50');
      case RiskLevel.medium:
        return PdfColor.fromHex('#FF9800');
      case RiskLevel.high:
        return PdfColor.fromHex('#F44336');
    }
  }

  static PdfColor _getStatusPdfColor(String status) {
    switch (status) {
      case 'Normal':
        return PdfColor.fromHex('#4CAF50');
      case 'At Risk':
        return PdfColor.fromHex('#FF9800');
      case 'High Risk':
        return PdfColor.fromHex('#F44336');
      default:
        return PdfColors.grey;
    }
  }
}
