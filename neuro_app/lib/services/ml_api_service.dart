import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neuro_app/models/test_result.dart';
import 'package:neuro_app/services/app_config.dart';

/// Exception thrown by ML API service
class MLApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? rawResponse;

  MLApiException({
    required this.message,
    this.statusCode,
    this.rawResponse,
  });

  @override
  String toString() => 'MLApiException: $message (Status: $statusCode)';
}

/// Response model for risk prediction
class RiskPredictionResponse {
  final double overallRiskScore;
  final String riskLevel; // 'low', 'medium', 'high'
  final Map<String, double> riskCategories;
  final double confidence;
  final List<String> recommendations;
  final DateTime timestamp;

  RiskPredictionResponse({
    required this.overallRiskScore,
    required this.riskLevel,
    required this.riskCategories,
    required this.confidence,
    required this.recommendations,
    required this.timestamp,
  });

  factory RiskPredictionResponse.fromJson(Map<String, dynamic> json) {
    return RiskPredictionResponse(
      overallRiskScore: (json['overall_risk_score'] ?? 0).toDouble(),
      riskLevel: json['risk_level'] ?? 'medium',
      riskCategories: Map<String, double>.from(
        (json['risk_categories'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      confidence: (json['confidence'] ?? 0).toDouble(),
      recommendations: List<String>.from(json['recommendations'] ?? []),
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'overall_risk_score': overallRiskScore,
        'risk_level': riskLevel,
        'risk_categories': riskCategories,
        'confidence': confidence,
        'recommendations': recommendations,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Response model for trend analysis
class TrendAnalysisResponse {
  final String direction; // 'up', 'down', 'stable'
  final double slope;
  final double strength; // 0-1
  final List<double> forecast;
  final String interpretation;

  TrendAnalysisResponse({
    required this.direction,
    required this.slope,
    required this.strength,
    required this.forecast,
    required this.interpretation,
  });

  factory TrendAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return TrendAnalysisResponse(
      direction: json['direction'] ?? 'stable',
      slope: (json['slope'] ?? 0).toDouble(),
      strength: (json['strength'] ?? 0).toDouble(),
      forecast: List<double>.from(
        (json['forecast'] as List?)?.map((v) => (v as num).toDouble()) ?? [],
      ),
      interpretation: json['interpretation'] ?? '',
    );
  }
}

/// ML API Service - Handles communication with Python ML backend
class MLApiService {
  // Default endpoints for different environments
  static const String _localBaseUrl = 'http://localhost:8000';
  static const String _emulatorBaseUrl = 'http://10.0.2.2:8000'; // Android emulator
  static const String _prodBaseUrl = 'https://ml-api.neuroscreen.com'; // Production (set via env)

  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;

  final http.Client _httpClient;
  String? _customBaseUrl; // Allow custom configuration

  MLApiService({
    http.Client? httpClient,
    String? baseUrl,
  }) : _httpClient = httpClient ?? http.Client() {
    _customBaseUrl = baseUrl;
  }

  /// Get the base URL for the API
  /// Uses custom URL if set, otherwise uses configured environment URL
  String get baseUrl {
    if (_customBaseUrl != null) return _customBaseUrl!;
    return AppConfig().mlApiBaseUrl;
  }

  /// Set custom base URL (useful for testing or different environments)
  void setCustomBaseUrl(String url) {
    _customBaseUrl = url;
  }

  /// Reset to default base URL
  void resetBaseUrl() {
    _customBaseUrl = null;
  }

  /// Predict neurological risk based on test results
  ///
  /// Calls the ML backend /api/predictions/risk endpoint
  /// Uses ensemble ML models (97.78% accuracy)
  ///
  /// Returns: RiskPredictionResponse with risk score, level, and recommendations
  /// Throws: MLApiException on error
  Future<RiskPredictionResponse> predictRisk(
    List<TestResult> testResults, {
    bool includeConfidence = true,
    bool retryOnFailure = true,
  }) async {
    try {
      // Prepare request data
      final requestData = {
        'test_results': testResults.map((test) {
          return {
            'user_id': test.userId,
            'test_type': test.testType,
            'score': test.score,
            'timestamp': test.timestamp.toIso8601String(),
            'details': test.details,
          };
        }).toList(),
        'include_confidence': includeConfidence,
      };

      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/api/predictions/risk',
        body: requestData,
        timeout: _timeout,
      );

      final jsonResponse = jsonDecode(response);
      return RiskPredictionResponse.fromJson(jsonResponse);
    } on MLApiException {
      rethrow;
    } catch (e) {
      throw MLApiException(
        message: 'Failed to predict risk: ${e.toString()}',
        rawResponse: e.toString(),
      );
    }
  }

  /// Analyze trends in test results over time
  ///
  /// Calls the ML backend /api/analytics/trends endpoint
  /// Uses linear regression for trend detection
  ///
  /// Returns: TrendAnalysisResponse with direction, slope, and forecast
  /// Throws: MLApiException on error
  Future<TrendAnalysisResponse> analyzeTrends(
    List<double> scores, {
    int forecastPeriods = 10,
  }) async {
    try {
      final requestData = {
        'scores': scores,
        'forecast_periods': forecastPeriods,
      };

      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/api/analytics/trends',
        body: requestData,
        timeout: _timeout,
      );

      final jsonResponse = jsonDecode(response);
      return TrendAnalysisResponse.fromJson(jsonResponse);
    } on MLApiException {
      rethrow;
    } catch (e) {
      throw MLApiException(
        message: 'Failed to analyze trends: ${e.toString()}',
        rawResponse: e.toString(),
      );
    }
  }

  /// Detect anomalies in assessment patterns
  ///
  /// Calls the ML backend /api/analytics/anomalies endpoint
  /// Uses IsolationForest for anomaly detection
  ///
  /// Returns: Map with anomaly detection results
  /// Throws: MLApiException on error
  Future<Map<String, dynamic>> detectAnomalies(
    List<double> features,
  ) async {
    try {
      final requestData = {
        'features': features,
        'threshold': 0.05,
      };

      final response = await _makeRequest(
        method: 'POST',
        endpoint: '/api/analytics/anomalies',
        body: requestData,
        timeout: _timeout,
      );

      return jsonDecode(response);
    } on MLApiException {
      rethrow;
    } catch (e) {
      throw MLApiException(
        message: 'Failed to detect anomalies: ${e.toString()}',
        rawResponse: e.toString(),
      );
    }
  }

  /// Get model status and performance metrics
  ///
  /// Calls the ML backend /api/models/status endpoint
  ///
  /// Returns: Map with model information
  /// Throws: MLApiException on error
  Future<Map<String, dynamic>> getModelStatus() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/api/models/status',
        timeout: const Duration(seconds: 5),
      );

      return jsonDecode(response);
    } on MLApiException {
      rethrow;
    } catch (e) {
      throw MLApiException(
        message: 'Failed to get model status: ${e.toString()}',
        rawResponse: e.toString(),
      );
    }
  }

