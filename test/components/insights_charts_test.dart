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

  group('MechanicChips', () {
    testWidgets('renders a chip with name and count per mechanic',
        (tester) async {
      await tester.pumpWidget(_wrap(const MechanicChips(data: [
        BarDatum(label: 'Hand Management', value: 43),
        BarDatum(label: 'Dice Rolling', value: 38),
      ])));

      expect(find.text('Hand Management'), findsOneWidget);
      expect(find.text('43'), findsOneWidget);
      expect(find.text('Dice Rolling'), findsOneWidget);
      expect(find.text('38'), findsOneWidget);
    });

    testWidgets('renders nothing when data is empty', (tester) async {
      await tester.pumpWidget(_wrap(const MechanicChips(data: [])));
      expect(find.byType(Wrap), findsNothing);
    });
  });

  group('PlaysPerYearChart', () {
    testWidgets('renders a labelled row and total per year', (tester) async {
      await tester.pumpWidget(_wrap(const PlaysPerYearChart(data: [
        YearPlaysDatum(label: '2025', total: 10, collection: 6),
        YearPlaysDatum(label: '2026', total: 4, collection: 4),
      ])));

      expect(find.text('2025'), findsOneWidget);
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('keys legend for collection and all plays', (tester) async {
      await tester.pumpWidget(_wrap(const PlaysPerYearChart(data: [
        YearPlaysDatum(label: '2026', total: 4, collection: 4),
      ])));

      expect(find.text('From collection'), findsOneWidget);
      expect(find.text('All plays'), findsOneWidget);
    });

    testWidgets('scales total and collection fills against the maximum',
        (tester) async {
      await tester.pumpWidget(_wrap(const PlaysPerYearChart(data: [
        YearPlaysDatum(label: '2025', total: 10, collection: 5),
      ])));

      final total = tester.widget<FractionallySizedBox>(
          find.byKey(const ValueKey('year-total-fill')));
      final collection = tester.widget<FractionallySizedBox>(
          find.byKey(const ValueKey('year-collection-fill')));
      expect(total.widthFactor, 1.0);
      expect(collection.widthFactor, 0.5);
    });

    testWidgets('renders nothing when data is empty', (tester) async {
      await tester.pumpWidget(_wrap(const PlaysPerYearChart(data: [])));
      expect(find.byKey(const ValueKey('year-total-fill')), findsNothing);
    });
  });

  group('PlayerCoverageChart', () {
    List<PlayerCountCoverage> _coverage() => const [
          PlayerCountCoverage(2, 103, 82),
          PlayerCountCoverage(3, 108, 95),
          PlayerCountCoverage(4, 109, 99),
        ];

    testWidgets('renders an axis label per player count', (tester) async {
      await tester
          .pumpWidget(_wrap(PlayerCoverageChart(coverage: _coverage())));

      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('labels every best and supported point', (tester) async {
      await tester
          .pumpWidget(_wrap(PlayerCoverageChart(coverage: _coverage())));

      // Best counts.
      expect(find.text('82'), findsOneWidget);
      expect(find.text('95'), findsOneWidget);
      expect(find.text('99'), findsOneWidget);
      // Supported counts.
      expect(find.text('103'), findsOneWidget);
      expect(find.text('108'), findsOneWidget);
      expect(find.text('109'), findsOneWidget);
    });

    testWidgets('draws the overlaid area', (tester) async {
      await tester
          .pumpWidget(_wrap(PlayerCoverageChart(coverage: _coverage())));

      expect(find.byKey(const ValueKey('coverage-area')), findsOneWidget);
    });

    testWidgets('renders nothing when coverage is empty', (tester) async {
      await tester.pumpWidget(_wrap(const PlayerCoverageChart(coverage: [])));
      expect(find.byKey(const ValueKey('coverage-area')), findsNothing);
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

    testWidgets('splits base vs expansions into a donut with legend',
        (tester) async {
      await tester.pumpWidget(_wrap(const InsightsSummaryGrid(
        summary: CollectionSummary(
          totalGames: 113,
          baseGames: 85,
          expansions: 28,
        ),
      )));

      // Total in the donut centre, split in the legend.
      expect(find.text('113'), findsOneWidget);
      expect(find.text('Base'), findsOneWidget);
      expect(find.text('85'), findsOneWidget);
      expect(find.text('Expansions'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);
    });

    testWidgets('appends a played/unplayed backlog donut when provided',
        (tester) async {
      await tester.pumpWidget(_wrap(const InsightsSummaryGrid(
        summary: CollectionSummary(totalGames: 113),
        backlogPlayed: 63,
        backlogUnplayed: 50,
        backlogTotal: 113,
      )));

      expect(find.text('Played'), findsOneWidget);
      expect(find.text('Unplayed'), findsOneWidget);
      expect(find.text('63'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
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
