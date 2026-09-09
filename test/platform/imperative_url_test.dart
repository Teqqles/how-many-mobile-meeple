@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;

// Pages opened with context.push must show up in the browser URL. go_router
// only does this when optionURLReflectsImperativeAPIs is on, which the app's
// Router enables on construction.
void main() {
  test('building the app router enables URL reflection for pushes', () {
    // ignore: unnecessary_statements
    r.Router.router;
    expect(GoRouter.optionURLReflectsImperativeAPIs, isTrue);
  });

  testWidgets('a pushed route is reflected in the browser URL', (tester) async {
    // ignore: unnecessary_statements
    r.Router.router;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: '/second',
          builder: (_, _) => const Scaffold(body: Text('second')),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.push('/second');
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.toString(), '/second');
    expect(find.text('second'), findsOneWidget);
  });
}
