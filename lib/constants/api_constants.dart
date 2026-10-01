class ApiConstants {
  ApiConstants._();

  /// Default Base URL for the CNG Pump backend API.
  /// Configured to the local backend server: http://192.168.1.8:5000
  /// Can be overridden at compile-time via `--dart-define=API_BASE_URL=http://...`
  static const String defaultBaseUrl = 'http://192.168.1.8:5000';

  static String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  /// Current active Base URL.
  static String get baseUrl => _baseUrl;

  /// Allows runtime reconfiguration of the base URL (e.g. from developer settings or environment switch).
  static void setBaseUrl(String url) {
    if (url.trim().isNotEmpty) {
      _baseUrl = url.trim().endsWith('/')
          ? url.trim().substring(0, url.trim().length - 1)
          : url.trim();
    }
  }

  /// Request timeout durations (10 seconds)
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Default headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
