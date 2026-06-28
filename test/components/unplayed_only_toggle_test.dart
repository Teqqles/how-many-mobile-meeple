import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/components/unplayed_only_toggle.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, AppModel model) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) async {});
    HttpRetryClient.setTestClient(
      http_testing.MockClient((request) async => http.Response('[]', 200)),
    );
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  group('UnplayedOnlyToggle card style', () {
    testWidgets('shows label and switch', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      await tester.pumpWidget(_wrap(const UnplayedOnlyToggle(), model));

      expect(find.text('Unplayed only'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('switch is disabled without primary player', (tester) async {
      final model = AppModel();
      await tester.pumpWidget(_wrap(const UnplayedOnlyToggle(), model));

      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.onChanged, isNull);
    });

    testWidgets('switch is enabled with primary player', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      await tester.pumpWidget(_wrap(const UnplayedOnlyToggle(), model));

      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.onChanged, isNotNull);
    });

    testWidgets('toggling updates model setting', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      await tester.pumpWidget(_wrap(const UnplayedOnlyToggle(), model));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final setting =
          model.settings.setting(Settings.filterShelfOfShameOnly.name);
      expect(setting.enabled, isTrue);
      expect(setting.getBool(), isTrue);
    });

    testWidgets('toggling off disables setting', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      final setting =
          model.settings.setting(Settings.filterShelfOfShameOnly.name);
      setting.value = true;
      setting.enabled = true;
      model.settings.updateSetting(setting);

      await tester.pumpWidget(_wrap(const UnplayedOnlyToggle(), model));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(setting.enabled, isFalse);
    });
  });

  group('UnplayedOnlyToggle compact style', () {
    testWidgets('shows compact label', (tester) async {
      final model = AppModel();
      await model.addItem(Item('testuser'));
      await tester.pumpWidget(_wrap(
        const UnplayedOnlyToggle(style: UnplayedToggleStyle.compact),
        model,
      ));

      expect(find.text('Unplayed Only (Shelf of Shame)'), findsOneWidget);
    });
  });
}
