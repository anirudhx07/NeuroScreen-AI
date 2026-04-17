import 'package:neuro_app/models/neurology_report.dart';
import 'package:neuro_app/models/test_result.dart';

class NeurologicalAnalysisService {
  // Risk thresholds for each test type (score out of 100)
  static const Map<String, Map<String, double>> testThresholds = {
    'memory': {
      'high_risk': 40.0, // below 40 = high risk
      'medium_risk': 70.0, // 40-70 = medium, above 70 = low
    },
    'reaction_time': {
      'high_risk': 40.0,
      'medium_risk': 70.0,
    },
    'motor_skills': {
      'high_risk': 40.0,
      'medium_risk': 70.0,
    },
    'voice_analysis': {
      'high_risk': 40.0,
      'medium_risk': 70.0,
    },
    'eye_tracking': {
      'high_risk': 40.0,
      'medium_risk': 70.0,
    },
  };

  // Weights for each test in overall score calculation
  static const Map<String, double> testWeights = {
    'memory': 0.25,
    'reaction_time': 0.20,
    'motor_skills': 0.20,
    'voice_analysis': 0.18,
    'eye_tracking': 0.17,
  };

  /// Analyzes test results and generates a comprehensive report
  static NeurologyReport analyzeResults(
    String userId,
    List<TestResult> recentTests, {
    List<TestResult>? historicalTests,
  }) {
    // Group tests by type and get latest score for each
    Map<String, double> latestScores = {};
    for (var test in recentTests) {
      latestScores[test.testType] = test.score;
    }

    // Add all test types (completed or not)
    final allTestTypes = ['memory', 'reaction_time', 'motor_skills', 'voice_analysis', 'eye_tracking'];
    for (var testType in allTestTypes) {
      if (!latestScores.containsKey(testType)) {
        latestScores[testType] = 0; // Mark as incomplete
      }
    }

    // Calculate individual test breakdowns
    Map<String, TestScoreBreakdown> testBreakdowns = {};
    double totalWeightedScore = 0.0;
    double totalWeight = 0.0;

    latestScores.forEach((testType, score) {
      final weight = testWeights[testType] ?? 0.2;

      // Only count completed tests in overall score
      if (score > 0) {
        totalWeightedScore += score * weight;
        totalWeight += weight;
      }

      final breakdown = _createTestBreakdown(testType, score);
      testBreakdowns[testType] = breakdown;
    });

    // Calculate overall risk score
    final overallScore = totalWeight > 0 ? totalWeightedScore / totalWeight : 0.0;

    // Calculate trends
    Map<String, double> trends = {};
    if (historicalTests != null && historicalTests.isNotEmpty) {
      trends = _calculateTrends(recentTests, historicalTests);
    }

    // Generate interpretation and recommendations
    final interpretation = _generateInterpretation(overallScore);
    final recommendations = _generateRecommendations(overallScore, testBreakdowns);

    return NeurologyReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      generatedAt: DateTime.now(),
      overallRiskScore: overallScore,
      riskLevel: _getRiskLevel(overallScore),
      testScores: testBreakdowns,
      trendData: trends,
      interpretation: interpretation,
      recommendations: recommendations,
    );
  }

  /// Creates a breakdown for individual test
  static TestScoreBreakdown _createTestBreakdown(String testType, double score) {
    // Handle incomplete tests
    if (score == 0) {
      return TestScoreBreakdown(
        testName: _getTestDisplayName(testType),
        score: 0,
        status: 'Not Completed',
        feedback: 'Complete this test to get a score',
      );
    }

    final thresholds = testThresholds[testType] ?? testThresholds['memory']!;
    String status;
    String feedback;

    final highRiskThreshold = thresholds['high_risk'] ?? 40.0;
    final mediumRiskThreshold = thresholds['medium_risk'] ?? 70.0;

    if (score <= highRiskThreshold) {
      status = 'High Risk';
      feedback = _getHighRiskFeedback(testType);
    } else if (score <= mediumRiskThreshold) {
      status = 'At Risk';
      feedback = _getMediumRiskFeedback(testType);
    } else {
      status = 'Normal';
      feedback = _getNormalFeedback(testType);
    }

    return TestScoreBreakdown(
      testName: _getTestDisplayName(testType),
      score: score,
      status: status,
      feedback: feedback,
    );
  }

  /// Calculate trend data by comparing recent vs historical scores
  static Map<String, double> _calculateTrends(
    List<TestResult> recentTests,
    List<TestResult> historicalTests,
  ) {
    Map<String, double> trends = {};

    recentTests.forEach((recentTest) {
      // Find comparable historical test
      final historicalTest = historicalTests.where((h) => h.testType == recentTest.testType).lastWhere(
            (h) => h.timestamp.isBefore(recentTest.timestamp),
            orElse: () => TestResult(
              id: '',
              userId: '',
              testType: '',
              score: recentTest.score, // Default to recent score if no history
              timestamp: DateTime.now(),
            ),
          );

      if (historicalTest.id.isNotEmpty) {
        final improvement = ((recentTest.score - historicalTest.score) / historicalTest.score) * 100.0;
        trends[recentTest.testType] = improvement;
      }
    });

    return trends;
  }

  static RiskLevel _getRiskLevel(double score) {
    if (score >= 80.0) return RiskLevel.low;
    if (score >= 50.0) return RiskLevel.medium;
    return RiskLevel.high;
  }

  static String _getTestDisplayName(String testType) {
    switch (testType) {
      case 'memory':
        return 'Memory Test';
      case 'reaction_time':
        return 'Reaction Time';
      case 'motor_skills':
        return 'Motor Skills';
      case 'voice_analysis':
        return 'Voice Analysis';
      case 'eye_tracking':
        return 'Eye Tracking';
      default:
        return testType;
    }
  }

  static String _generateInterpretation(double score) {
    if (score >= 80.0) {
      return 'Your cognitive performance is within normal range. Your neurological health appears to be stable.';
    } else if (score >= 50.0) {
      return 'Your cognitive performance shows some variation. Monitor your symptoms and consider regular testing.';
    } else {
      return 'Your cognitive performance indicates potential concerns. Please consult a healthcare professional.';
    }
  }

  static List<String> _generateRecommendations(
    double score,
    Map<String, TestScoreBreakdown> testBreakdowns,
  ) {
    List<String> recommendations = [];

    if (score < 50.0) {
      recommendations.add('Schedule a consultation with a neurologist or cognitive specialist');
      recommendations.add('Undergo comprehensive neuropsychological testing');
    }

    if (score < 70.0) {
      recommendations.add('Maintain regular cognitive exercises and mental stimulation');
      recommendations.add('Ensure adequate sleep (7-9 hours per night)');
      recommendations.add('Engage in regular physical exercise');
    }

    recommendations.add('Take periodic tests to monitor cognitive trends');
    recommendations.add('Maintain a healthy diet rich in antioxidants and omega-3');
    recommendations.add('Manage stress through meditation or relaxation techniques');

    // Test-specific recommendations
    testBreakdowns.forEach((testType, breakdown) {
      if (breakdown.status == 'High Risk') {
        switch (testType) {
          case 'memory':
            recommendations.add('Practice memory exercises and mnemonic techniques');
            break;
          case 'reaction_time':
            recommendations.add('Improve attention and focus through targeted exercises');
            break;
          case 'motor_skills':
            recommendations.add('Engage in coordination and balance exercises');
            break;
          case 'voice_analysis':
            recommendations.add('Monitor speech clarity; consult a speech-language pathologist if needed');
            break;
          case 'eye_tracking':
            recommendations.add('Have vision and eye health checked by an optometrist');
            break;
        }
      }
    });

    return recommendations;
  }

  static String _getHighRiskFeedback(String testType) {
    switch (testType) {
      case 'memory':
        return 'Memory recall is below expected levels';
      case 'reaction_time':
        return 'Response time is slower than expected';
      case 'motor_skills':
        return 'Motor coordination shows decline';
      case 'voice_analysis':
        return 'Voice quality indicates potential issues';
      case 'eye_tracking':
        return 'Eye tracking shows significant deviation';
      default:
        return 'Performance is below expected levels';
    }
  }

  static String _getMediumRiskFeedback(String testType) {
    switch (testType) {
      case 'memory':
        return 'Memory performance is moderately below normal';
      case 'reaction_time':
        return 'Response time is moderately slower than normal';
      case 'motor_skills':
        return 'Motor skills show moderate decline';
      case 'voice_analysis':
        return 'Voice quality shows some irregularities';
      case 'eye_tracking':
        return 'Eye tracking shows moderate deviation';
      default:
        return 'Performance is moderately below normal';
    }
  }

  static String _getNormalFeedback(String testType) {
    switch (testType) {
      case 'memory':
        return 'Memory performance is within normal range';
      case 'reaction_time':
        return 'Response time is normal and healthy';
      case 'motor_skills':
        return 'Motor skills are functioning well';
      case 'voice_analysis':
        return 'Voice quality is normal';
      case 'eye_tracking':
        return 'Eye tracking is performing normally';
      default:
        return 'Performance is within normal range';
    }
  }
}
