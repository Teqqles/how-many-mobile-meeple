import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';

/// A compact one-line summary of a collection distribution: each bucket shown
/// as "name count", with the bucket(s) matching the current filter selection
/// emphasised. Renders nothing when [buckets] is empty, so callers degrade
/// gracefully while analytics are unavailable.
class DistributionCountRow extends StatelessWidget {
  const DistributionCountRow({
    super.key,
    required this.buckets,
    required this.isActive,
  });

  final List<DistributionBucket> buckets;

  /// Whether a bucket overlaps the current filter selection.
  final bool Function(DistributionBucket) isActive;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final segments = <Widget>[];
    for (var i = 0; i < buckets.length; i++) {
      if (i > 0) {
        segments.add(
          Text(
            '·',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }
      final bucket = buckets[i];
      final active = isActive(bucket);
      segments.add(
        Text(
          '${bucket.name} ${bucket.count}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: segments,
    );
  }
}
