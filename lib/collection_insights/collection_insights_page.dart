import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/app_page.dart';
import 'package:how_many_mobile_meeple/components/disclaimer_text.dart';
import 'package:how_many_mobile_meeple/components/feature_drawer.dart';
import 'package:how_many_mobile_meeple/components/insights_charts.dart';
import 'package:how_many_mobile_meeple/components/list_empty_state.dart';
import 'package:how_many_mobile_meeple/components/plays_loading_indicator.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/model/play_insights.dart';

/// A dashboard summarising the primary player's collection from the analytics
/// endpoint. Reads [AppModel.collectionAnalytics] reactively and degrades to a
/// soft empty state — no error, no blocking spinner — until data arrives.
class CollectionInsightsPage extends StatefulWidget {
  const CollectionInsightsPage({super.key});

  @override
  State<CollectionInsightsPage> createState() => _CollectionInsightsPageState();
}

class _CollectionInsightsPageState extends State<CollectionInsightsPage>
    with AppPage {
  @override
  void initState() {
    super.initState();
    // Analytics are owned by the model (with retry). Kick the load in case the
    // user deep-linked straight here; idempotent when already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppModel.of(context, listen: false).loadPlays();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HowManyMeepleAppBar('Collection Insights',
          context: context, helpSection: 'collection-insights'),
      drawer: const FeatureDrawer(),
      endDrawer: pageDrawer(context),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [PlaysLoadingIndicator(), AppFooter()],
      ),
      body: Consumer<AppModel>(
        builder: (context, model, child) {
          final analytics = model.collectionAnalytics;
          if (analytics == null || !analytics.hasData) {
            return _buildEmptyState(context);
          }
          return _buildDashboard(context, model, analytics);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const ListEmptyState(
      icon: Icons.insights,
      title: 'Insights are on their way',
      description: 'Your collection dashboard will appear here once we\'ve '
          'analysed your games. Add a BGG collection in Step 1 if you '
          'haven\'t yet.',
    );
  }

  Widget _buildDashboard(
      BuildContext context, AppModel model, CollectionAnalytics analytics) {
    final sections = <Widget>[];

    final stats = (model.playsLoaded && model.collectionGameIds.isNotEmpty)
        ? PlayInsights.from(
            collectionGameIds: model.collectionGameIds,
            playsData: model.playsData,
            playCount: model.getPlayCount,
            now: DateTime.now(),
          )
        : null;

    final summary = analytics.summary;
    if (summary != null) {
      sections.add(_Section(
        title: 'Overview',
        child: InsightsSummaryGrid(
          summary: summary,
          backlogPlayed: stats?.playedGames,
          backlogUnplayed: stats?.unplayedGames,
          backlogTotal: stats?.totalGames,
        ),
      ));
    } else if (stats != null) {
      // No summary block, but plays loaded: still surface the backlog donut.
      sections.add(_Section(
        title: 'Overview',
        child: SplitDonut(
          primaryValue: stats.playedGames,
          primaryLabel: 'Played',
          secondaryValue: stats.unplayedGames,
          secondaryLabel: 'Unplayed',
          total: stats.totalGames,
          centerLabel: 'Backlog',
        ),
      ));
    }

    if (analytics.complexityDistribution.isNotEmpty) {
      sections.add(_Section(
        title: 'Complexity',
        child: HorizontalBarChart(
          data: _bucketData(analytics.complexityDistribution),
        ),
      ));
    }

    if (analytics.playtimeDistribution.isNotEmpty) {
      sections.add(_Section(
        title: 'Play Time',
        child: HorizontalBarChart(
          data: _bucketData(analytics.playtimeDistribution),
        ),
      ));
    }

    if (analytics.playerCountCoverage.isNotEmpty) {
      sections.add(_Section(
        title: 'Player Counts',
        subtitle: 'Best/recommended (solid) within supported (shaded), '
            'by player count',
        child: PlayerCoverageChart(coverage: analytics.playerCountCoverage),
      ));
    }

    if (analytics.topMechanics.isNotEmpty) {
      sections.add(_Section(
        title: 'Top Mechanics',
        child: MechanicChips(
          data: [
            for (final m in analytics.topMechanics)
              BarDatum(label: m.name, value: m.count),
          ],
        ),
      ));
    }

    if (stats != null) _addPlaySections(context, stats, sections);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sections,
    );
  }

  /// Appends play-derived sections. Each subsection is guarded by its own
  /// emptiness so a collection with no recorded plays degrades quietly.
  void _addPlaySections(
      BuildContext context, PlayInsights stats, List<Widget> sections) {
    if (stats.hasPlays) {
      sections.add(_Section(
        title: 'Play Activity',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatTile(label: 'Total Plays', value: '${stats.totalPlays}'),
            if (stats.totalMinutes > 0)
              StatTile(
                  label: 'Hours Played',
                  value: '${(stats.totalMinutes / 60).round()}'),
            StatTile(
                label: 'Played this Year', value: '${stats.playsThisYear}'),
            StatTile(label: 'Played Once', value: '${stats.playedOnce}'),
            StatTile(label: 'Repeated', value: '${stats.playedRepeatedly}'),
          ],
        ),
      ));
    }

    if (stats.mostPlayed.isNotEmpty) {
      sections.add(_Section(
        title: 'Most Played',
        child: MechanicChips(
          data: [
            for (final m in stats.mostPlayed)
              BarDatum(label: m.name, value: m.plays),
          ],
        ),
      ));
    }

    if (stats.playsPerYear.isNotEmpty) {
      sections.add(_Section(
        title: 'Plays Per Year',
        child: PlaysPerYearChart(
          data: [
            for (final y in stats.playsPerYear)
              YearPlaysDatum(
                label: '${y.year}',
                total: y.plays,
                collection: y.collectionPlays,
              ),
          ],
        ),
      ));
    }
  }

  List<BarDatum> _bucketData(List<DistributionBucket> buckets) => [
        for (final b in buckets) BarDatum(label: b.name, value: b.count),
      ];
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
