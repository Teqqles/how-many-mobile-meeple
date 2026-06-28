import 'package:flutter/material.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:test/test.dart';

void main() {
  group('Router.generateRoute', () {
    test('handles home route', () {
      final route = r.Router.generateRoute(RouteSettings(name: '/'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles list route', () {
      final route = r.Router.generateRoute(RouteSettings(name: '/list'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles random route', () {
      final route = r.Router.generateRoute(RouteSettings(name: '/random'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles settings route', () {
      final route = r.Router.generateRoute(RouteSettings(name: '/settings'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles route with nested path', () {
      final route =
          r.Router.generateRoute(RouteSettings(name: '/list/some/nested/path'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles unknown route with default', () {
      final route = r.Router.generateRoute(RouteSettings(name: '/unknown'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('extracts base route from nested path', () {
      final route =
          r.Router.generateRoute(RouteSettings(name: '/random/extra/path'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles shelf-of-shame route', () {
      final route =
          r.Router.generateRoute(RouteSettings(name: '/shelf-of-shame'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles shelf-of-shame route with username', () {
      final route = r.Router.generateRoute(
          RouteSettings(name: '/shelf-of-shame/testuser'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles shelf-of-shame route with encoded username', () {
      final route = r.Router.generateRoute(
          RouteSettings(name: '/shelf-of-shame/user%20name'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles game detail route with id', () {
      final route =
          r.Router.generateRoute(RouteSettings(name: '/game/Wingspan/174430'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles favourites route', () {
      final route = r.Router.generateRoute(RouteSettings(name: '/favourites'));
      expect(route, isA<MaterialPageRoute>());
    });

    test('handles ignored route', () {
      final route = r.Router.generateRoute(RouteSettings(name: '/ignored'));
      expect(route, isA<MaterialPageRoute>());
    });
  });
}
