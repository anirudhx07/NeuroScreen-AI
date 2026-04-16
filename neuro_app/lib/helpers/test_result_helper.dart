import 'package:neuro_app/models/test_result.dart';
import 'package:neuro_app/services/firestore_test_service.dart';

/// Helper class to easily store test results and manage score normalization
class TestResultHelper {
  static final FirestoreTestService _firestoreService = FirestoreTestService();

  /// Store memory test result
  /// [correctAnswers] - number of correct answers (0-5 typically)
  /// [totalItems] - total items to remember
  static Future<void> storeMemoryTestResult({
    required String userId,
    required int correctAnswers,
    required int totalItems,
  }) async {
    final normalizedScore = (correctAnswers.toDouble() / totalItems.toDouble()) * 100.0;

    final testResult = TestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      testType: 'memory',
      score: normalizedScore,
      timestamp: DateTime.now(),
      details: {
        'correctAnswers': correctAnswers,
        'totalItems': totalItems,
        'percentage': (correctAnswers.toDouble() / totalItems.toDouble() * 100.0).toStringAsFixed(1),
      },
    );

    await _firestoreService.storeTestResult(testResult);
  }

  /// Store reaction time test result
  /// [reactionTimeMs] - average reaction time in milliseconds
  /// Lower is better, normal range 200-300ms
  static Future<void> storeReactionTimeTestResult({
    required String userId,
    required double reactionTimeMs,
    double normalReactionTime = 300,
  }) async {
    // Higher score for faster reaction time
    final normalizedScore = 100.0 - ((reactionTimeMs / normalReactionTime) * 100.0).clamp(0.0, 100.0);

    final testResult = TestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      testType: 'reaction_time',
      score: normalizedScore,
      timestamp: DateTime.now(),
      details: {
        'reactionTimeMs': reactionTimeMs,
        'normalReactionTime': normalReactionTime,
        'status': reactionTimeMs < 300 ? 'Fast' : reactionTimeMs < 500 ? 'Normal' : 'Slow',
      },
    );

    await _firestoreService.storeTestResult(testResult);
  }

  /// Store motor skills test result
  /// [score] - user's score
  /// [maxScore] - maximum possible score
  static Future<void> storeMotorSkillsTestResult({
    required String userId,
    required double score,
    required double maxScore,
  }) async {
    final normalizedScore = (score / maxScore) * 100.0;

    final testResult = TestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      testType: 'motor_skills',
      score: normalizedScore,
      timestamp: DateTime.now(),
      details: {
        'score': score,
        'maxScore': maxScore,
        'percentage': (score / maxScore * 100.0).toStringAsFixed(1),
      },
    );

    await _firestoreService.storeTestResult(testResult);
  }

  /// Store voice analysis test result
  /// [analysisScore] - normalized score from voice analysis (0-100)
  /// [metrics] - additional voice metrics (clarity, pitch, etc.)
  static Future<void> storeVoiceAnalysisTestResult({
    required String userId,
    required double analysisScore,
    Map<String, dynamic>? metrics,
  }) async {
    final testResult = TestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      testType: 'voice_analysis',
      score: analysisScore.clamp(0.0, 100.0),
      timestamp: DateTime.now(),
      details: metrics ?? {},
    );

    await _firestoreService.storeTestResult(testResult);
  }

  /// Store eye tracking test result
  /// [accuracyPercentage] - eye tracking accuracy (0-100%)
  /// [trackingQuality] - overall tracking quality metrics
  static Future<void> storeEyeTrackingTestResult({
    required String userId,
    required double accuracyPercentage,
    Map<String, dynamic>? trackingQuality,
  }) async {
    final testResult = TestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      testType: 'eye_tracking',
      score: accuracyPercentage.clamp(0.0, 100.0),
      timestamp: DateTime.now(),
      details: trackingQuality ?? {},
    );

    await _firestoreService.storeTestResult(testResult);
  }

  /// Generic method to store any test result
  static Future<void> storeTestResult({
    required String userId,
    required String testType,
    required double score,
    required Map<String, dynamic> details,
  }) async {
    final testResult = TestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      testType: testType,
      score: score.clamp(0.0, 100.0),
      timestamp: DateTime.now(),
      details: details,
    );

    await _firestoreService.storeTestResult(testResult);
  }

  /// Get the FirestoreTestService for direct access if needed
  static FirestoreTestService getFirestoreService() {
    return _firestoreService;
  }

  /// Convert score to risk level string
  static String scoreToRiskLevel(double score) {
    if (score >= 80) return 'Low Risk';
    if (score >= 50) return 'Medium Risk';
    return 'High Risk';
  }

  /// Get color for risk level
  static String getRiskLevelColor(double score) {
    if (score >= 80) return 'GREEN';
    if (score >= 50) return 'ORANGE';
    return 'RED';
  }
}
