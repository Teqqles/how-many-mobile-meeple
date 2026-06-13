import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/js.dart' as js;

class PwaInstallService {
  static const String _dismissedKey = 'pwa_banner_dismissed';

  static bool get isWeb => kIsWeb;

  static bool get isAlreadyInstalled {
    if (!isWeb) return false;
    try {
      final result = js.context.callMethod('isPwaAlreadyInstalled');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static bool get isInstallAvailable {
    if (!isWeb) return false;
    if (isAlreadyInstalled) return false;
    try {
      final result = js.context.callMethod('isPwaInstallAvailable');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> wasBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dismissedKey) ?? false;
  }

  static Future<void> markBannerDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  static void triggerInstall({void Function(bool accepted)? onResult}) {
    if (!isWeb) return;
    try {
      if (onResult != null) {
        js.context['_pwaInstallResultCallback'] =
            (bool accepted) => onResult(accepted);
      }
      js.context.callMethod('triggerPwaInstall');
    } catch (_) {}
  }

  static void onPromptReady(void Function() callback) {
    if (!isWeb) return;
    try {
      js.context['_pwaPromptReadyCallback'] = () => callback();
    } catch (_) {}
  }

  static void onInstalled(void Function() callback) {
    if (!isWeb) return;
    try {
      js.context['_pwaInstalledCallback'] = () => callback();
    } catch (_) {}
  }
}
