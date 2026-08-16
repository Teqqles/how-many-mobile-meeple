@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/app_choice_chip.dart';
import 'package:how_many_mobile_meeple/components/top_mechanic_chips_widget.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(AppModel model) => ChangeNotifierProvider<AppModel>.value(
      value: model,
      child: const MaterialApp(
        home: Scaffold(body: TopMechanicChipsWidget()),
      ),
    );

CollectionAnalytics _analyticsWith(List<Map<String, dynamic>> mechanics) =>
    CollectionAnalytics.fromJson({'top_mechanics': mechanics});

List<String> _selected(AppModel model) =>
    (model.settings.setting(Settings.filterMechanics.name).value as List)
        .cast<String>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders nothing when no analytics are available',
      (tester) async {
    final model = AppModel();
    addTearDown(model.dispose);

    await tester.pumpWidget(_app(model));
    await tester.pump();

    expect(find.byType(AppMechanicChip), findsNothing);
  });

  testWidgets('renders one chip per top mechanic, count-ordered',
      (tester) async {
    final model = AppModel();
    addTearDown(model.dispose);
    model.setCollectionAnalyticsForTest(_analyticsWith([
      {'name': 'Set Collection', 'count': 39},
      {'name': 'Hand Management', 'count': 43},
    ]));

    await tester.pumpWidget(_app(model));
    await tester.pump();

    final chips = tester
        .widgetList<AppMechanicChip>(find.byType(AppMechanicChip))
        .toList();
    expect(chips.map((c) => c.label).toList(),
        ['Hand Management', 'Set Collection']);
  });

  testWidgets('caps the number of chips shown', (tester) async {
    final model = AppModel();
    addTearDown(model.dispose);
    model.setCollectionAnalyticsForTest(_analyticsWith(
        List.generate(20, (i) => {'name': 'Mechanic $i', 'count': 100 - i})));

    await tester.pumpWidget(_app(model));
    await tester.pump();

    expect(find.byType(AppMechanicChip),
        findsNWidgets(TopMechanicChipsWidget.maxChips));
  });

  testWidgets('tapping a chip selects the mechanic and enables the filter',
      (tester) async {
    final model = AppModel();
    addTearDown(model.dispose);
    model.settings.setting(Settings.filterMechanics.name).enabled = false;
    model.setCollectionAnalyticsForTest(_analyticsWith([
      {'name': 'Hand Management', 'count': 43},
    ]));

    await tester.pumpWidget(_app(model));
    await tester.pump();

    await tester.tap(find.text('Hand Management'));
    await tester.pump();

    expect(_selected(model), contains('Hand Management'));
    expect(
        model.settings.setting(Settings.filterMechanics.name).enabled, isTrue);
  });

  testWidgets('tapping a selected chip deselects it', (tester) async {
    final model = AppModel();
    addTearDown(model.dispose);
    model.settings
        .setting(Settings.filterMechanics.name)
        .value
        .add('Hand Management');
    model.setCollectionAnalyticsForTest(_analyticsWith([
      {'name': 'Hand Management', 'count': 43},
    ]));

    await tester.pumpWidget(_app(model));
    await tester.pump();

    await tester.tap(find.text('Hand Management'));
    await tester.pump();

    expect(_selected(model), isNot(contains('Hand Management')));
  });
}
