@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/distribution_count_row.dart';
import 'package:how_many_mobile_meeple/model/collection_analytics.dart';

const _buckets = [
  DistributionBucket(name: 'light', min: 0, max: 2.0, count: 40),
  DistributionBucket(name: 'medium', min: 2.0, max: 3.0, count: 23),
  DistributionBucket(name: 'heavy', min: 3.0, max: null, count: 2),
];

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders nothing when there are no buckets', (tester) async {
    await tester.pumpWidget(
      _app(DistributionCountRow(buckets: const [], isActive: (_) => false)),
    );

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('renders a segment per bucket with name and count', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(DistributionCountRow(buckets: _buckets, isActive: (_) => false)),
    );

    expect(find.text('light 40'), findsOneWidget);
    expect(find.text('medium 23'), findsOneWidget);
    expect(find.text('heavy 2'), findsOneWidget);
  });

  testWidgets('emphasises the active bucket and mutes the rest', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        DistributionCountRow(
          buckets: _buckets,
          isActive: (b) => b.name == 'medium',
        ),
      ),
    );

    final active = tester.widget<Text>(find.text('medium 23'));
    final inactive = tester.widget<Text>(find.text('light 40'));

    expect(active.style?.fontWeight, FontWeight.bold);
    expect(inactive.style?.fontWeight, isNot(FontWeight.bold));
  });
}
