import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:how_many_mobile_meeple/app_page.dart';
import 'package:how_many_mobile_meeple/components/disclaimer_text.dart';
import 'package:how_many_mobile_meeple/components/feature_drawer.dart';
import 'package:how_many_mobile_meeple/components/insights_charts.dart';
import 'package:how_many_mobile_meeple/how_many_meeple_app_bar.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';
import 'package:how_many_mobile_meeple/model/model.dart';

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
      bottomNavigationBar: const AppFooter(),
      body: Consumer<AppModel>(
        builder: (context, model, child) {
          final analytics = model.collectionAnalytics;
          if (analytics == null || !analytics.hasData) {
            return _buildEmptyState(context);
          }
          return _buildDashboard(context, analytics);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 64, color: theme.colorScheme.secondary),
            const SizedBox(height: 16),
            Text('Insights are on their way',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Your collection dashboard will appear here once we\'ve '
              'analysed your games. Add a BGG collection in Step 1 if you '
              'haven\'t yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, CollectionAnalytics analytics) {
    final sections = <Widget>[];

    final summary = analytics.summary;
    if (summary != null) {
      sections.add(_Section(
        title: 'Overview',
        child: InsightsSummaryGrid(summary: summary),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sections,
    );
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
