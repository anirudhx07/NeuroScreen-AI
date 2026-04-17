import 'package:cloud_firestore/cloud_firestore.dart';

class TestResult {
  final String id;
  final String userId;
  final String testType; // 'memory', 'reaction_time', 'motor_skills', 'voice_analysis', 'eye_tracking'
  final double score; // 0-100
  final DateTime timestamp;
  final Map<String, dynamic> details; // Additional test-specific data

  TestResult({
    required this.id,
    required this.userId,
    required this.testType,
    required this.score,
    required this.timestamp,
    this.details = const {},
  });

  factory TestResult.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TestResult(
      id: doc.id,
      userId: data['userId'] ?? '',
      testType: data['testType'] ?? '',
      score: (data['score'] ?? 0).toDouble(),
      timestamp: _parseTimestamp(data['timestamp']) ?? DateTime.now(),
      details: data['details'] ?? {},
    );
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    // Handle Firestore Timestamp
    try {
      return timestamp.toDate();
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'testType': testType,
      'score': score,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
    };
  }
}
