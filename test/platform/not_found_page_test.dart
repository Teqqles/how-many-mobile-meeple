@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:how_many_mobile_meeple/platform/common/not_found_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/does-not-exist',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const Scaffold(body: Text('home')),
    ),
  ],
  errorBuilder: (_, state) => NotFoundPage(location: state.uri),
);

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'test',
      packageName: 'test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    ),
  );

  testWidgets('an unmatched route shows the not-found page', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    expect(find.textContaining("couldn't find that page"), findsOneWidget);
    expect(find.textContaining('/does-not-exist'), findsOneWidget);
  });

  testWidgets('the home button returns to the app', (tester) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: _router()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('not-found-home')));
    await tester.pumpAndSettle();

    expect(find.text('home'), findsOneWidget);
    expect(find.textContaining("couldn't find that page"), findsNothing);
  });
}