  /// Health check endpoint
  ///
  /// Calls the ML backend /health endpoint
  ///
  /// Returns: true if backend is healthy
  /// Throws: MLApiException on error
  Future<bool> healthCheck() async {
    try {
      final response = await _makeRequest(
        method: 'GET',
        endpoint: '/health',
        timeout: const Duration(seconds: 5),
      );

      final jsonResponse = jsonDecode(response);
      return jsonResponse['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }

  /// Internal method to make HTTP requests with retry logic
  Future<String> _makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    required Duration timeout,
    int retryCount = 0,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');

      late http.Response response;
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (method == 'GET') {
        response = await _httpClient.get(url, headers: headers).timeout(timeout);
      } else if (method == 'POST') {
        response = await _httpClient
            .post(
              url,
              headers: headers,
              body: jsonEncode(body ?? {}),
            )
            .timeout(timeout);
      } else {
        throw MLApiException(message: 'Unsupported HTTP method: $method');
      }

      // Check for success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }

      // Check for retryable errors (5xx, timeout)
      if ((response.statusCode >= 500 || response.statusCode == 408) &&
          retryCount < _maxRetries) {
        // Exponential backoff: 1s, 2s, 4s
        await Future.delayed(Duration(seconds: 1 << retryCount));
        return _makeRequest(
          method: method,
          endpoint: endpoint,
          body: body,
          timeout: timeout,
          retryCount: retryCount + 1,
        );
      }

      // Non-retryable error
      throw MLApiException(
        message: 'API request failed: ${response.statusCode}',
        statusCode: response.statusCode,
        rawResponse: response.body,
      );
    } on TimeoutException {
      // Retry on timeout
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: 1 << retryCount));
        return _makeRequest(
          method: method,
          endpoint: endpoint,
          body: body,
          timeout: timeout,
          retryCount: retryCount + 1,
        );
      }
      throw MLApiException(
        message: 'Request timeout after $_maxRetries retries',
      );
    } catch (e) {
      if (e is MLApiException) rethrow;
      throw MLApiException(
        message: 'Network error: ${e.toString()}',
        rawResponse: e.toString(),
      );
    }
  }

  /// Dispose HTTP client resources
  void dispose() {
    _httpClient.close();
  }
}
