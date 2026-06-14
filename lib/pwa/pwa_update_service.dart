import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class PwaUpdateService {
  static final StreamController<bool> _updateController =
      StreamController<bool>.broadcast();

  static Stream<bool> get updateAvailable => _updateController.stream;

  static bool get isWeb => kIsWeb;

  static void start() {
    if (!isWeb) return;
    _check();
  }

  static Future<void> _check() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final running = packageInfo.version;

      final response = await http
          .get(Uri.parse(
              '/version.json?_=${DateTime.now().millisecondsSinceEpoch}'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final deployed = data['version'] as String?;

      if (deployed != null && deployed != running) {
        _updateController.add(true);
      }
    } catch (_) {
      // Network errors are expected — silently ignore
    }
  }
}
