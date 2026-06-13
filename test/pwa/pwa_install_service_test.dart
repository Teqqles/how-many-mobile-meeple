import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/pwa/pwa_install_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PwaInstallService persistence', () {
    test('wasBannerDismissed returns false when key has never been set',
        () async {
      expect(await PwaInstallService.wasBannerDismissed(), isFalse);
    });

    test('wasBannerDismissed returns true after markBannerDismissed', () async {
      await PwaInstallService.markBannerDismissed();
      expect(await PwaInstallService.wasBannerDismissed(), isTrue);
    });

    test('wasBannerDismissed returns true when key is pre-set', () async {
      SharedPreferences.setMockInitialValues({'pwa_banner_dismissed': true});
      expect(await PwaInstallService.wasBannerDismissed(), isTrue);
    });
  });

  group('PwaInstallService non-web guards', () {
    test('isWeb is false outside browser context', () {
      expect(PwaInstallService.isWeb, isFalse);
    });

    test('isAlreadyInstalled is false outside browser context', () {
      expect(PwaInstallService.isAlreadyInstalled, isFalse);
    });

    test('isInstallAvailable is false outside browser context', () {
      expect(PwaInstallService.isInstallAvailable, isFalse);
    });

    test('triggerInstall is a no-op outside browser context', () {
      expect(() => PwaInstallService.triggerInstall(), returnsNormally);
    });

    test('onPromptReady is a no-op outside browser context', () {
      expect(() => PwaInstallService.onPromptReady(() {}), returnsNormally);
    });
  });
}
