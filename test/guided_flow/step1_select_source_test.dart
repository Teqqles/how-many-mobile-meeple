import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/guided_flow/step1_select_source.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:provider/provider.dart';

void main() {
  group('Step1SelectSource', () {
    testWidgets('Add Source button is disabled when text field is empty', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: model,
              child: const Step1SelectSource(),
            ),
          ),
        ),
      );

      // Find the Add Source button
      final addButton = find.widgetWithText(FilledButton, 'Add Source');
      expect(addButton, findsOneWidget);

      // Button should be disabled (onPressed is null)
      final FilledButton button = tester.widget(addButton);
      expect(button.onPressed, isNull);
    });

    testWidgets('Add Source button becomes enabled when text is entered', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: model,
              child: const Step1SelectSource(),
            ),
          ),
        ),
      );

      // Find the text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      // Enter some text
      await tester.enterText(textField, 'testuser');
      await tester.pump();

      // Find the Add Source button
      final addButton = find.widgetWithText(FilledButton, 'Add Source');
      expect(addButton, findsOneWidget);

      // Button should now be enabled (onPressed is not null)
      final FilledButton button = tester.widget(addButton);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Add Source button becomes disabled again when text is cleared', (WidgetTester tester) async {
      final model = AppModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: model,
              child: const Step1SelectSource(),
            ),
          ),
        ),
      );

      // Find the text field
      final textField = find.byType(TextField);

      // Enter text
      await tester.enterText(textField, 'testuser');
      await tester.pump();

      // Verify button is enabled
      FilledButton button = tester.widget(find.widgetWithText(FilledButton, 'Add Source'));
      expect(button.onPressed, isNotNull);

      // Clear the text
      await tester.enterText(textField, '');
      await tester.pump();

      // Button should be disabled again
      button = tester.widget(find.widgetWithText(FilledButton, 'Add Source'));
      expect(button.onPressed, isNull);
    });
  });
}
