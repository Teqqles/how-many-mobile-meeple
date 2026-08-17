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
                          color: theme.colorScheme.primary,
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

/// The top mechanics rendered as count-badged chips rather than a chart — a
/// flat ranked list of labels reads better as chips than as bars. Renders
/// nothing for empty data so callers degrade gracefully.
class MechanicChips extends StatelessWidget {
  const MechanicChips({super.key, required this.data});

  final List<BarDatum> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final datum in data)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  datum.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${datum.value}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
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

/// A player-count coverage chart drawn as two overlaid area sweeps: the faint
/// `supported` envelope with the solid `best/recommended` area on top, plotted
/// across player counts so the shape of the collection's sweet spot reads at a
/// glance. Empty coverage renders nothing so callers degrade gracefully.
class PlayerCoverageChart extends StatelessWidget {
  const PlayerCoverageChart({super.key, required this.coverage});

  final List<PlayerCountCoverage> coverage;

  static const double _chartHeight = 130;
  static const double _labelStripHeight = 20;
  static const double _padX = 14;
  static const double _padTop = 18;

  @override
  Widget build(BuildContext context) {
    if (coverage.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final maxSupported =
        coverage.map((c) => c.supported).fold<int>(0, (a, b) => b > a ? b : a);
    final n = coverage.length;

    double yFor(int value) => maxSupported == 0
        ? _chartHeight
        : _chartHeight - (value / maxSupported) * (_chartHeight - _padTop);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        double xFor(int i) =>
            n == 1 ? w / 2 : _padX + i * (w - 2 * _padX) / (n - 1);

        final supportedPts = <Offset>[
          for (var i = 0; i < n; i++)
            Offset(xFor(i), yFor(coverage[i].supported)),
        ];
        final bestPts = <Offset>[
          for (var i = 0; i < n; i++)
            Offset(xFor(i), yFor(coverage[i].bestOrRecommended)),
        ];

        return SizedBox(
          height: _chartHeight + _labelStripHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: _chartHeight,
                child: CustomPaint(
                  key: const ValueKey('coverage-area'),
                  painter: _CoverageAreaPainter(
                    supported: supportedPts,
                    best: bestPts,
                    baseline: _chartHeight,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              // Supported count above each supported point.
              for (var i = 0; i < n; i++)
                Positioned(
                  left: xFor(i) - 20,
                  width: 40,
                  top: supportedPts[i].dy - 16,
                  child: Center(
                    child: Text(
                      '${coverage[i].supported}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              // Best count just above each best point.
              for (var i = 0; i < n; i++)
                Positioned(
                  left: xFor(i) - 20,
                  width: 40,
                  top: bestPts[i].dy - 16,
                  child: Center(
                    child: Text(
                      '${coverage[i].bestOrRecommended}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Player-count axis labels.
              for (var i = 0; i < n; i++)
                Positioned(
                  left: xFor(i) - 20,
                  width: 40,
                  top: _chartHeight,
                  child: Center(
                    child: Text(
                      '${coverage[i].playerCount}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Paints the two overlaid coverage areas: a faint `supported` envelope and a
/// solid `best/recommended` area, each filled to [baseline] with a stroked top
/// edge and point markers.
class _CoverageAreaPainter extends CustomPainter {
  const _CoverageAreaPainter({
    required this.supported,
    required this.best,
    required this.baseline,
    required this.color,
  });

  final List<Offset> supported;
  final List<Offset> best;
  final double baseline;
  final Color color;

  void _drawArea(
    Canvas canvas,
    List<Offset> pts,
    double fillAlpha,
    double strokeAlpha,
    double dotRadius,
  ) {
    if (pts.isEmpty) return;
    final area = Path()..moveTo(pts.first.dx, baseline);
    for (final p in pts) {
      area.lineTo(p.dx, p.dy);
    }
    area.lineTo(pts.last.dx, baseline);
    area.close();
    canvas.drawPath(area, Paint()..color = color.withValues(alpha: fillAlpha));

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = color.withValues(alpha: strokeAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = color.withValues(alpha: strokeAlpha);
    for (final p in pts) {
      canvas.drawCircle(p, dotRadius, dot);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _drawArea(canvas, supported, 0.16, 0.45, 2);
    _drawArea(canvas, best, 0.55, 1.0, 3);
  }

  @override
  bool shouldRepaint(covariant _CoverageAreaPainter old) =>
      old.supported != supported ||
      old.best != best ||
      old.baseline != baseline ||
      old.color != color;
}

/// A grid of headline stat tiles for a [CollectionSummary]. Only figures that
/// are present get a tile.
class InsightsSummaryGrid extends StatelessWidget {
  const InsightsSummaryGrid({super.key, required this.summary});

  final CollectionSummary summary;

  @override
  Widget build(BuildContext context) {
    // A base-vs-expansions split is a part-of-whole relationship, so it reads
    // better as a donut than as two separate tiles.
    final hasSplit = summary.baseGames != null && summary.expansions != null;

    final children = <Widget>[
      if (hasSplit)
        _SplitDonut(
          base: summary.baseGames!,
          expansions: summary.expansions!,
          total:
              summary.totalGames ?? (summary.baseGames! + summary.expansions!),
        )
      else if (summary.totalGames != null)
        _StatTile(label: 'Games', value: '${summary.totalGames}'),
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
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

/// A donut splitting the collection into base games and expansions, with the
/// total in the centre and a colour-keyed legend alongside.
class _SplitDonut extends StatelessWidget {
  const _SplitDonut({
    required this.base,
    required this.expansions,
    required this.total,
  });

  final int base;
  final int expansions;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.primary;
    final expansionColor = theme.colorScheme.tertiary;
    final denom = base + expansions;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: CustomPaint(
            painter: _DonutPainter(
              baseFraction: denom == 0 ? 0.0 : base / denom,
              baseColor: baseColor,
              expansionColor: expansionColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Games',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendRow(color: baseColor, label: 'Base', value: '$base'),
            const SizedBox(height: 6),
            _LegendRow(
                color: expansionColor,
                label: 'Expansions',
                value: '$expansions'),
          ],
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow(
      {required this.color, required this.label, required this.value});

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(width: 6),
        Text(
          value,
          style:
              theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Paints a two-segment donut ring: [baseFraction] of the ring in
/// [baseColor], the remainder in [expansionColor].
class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.baseFraction,
    required this.baseColor,
    required this.expansionColor,
  });

  final double baseFraction;
  final Color baseColor;
  final Color expansionColor;

  static const double _stroke = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _stroke / 2,
      _stroke / 2,
      size.width - _stroke,
      size.height - _stroke,
    );
    const start = -1.5707963267948966; // -90 degrees, start at top.
    final baseSweep = 6.283185307179586 * baseFraction;

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    final expansionPaint = Paint()
      ..color = expansionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    // Expansion segment first (full remainder), base drawn over its arc.
    canvas.drawArc(rect, start + baseSweep, 6.283185307179586 - baseSweep,
        false, expansionPaint);
    canvas.drawArc(rect, start, baseSweep, false, basePaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.baseFraction != baseFraction ||
      old.baseColor != baseColor ||
      old.expansionColor != expansionColor;
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

/// The rounded track a bar sits in. A tinted fill and hairline border keep it
/// distinct from the card background so the bars read clearly.
class _Track extends StatelessWidget {
  const _Track({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 14,
      decoration: BoxDecoration(
        // Shaded primary tint (matching the coverage graph's supported area)
        // rather than a light neutral, so the unfilled portion reads clearly.
        color: theme.colorScheme.primary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
