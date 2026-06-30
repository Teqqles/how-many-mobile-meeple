@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/about_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      (MethodCall call) async {
        if (call.method == 'getAll') {
          return <String, dynamic>{
            'appName': 'How Many Meeple?',
            'packageName': 'com.test',
            'version': '2.11.4',
            'buildNumber': '28',
          };
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/package_info'),
      null,
    );
  });

  Widget buildApp() {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(800, 2400)),
        child: const AboutPage(),
      ),
    );
  }

  group('AboutPage', () {
    testWidgets('displays app bar, title, and version', (tester) async {
      tester.view.physicalSize = const Size(800, 8000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('How Many Meeple?'), findsOneWidget);
      expect(find.text('v2.11.4'), findsOneWidget);
      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Contributors'), findsOneWidget);
      expect(find.text('David Long'), findsOneWidget);
      expect(find.text('Source Code'), findsOneWidget);
      expect(find.text('Frontend (Flutter)'), findsOneWidget);
      expect(find.text('Backend API'), findsOneWidget);
    });
  });
}
