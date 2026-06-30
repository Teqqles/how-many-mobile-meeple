@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import '../helpers/mock_api_client.dart';
import 'package:how_many_mobile_meeple/guided_flow/step1_select_source.dart';
import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestApp(AppModel model) {
  return ChangeNotifierProvider<AppModel>.value(
    value: model,
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: const Step1SelectSource(),
        ),
      ),
    ),
  );
}

Finder _findCrowns() => find.byWidgetPredicate(
    (w) => w is FaIcon && w.icon == FontAwesomeIcons.crown.data);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'tour_tip_seen_step1_tab_selector': true,
      'tour_tip_seen_step1_trending': true,
      'tour_tip_seen_step1_collection': true,
      'tour_tip_seen_step1_geeklist': true,
    });
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) async {});
    HttpRetryClient.setTestClient(mockApiClient());
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  group('Step1 Primary Player Crown', () {
    testWidgets('shows crown for collection items', (tester) async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();

      expect(_findCrowns(), findsOneWidget);
    });

    testWidgets('does not show crown for hotList items', (tester) async {
      final model = AppModel();
      await model.addItem(Item('trending', itemType: ItemType.hotList));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();

      expect(_findCrowns(), findsNothing);
    });

    testWidgets('does not show crown for geekList items', (tester) async {
      final model = AppModel();
      await model.addItem(Item('12345', itemType: ItemType.geekList));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();

      expect(_findCrowns(), findsNothing);
    });

    testWidgets('first collection item has gold crown by default',
        (tester) async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();

      final crownIcon = tester.widget<FaIcon>(_findCrowns());
      expect(crownIcon.color, Colors.amber);
    });

    testWidgets('second collection item has grey crown', (tester) async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));
      await model.addItem(Item('otheruser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();

      final crowns = tester.widgetList<FaIcon>(_findCrowns()).toList();

      expect(crowns.length, 2);
      expect(crowns[0].color, Colors.amber);
      expect(crowns[1].color, Colors.grey);
    });

    testWidgets('tapping grey crown makes it primary player', (tester) async {
      final model = AppModel();
      await model.addItem(Item('teqqles'));
      await model.addItem(Item('otheruser'));

      await tester.pumpWidget(_buildTestApp(model));
      await tester.pump();

      final crownButtons = _findCrowns();
      await tester.tap(crownButtons.last);
      await tester.pump();

      expect(model.primaryPlayer, 'otheruser');
    });
  });
}
