@Tags(['unit'])
library;

import 'package:go_router/go_router.dart';
import 'package:how_many_mobile_meeple/platform/router.dart' as r;
import 'package:test/test.dart';

void main() {
  final config = r.Router.router.configuration;

  RouteMatchList match(String location) =>
      config.findMatch(Uri.parse(location));

  group('GoRouter route matching', () {
    for (final location in <String>[
      '/',
      '/gameNight',
      '/gameNight/teqqles',
      '/gameNight/teqqles?gameNightLineup=822-243759-251661-223770',
      '/list',
      '/list/teqqles?maxPlayers=4',
      '/random',
      '/random/teqqles',
      '/settings',
      '/favourites',
      '/ignored',
      '/play-log',
      '/insights',
      '/about',
      '/help',
      '/help/home',
      '/shelf-of-shame',
      '/shelf-of-shame/testuser',
      '/shelf-of-shame/user%20name',
      '/game/174430',
      '/game/Wingspan/174430',
    ]) {
      test('matches $location', () {
        expect(match(location).isError, isFalse);
      });
    }

    test('game detail exposes the id path parameter', () {
      expect(match('/game/Wingspan/174430').pathParameters['id'], '174430');
      expect(match('/game/174430').pathParameters['id'], '174430');
    });

    test('shelf of shame exposes the user path parameter', () {
      expect(
        match('/shelf-of-shame/testuser').pathParameters['user'],
        'testuser',
      );
    });

    test(
      'an unknown path fails to match, falling back to the error builder',
      () {
        expect(match('/unknown/deep/path').isError, isTrue);
      },
    );
  });
}
