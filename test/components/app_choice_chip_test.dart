import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/components/app_choice_chip.dart';

Widget _wrapWidget(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('AppChoiceChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrapWidget(
        AppChoiceChip(
          label: 'Test',
          selected: false,
          onSelected: (_) {},
        ),
      ));

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('calls onSelected when tapped', (tester) async {
      bool? selectedValue;
      await tester.pumpWidget(_wrapWidget(
        AppChoiceChip(
          label: 'Test',
          selected: false,
          onSelected: (value) => selectedValue = value,
        ),
      ));

      await tester.tap(find.text('Test'));
      expect(selectedValue, isTrue);
    });

    testWidgets('does not show checkmark', (tester) async {
      await tester.pumpWidget(_wrapWidget(
        AppChoiceChip(
          label: 'Test',
          selected: true,
          onSelected: (_) {},
        ),
      ));

      final chip = tester.widget<ChoiceChip>(find.byType(ChoiceChip));
      expect(chip.showCheckmark, isFalse);
    });

    testWidgets('renders avatar when provided', (tester) async {
      await tester.pumpWidget(_wrapWidget(
        AppChoiceChip(
          label: 'Test',
          selected: false,
          onSelected: (_) {},
          avatar: const Icon(Icons.people),
        ),
      ));

      expect(find.byIcon(Icons.people), findsOneWidget);
    });
  });

  group('AppFilterChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrapWidget(
        AppFilterChip(
          label: 'Filter',
          selected: false,
          onSelected: (_) {},
        ),
      ));

      expect(find.text('Filter'), findsOneWidget);
    });

    testWidgets('calls onSelected when tapped', (tester) async {
      bool? selectedValue;
      await tester.pumpWidget(_wrapWidget(
        AppFilterChip(
          label: 'Filter',
          selected: false,
          onSelected: (value) => selectedValue = value,
        ),
      ));

      await tester.tap(find.text('Filter'));
      expect(selectedValue, isTrue);
    });
  });

  group('AppMechanicChip', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(_wrapWidget(
        AppMechanicChip(
          label: 'Deck Building',
          selected: false,
          onSelected: (_) {},
        ),
      ));

      expect(find.text('Deck Building'), findsOneWidget);
    });

    testWidgets('respects enabled state', (tester) async {
      bool? called;
      await tester.pumpWidget(_wrapWidget(
        AppMechanicChip(
          label: 'Deck Building',
          selected: false,
          enabled: false,
          onSelected: (value) => called = value,
        ),
      ));

      await tester.tap(find.text('Deck Building'));
      expect(called, isNull);
    });

    testWidgets('calls onSelected when enabled and tapped', (tester) async {
      bool? selectedValue;
      await tester.pumpWidget(_wrapWidget(
        AppMechanicChip(
          label: 'Deck Building',
          selected: false,
          enabled: true,
          onSelected: (value) => selectedValue = value,
        ),
      ));

      await tester.tap(find.text('Deck Building'));
      expect(selectedValue, isTrue);
    });
  });
}
