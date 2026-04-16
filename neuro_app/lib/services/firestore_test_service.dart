import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neuro_app/models/test_result.dart';
import 'package:neuro_app/models/neurology_report.dart';

class FirestoreTestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Store a single test result in Firestore
  Future<void> storeTestResult(TestResult testResult) async {
    try {
      await _firestore
          .collection('users')
          .doc(testResult.userId)
          .collection('test_results')
          .doc(testResult.id)
          .set(testResult.toFirestore());
    } catch (e) {
      print('Error storing test result: $e');
      rethrow;
    }
  }

  /// Retrieve all test results for a user
  Future<List<TestResult>> getUserTestResults(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('test_results')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => TestResult.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error retrieving test results: $e');
      return [];
    }
  }

  /// Retrieve recent test results (last N days)
  Future<List<TestResult>> getRecentTestResults(String userId, {int days = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('test_results')
          .where('timestamp', isGreaterThanOrEqualTo: cutoffDate)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => TestResult.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error retrieving recent test results: $e');
      return [];
    }
  }

  /// Store a neurology report in Firestore
  Future<void> storeNeurologyReport(NeurologyReport report) async {
    try {
      await _firestore
          .collection('users')
          .doc(report.userId)
          .collection('neurology_reports')
          .doc(report.id)
          .set(report.toFirestore());
    } catch (e) {
      print('Error storing neurology report: $e');
      rethrow;
    }
  }

  /// Retrieve the latest neurology report for a user
  Future<NeurologyReport?> getLatestReport(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('neurology_reports')
          .orderBy('generatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return NeurologyReport.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('Error retrieving latest report: $e');
      return null;
    }
  }

  /// Retrieve all neurology reports for a user
  Future<List<NeurologyReport>> getUserReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('neurology_reports')
          .orderBy('generatedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => NeurologyReport.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error retrieving user reports: $e');
      return [];
    }
  }

  /// Delete a test result
  Future<void> deleteTestResult(String userId, String testResultId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('test_results')
          .doc(testResultId)
          .delete();
    } catch (e) {
      print('Error deleting test result: $e');
      rethrow;
    }
  }

  /// Stream of user's test results (real-time updates)
  Stream<List<TestResult>> getTestResultsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('test_results')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TestResult.fromFirestore(doc)).toList());
  }

  /// Stream of user's neurology reports (real-time updates)
  Stream<List<NeurologyReport>> getReportsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('neurology_reports')
        .orderBy('generatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NeurologyReport.fromFirestore(doc)).toList());
  }
}
