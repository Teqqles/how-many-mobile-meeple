@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/insights_charts.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 400, child: child),
      ),
    );

void main() {
  group('HorizontalBarChart', () {
    testWidgets('renders a labelled row with count for each datum',
        (tester) async {
      await tester.pumpWidget(_wrap(const HorizontalBarChart(data: [
        BarDatum(label: 'light', value: 40),
        BarDatum(label: 'heavy', value: 2),
      ])));

      expect(find.text('light'), findsOneWidget);
      expect(find.text('heavy'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('scales bar width by value against the maximum',
        (tester) async {
      await tester.pumpWidget(_wrap(const HorizontalBarChart(data: [
        BarDatum(label: 'a', value: 50),
        BarDatum(label: 'b', value: 25),
      ])));

      final bars = tester
          .widgetList<FractionallySizedBox>(
              find.byKey(const ValueKey('bar-fill')))
          .toList();
      expect(bars.length, 2);
      expect(bars[0].widthFactor, 1.0);
      expect(bars[1].widthFactor, 0.5);
    });

    testWidgets('all-zero data does not divide by zero', (tester) async {
      await tester.pumpWidget(_wrap(const HorizontalBarChart(data: [
        BarDatum(label: 'a', value: 0),
        BarDatum(label: 'b', value: 0),
      ])));

      final bars = tester
          .widgetList<FractionallySizedBox>(
              find.byKey(const ValueKey('bar-fill')))
          .toList();
      expect(bars.every((b) => b.widthFactor == 0.0), isTrue);
    });

    testWidgets('renders nothing when data is empty', (tester) async {
      await tester.pumpWidget(_wrap(const HorizontalBarChart(data: [])));
      expect(find.byType(FractionallySizedBox), findsNothing);
    });

    testWidgets('emphasises highlighted datum label', (tester) async {
      await tester.pumpWidget(_wrap(const HorizontalBarChart(data: [
        BarDatum(label: 'light', value: 40),
        BarDatum(label: 'heavy', value: 2, highlighted: true),
      ])));

      final heavy = tester.widget<Text>(find.text('heavy'));
      final light = tester.widget<Text>(find.text('light'));
      expect(heavy.style?.fontWeight, FontWeight.bold);
      expect(light.style?.fontWeight, isNot(FontWeight.bold));
    });
  });

  group('PlayerCoverageChart', () {
    List<PlayerCountCoverage> _coverage() => const [
          PlayerCountCoverage(2, 103, 82),
          PlayerCountCoverage(3, 108, 95),
          PlayerCountCoverage(4, 109, 99),
        ];

    testWidgets('renders a labelled row per player count', (tester) async {
      await tester
          .pumpWidget(_wrap(PlayerCoverageChart(coverage: _coverage())));

      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('overlays best bar over the supported bar per row',
        (tester) async {
      await tester
          .pumpWidget(_wrap(PlayerCoverageChart(coverage: _coverage())));

      final supported = tester
          .widgetList<FractionallySizedBox>(
              find.byKey(const ValueKey('coverage-supported')))
          .toList();
      final best = tester
          .widgetList<FractionallySizedBox>(
              find.byKey(const ValueKey('coverage-best')))
          .toList();
      expect(supported.length, 3);
      expect(best.length, 3);
      // Scaled against the maximum supported (109).
      expect(supported.last.widthFactor, 1.0);
      expect(best.first.widthFactor, closeTo(82 / 109, 0.001));
    });

    testWidgets('fills the supported region with a chevron pattern',
        (tester) async {
      await tester
          .pumpWidget(_wrap(PlayerCoverageChart(coverage: _coverage())));

      final supportedPaint = find.descendant(
        of: find.byKey(const ValueKey('coverage-supported')),
        matching: find.byType(CustomPaint),
      );
      expect(supportedPaint, findsWidgets);
    });

    testWidgets('renders nothing when coverage is empty', (tester) async {
      await tester.pumpWidget(_wrap(const PlayerCoverageChart(coverage: [])));
      expect(find.byType(FractionallySizedBox), findsNothing);
    });
  });

  group('InsightsSummaryGrid', () {
    testWidgets('shows a tile per present figure', (tester) async {
      await tester.pumpWidget(_wrap(const InsightsSummaryGrid(
        summary: CollectionSummary(
          totalGames: 113,
          baseGames: 85,
          expansions: 28,
          averageRating: 7.39,
          medianRating: 7.42,
          averageWeight: 2.3,
        ),
      )));

      expect(find.text('113'), findsOneWidget);
      expect(find.text('Games'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
      expect(find.text('7.4'), findsWidgets); // rounded ratings
      expect(find.text('2.3'), findsOneWidget);
    });

    testWidgets('omits tiles for absent figures', (tester) async {
      await tester.pumpWidget(_wrap(const InsightsSummaryGrid(
        summary: CollectionSummary(totalGames: 10),
      )));

      expect(find.text('10'), findsOneWidget);
      expect(find.text('Base Games'), findsNothing);
      expect(find.text('Avg Rating'), findsNothing);
    });
  });
}
