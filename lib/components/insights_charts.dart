import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';

/// One bar in a [HorizontalBarChart]: a [label], its [value], and whether it
/// should be visually emphasised.
class BarDatum {
  final String label;
  final int value;
  final bool highlighted;
  const BarDatum(
      {required this.label, required this.value, this.highlighted = false});
}

/// A simple horizontal bar chart: label on the left, a bar whose length is
/// proportional to the largest value, and the count at the end. Renders
/// nothing for empty data so callers degrade gracefully.
class HorizontalBarChart extends StatelessWidget {
  const HorizontalBarChart({super.key, required this.data});

  final List<BarDatum> data;

  static const double _labelWidth = 96;
  static const double _valueWidth = 32;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final maxValue =
        data.map((d) => d.value).fold<int>(0, (a, b) => b > a ? b : a);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final datum in data)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text(
                    datum.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: datum.highlighted
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: datum.highlighted
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: _Track(
                    child: FractionallySizedBox(
                      key: const ValueKey('bar-fill'),
                      alignment: Alignment.centerLeft,
                      widthFactor: maxValue == 0 ? 0.0 : datum.value / maxValue,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: datum.highlighted
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary
                                  .withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _valueWidth,
                  child: Text(
                    '${datum.value}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: datum.highlighted
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A player-count coverage chart. Each row draws the faint full-width
/// `supported` count with the solid `best/recommended` count overlaid, both
/// scaled against the largest supported count. Empty coverage renders nothing.
class PlayerCoverageChart extends StatelessWidget {
  const PlayerCoverageChart({super.key, required this.coverage});

  final List<PlayerCountCoverage> coverage;

  static const double _labelWidth = 24;
  static const double _valueWidth = 40;

  @override
  Widget build(BuildContext context) {
    if (coverage.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final maxSupported =
        coverage.map((c) => c.supported).fold<int>(0, (a, b) => b > a ? b : a);

    double factor(int value) => maxSupported == 0 ? 0.0 : value / maxSupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in coverage)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text(
                    '${c.playerCount}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: _Track(
                    child: Stack(
                      children: [
                        FractionallySizedBox(
                          key: const ValueKey('coverage-supported'),
                          alignment: Alignment.centerLeft,
                          widthFactor: factor(c.supported),
                          child: CustomPaint(
                            size: const Size.fromHeight(14),
                            painter: _ChevronPainter(
                              theme.colorScheme.primary.withValues(alpha: 0.45),
                            ),
                            child: const SizedBox(height: 14),
                          ),
                        ),
                        FractionallySizedBox(
                          key: const ValueKey('coverage-best'),
                          alignment: Alignment.centerLeft,
                          widthFactor: factor(c.bestOrRecommended),
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: _valueWidth,
                  child: Text(
                    '${c.bestOrRecommended}/${c.supported}',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A grid of headline stat tiles for a [CollectionSummary]. Only figures that
/// are present get a tile.
class InsightsSummaryGrid extends StatelessWidget {
  const InsightsSummaryGrid({super.key, required this.summary});

  final CollectionSummary summary;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (summary.totalGames != null)
        _StatTile(label: 'Games', value: '${summary.totalGames}'),
      if (summary.baseGames != null)
        _StatTile(label: 'Base Games', value: '${summary.baseGames}'),
      if (summary.expansions != null)
        _StatTile(label: 'Expansions', value: '${summary.expansions}'),
      if (summary.averageRating != null)
        _StatTile(
            label: 'Avg Rating',
            value: summary.averageRating!.toStringAsFixed(1)),
      if (summary.medianRating != null)
        _StatTile(
            label: 'Median Rating',
            value: summary.medianRating!.toStringAsFixed(1)),
      if (summary.averageWeight != null)
        _StatTile(
            label: 'Avg Weight',
            value: summary.averageWeight!.toStringAsFixed(1)),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: tiles,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a repeating chevron pattern across the given size, used to fill the
/// `supported` region so the gap beyond `best/recommended` reads at a glance.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  static const double _spacing = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    final h = size.height;
    for (double x = -h; x < size.width + h; x += _spacing) {
      final path = Path()
        ..moveTo(x, h)
        ..lineTo(x + h / 2, 0)
        ..lineTo(x + h, h);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter old) => old.color != color;
}

/// The faint rounded track a bar sits in.
class _Track extends StatelessWidget {
  const _Track({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 14,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
