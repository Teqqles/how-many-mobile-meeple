@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/collection_insights/collection_insights_page.dart';
import 'package:how_many_mobile_meeple/components/disclaimer_text.dart';
import 'package:how_many_mobile_meeple/components/insights_charts.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/play_data.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/sync_mock_client.dart';

Widget _buildTestWidget(AppModel model) {
  return MaterialApp(
    home: ChangeNotifierProvider.value(
      value: model,
      child: const CollectionInsightsPage(),
    ),
  );
}

Map<String, dynamic> _fullBody() => {
      'summary': {
        'total_games': 113,
        'base_games': 85,
        'expansions': 28,
        'average_rating': 7.39,
        'median_rating': 7.42,
        'average_weight': 2.3,
      },
      'complexity_distribution': [
        {'label': 'light [0, 2.0)', 'count': 40},
        {'label': 'heavy [4.0+)', 'count': 2},
      ],
      'playtime_distribution': [
        {'label': 'filler [0, 30)', 'count': 14},
        {'label': 'short [30, 60)', 'count': 32},
      ],
      'player_count_coverage': [
        {'player_count': 2, 'best_or_recommended': 82, 'supported': 103},
        {'player_count': 4, 'best_or_recommended': 99, 'supported': 109},
      ],
      'top_mechanics': [
        {'name': 'Hand Management', 'count': 43},
        {'name': 'Dice Rolling', 'count': 38},
      ],
    };

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    HttpRetryClient.setDelayFunction((_) async {});
    HttpRetryClient.setTestClient(
        SyncMockClient((_) => http.Response('[]', 200)));
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
  });

  testWidgets('shows the title', (tester) async {
    final model = AppModel();
    await tester.pumpWidget(_buildTestWidget(model));
    expect(find.text('Collection Insights'), findsOneWidget);
  });

  testWidgets('shows a soft empty state when analytics are absent',
      (tester) async {
    final model = AppModel();
    await tester.pumpWidget(_buildTestWidget(model));

    expect(find.byType(HorizontalBarChart), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('once'), findsOneWidget);
  });

  testWidgets('renders the dashboard when analytics are present',
      (tester) async {
    final model = AppModel();
    model.setCollectionAnalyticsForTest(
        CollectionAnalytics.fromJson(_fullBody()));

    await tester.pumpWidget(_buildTestWidget(model));

    // Summary grid.
    expect(find.byType(InsightsSummaryGrid), findsOneWidget);
    expect(find.text('113'), findsOneWidget);
    // Section headings.
    expect(find.text('Complexity'), findsOneWidget);
    expect(find.text('Play Time'), findsOneWidget);
    // Chart content near the top.
    expect(find.text('light'), findsOneWidget);
    expect(find.text('filler'), findsOneWidget);

    // Sections further down the lazy list — scroll them into view.
    final listView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Player Counts'), 200,
        scrollable: listView);
    expect(find.byType(PlayerCoverageChart), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Top Mechanics'), 200,
        scrollable: listView);
    expect(find.text('Hand Management'), findsOneWidget);
  });

  testWidgets('includes BGG attribution', (tester) async {
    final model = AppModel();
    model.setCollectionAnalyticsForTest(
        CollectionAnalytics.fromJson(_fullBody()));

    await tester.pumpWidget(_buildTestWidget(model));

    await tester.scrollUntilVisible(find.byType(BGGAttribution), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byType(BGGAttribution), findsOneWidget);
  });

  testWidgets('renders play sections once plays have loaded', (tester) async {
    final model = AppModel();
    model.setCollectionAnalyticsForTest(
        CollectionAnalytics.fromJson(_fullBody()));
    model.setPlaysForTest(
      collectionGameIds: {1, 2, 3},
      playsData: {
        1: PlayData(gameId: 1, gameName: 'Gloomhaven', totalPlays: 5, plays: [
          BggPlay(playId: 1, date: DateTime(2026, 1, 1), length: 120),
        ]),
        2: PlayData(gameId: 2, gameName: 'Azul', totalPlays: 1, plays: [
          BggPlay(playId: 2, date: DateTime(2025, 1, 1), length: 30),
        ]),
      },
    );

    await tester.pumpWidget(_buildTestWidget(model));

    // Backlog donut lives in the Overview card near the top.
    expect(find.text('Played'), findsOneWidget);
    expect(find.text('Unplayed'), findsOneWidget);

    final listView = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(find.text('Most Played'), 200,
        scrollable: listView);
    expect(find.text('Gloomhaven'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Plays Per Year'), 200,
        scrollable: listView);
    expect(find.byType(PlaysPerYearChart), findsOneWidget);
    expect(find.text('From collection'), findsOneWidget);
  });

  testWidgets('re-renders when analytics arrive after the first build',
      (tester) async {
    final model = AppModel();
    await tester.pumpWidget(_buildTestWidget(model));

    expect(find.byType(InsightsSummaryGrid), findsNothing);

    model.setCollectionAnalyticsForTest(
        CollectionAnalytics.fromJson(_fullBody()));
    await tester.pump();

    expect(find.byType(InsightsSummaryGrid), findsOneWidget);
  });
}
