import 'package:cloud_firestore/cloud_firestore.dart';

enum RiskLevel { low, medium, high }

class NeurologyReport {
  final String id;
  final String userId;
  final DateTime generatedAt;
  final double overallRiskScore; // 0-100
  final RiskLevel riskLevel; // Derived from score
  final Map<String, TestScoreBreakdown> testScores; // breakdown by test type
  final Map<String, double> trendData; // trend percentage (positive = improving)
  final String interpretation; // User-friendly description
  final List<String> recommendations;
  final String disclaimer;

  NeurologyReport({
    required this.id,
    required this.userId,
    required this.generatedAt,
    required this.overallRiskScore,
    required this.riskLevel,
    required this.testScores,
    required this.trendData,
    required this.interpretation,
    required this.recommendations,
    this.disclaimer = 'This assessment is not a medical diagnosis. Please consult a healthcare professional for medical evaluation.',
  });

  factory NeurologyReport.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<String, TestScoreBreakdown> testScores = {};
    if (data['testScores'] != null) {
      (data['testScores'] as Map<String, dynamic>).forEach((key, value) {
        testScores[key] = TestScoreBreakdown.fromMap(value as Map<String, dynamic>);
      });
    }

    return NeurologyReport(
      id: doc.id,
      userId: data['userId'] ?? '',
      generatedAt: _parseTimestamp(data['generatedAt']) ?? DateTime.now(),
      overallRiskScore: (data['overallRiskScore'] ?? 0).toDouble(),
      riskLevel: _getRiskLevel((data['overallRiskScore'] ?? 0).toDouble()),
      testScores: testScores,
      trendData: _parseTrendData(data['trendData']),
      interpretation: data['interpretation'] ?? '',
      recommendations: List<String>.from(data['recommendations'] ?? []),
      disclaimer: data['disclaimer'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'generatedAt': Timestamp.fromDate(generatedAt),
      'overallRiskScore': overallRiskScore,
      'riskLevel': riskLevel.toString(),
      'testScores': testScores.map((key, value) => MapEntry(key, value.toMap())),
      'trendData': trendData,
      'interpretation': interpretation,
      'recommendations': recommendations,
      'disclaimer': disclaimer,
    };
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    try {
      return timestamp.toDate();
    } catch (e) {
      return null;
    }
  }

  static Map<String, double> _parseTrendData(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, (value ?? 0).toDouble()));
    }
    return {};
  }

  static RiskLevel _getRiskLevel(double score) {
    if (score >= 80) return RiskLevel.low;
    if (score >= 50) return RiskLevel.medium;
    return RiskLevel.high;
  }
}

class TestScoreBreakdown {
  final String testName;
  final double score; // 0-100
  final String status; // 'Normal', 'At Risk', 'High Risk'
  final String feedback;

  TestScoreBreakdown({
    required this.testName,
    required this.score,
    required this.status,
    required this.feedback,
  });

  factory TestScoreBreakdown.fromMap(Map<String, dynamic> data) {
    return TestScoreBreakdown(
      testName: data['testName'] ?? '',
      score: (data['score'] ?? 0).toDouble(),
      status: data['status'] ?? '',
      feedback: data['feedback'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'testName': testName,
      'score': score,
      'status': status,
      'feedback': feedback,
    };
  }
}
