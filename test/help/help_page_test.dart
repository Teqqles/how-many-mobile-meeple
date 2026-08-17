@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/help/help_content.dart';
import 'package:how_many_mobile_meeple/help/help_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HelpContent', () {
    test('every section has a unique id and at least one item', () {
      final ids = <String>{};
      for (final section in HelpContent.sections) {
        expect(
          ids.add(section.id),
          isTrue,
          reason: 'duplicate section id ${section.id}',
        );
        expect(section.items, isNotEmpty);
      }
    });

    test('forId returns the matching section, or null for unknown ids', () {
      expect(HelpContent.forId(HelpContent.list)?.id, HelpContent.list);
      expect(HelpContent.forId('does-not-exist'), isNull);
      expect(HelpContent.forId(null), isNull);
    });
  });

  group('HelpPage', () {
    testWidgets('renders the first section and can scroll to later ones', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const HelpPage()));
      await tester.pumpAndSettle();

      // The first section is visible on load.
      expect(find.text(HelpContent.sections.first.title), findsOneWidget);

      // A later section builds once scrolled into view.
      final lastTitle = HelpContent.sections.last.title;
      await tester.scrollUntilVisible(find.text(lastTitle), 400);
      expect(find.text(lastTitle), findsOneWidget);
    });

    testWidgets('highlights the initial section then clears it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const HelpPage(initialSectionId: HelpContent.home)),
      );

      // Let the post-frame scroll + highlight fire.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      bool anyHighlighted() => tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .any((c) {
            final border = (c.decoration as BoxDecoration).border as Border;
            return border.top.color != Colors.transparent;
          });

      expect(anyHighlighted(), isTrue);

      // Highlight clears itself after the delay.
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
      expect(anyHighlighted(), isFalse);
    });

    testWidgets('unknown initial section id does not throw', (tester) async {
      await tester.pumpWidget(_wrap(const HelpPage(initialSectionId: 'nope')));
      await tester.pumpAndSettle();

      expect(find.byType(HelpPage), findsOneWidget);
    });
  });
}
