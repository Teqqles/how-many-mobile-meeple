import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Application configuration
///
/// For web builds, API URL is loaded from /config.json or /config.local.json
/// For mobile builds, uses compile-time constant with optional --dart-define override
///
/// Web configuration:
/// - Production: Deploy with config.json (https://api.howmanymeeple.com)
/// - Local dev: Use config.local.json (http://localhost:3000)
///
/// Mobile configuration:
/// - flutter run --dart-define=API_URL=http://192.168.1.100:3000
class AppConfig {
  // Cached configuration
  static String? _cachedApiUrl;
  static bool _isInitialized = false;

  // Compile-time defaults (used for mobile or as fallback)
  static const String _defaultApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.howmanymeeple.com',
  );

  // Common URLs for reference
  static const String mockApiUrl = "http://localhost:3000";
  static const String productionApiUrl = "https://api.howmanymeeple.com";

  /// Initialize configuration (call this at app startup for web)
  static Future<void> initialize() async {
    if (_isInitialized) return;

    if (kIsWeb) {
      await _loadWebConfig();
    } else {
      _cachedApiUrl = _defaultApiUrl;
    }

    _isInitialized = true;
  }

  /// Load configuration from web/config.json or web/config.local.json
  static Future<void> _loadWebConfig() async {
    try {
      // Try local config first (for development)
      var response = await http.get(Uri.parse('/config.local.json'));
      if (response.statusCode == 200) {
        final config = jsonDecode(response.body);
        _cachedApiUrl = config['apiUrl'] as String;
        return;
      }
    } catch (e) {
      // Local config not found, try production config
    }

    try {
      // Fall back to production config
      var response = await http.get(Uri.parse('/config.json'));
      if (response.statusCode == 200) {
        final config = jsonDecode(response.body);
        _cachedApiUrl = config['apiUrl'] as String;
        return;
      }
    } catch (e) {
      // Config file not found, use default
    }

    // Ultimate fallback
    _cachedApiUrl = productionApiUrl;
  }

  /// Get the active API URL (synchronous access after initialization)
  static String get apiUrl => _cachedApiUrl ?? _defaultApiUrl;

  /// Check if using mock API
  static bool get isMockApi =>
      apiUrl.contains('localhost') || apiUrl.contains('127.0.0.1');

  /// Get environment name
  static String get environment =>
      isMockApi ? 'Development (Mock)' : 'Production';

  /// Check if configuration is loaded
  static bool get isInitialized => _isInitialized;
}
