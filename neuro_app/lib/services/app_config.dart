/// Global application configuration
/// Manages API endpoints and environment settings
class AppConfig {
  static final AppConfig _instance = AppConfig._internal();

  late String _mlApiBaseUrl;
  bool _isConfigured = false;

  // Environment modes
  static const String ENV_DEVELOPMENT = 'development';
  static const String ENV_STAGING = 'staging';
  static const String ENV_PRODUCTION = 'production';

  AppConfig._internal() {
    // Default to development/localhost
    _mlApiBaseUrl = 'http://localhost:8000';
  }

  /// Get singleton instance
  factory AppConfig() {
    return _instance;
  }

  /// Initialize configuration for specific environment
  /// Call this early in app lifecycle (e.g., in main())
  static void initialize({
    required String environment,
    String? customMlApiUrl,
  }) {
    final config = AppConfig();

    // Set base URL based on environment or custom URL
    if (customMlApiUrl != null) {
      config._mlApiBaseUrl = customMlApiUrl;
      print('AppConfig: Using custom ML API URL: $customMlApiUrl');
    } else {
      switch (environment) {
        case ENV_DEVELOPMENT:
          config._mlApiBaseUrl = 'http://localhost:8000';
          print('AppConfig: Development mode - ML API: ${config._mlApiBaseUrl}');
          break;
        case ENV_STAGING:
          config._mlApiBaseUrl = 'https://ml-staging.neuroscreen.com';
          print('AppConfig: Staging mode - ML API: ${config._mlApiBaseUrl}');
          break;
        case ENV_PRODUCTION:
          config._mlApiBaseUrl = 'https://ml-api.neuroscreen.com';
          print('AppConfig: Production mode - ML API: ${config._mlApiBaseUrl}');
          break;
      }
    }

    config._isConfigured = true;
  }

  /// Get ML API base URL
  String get mlApiBaseUrl => _mlApiBaseUrl;

  /// Check if app is configured
  bool get isConfigured => _isConfigured;

  /// Set ML API URL manually (for runtime changes)
  void setMlApiUrl(String url) {
    _mlApiBaseUrl = url;
    print('AppConfig: ML API URL updated to: $url');
  }
}
