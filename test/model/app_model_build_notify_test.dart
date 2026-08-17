@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_many_mobile_meeple/api/http_retry_client.dart';
import 'package:how_many_mobile_meeple/api/plays_service.dart';
import 'package:how_many_mobile_meeple/model/model.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_extractor.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/mock_api_client.dart';

AppModel _modelForFragment(String fragment) {
  final uri = Uri(fragment: fragment);
  return AppModel(urlExtractor: UrlFragmentExtractor(uri));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PlaysService.clearCache();
    HttpRetryClient.setDelayFunction((_) => Future.value());
    HttpRetryClient.setTestClient(mockApiClient());
  });

  tearDown(() {
    HttpRetryClient.resetTestClient();
    HttpRetryClient.resetDelayFunction();
    PlaysService.clearCache();
  });

  // The home pages call loadStoredData()/refreshFromUrl() from inside a
  // Consumer<AppModel> builder. When the URL encodes a model, applying it must
  // not fire notifyListeners() synchronously during that build - doing so
  // throws "setState() or markNeedsBuild() called during build".
  testWidgets(
    'consuming a URL model from inside build does not notify during build',
    (tester) async {
      final model = _modelForFragment('/random/%5Btrending%5D');

      await tester.pumpWidget(
        ChangeNotifierProvider<AppModel>.value(
          value: model,
          child: MaterialApp(
            home: Consumer<AppModel>(
              builder: (context, m, child) {
                if (!m.hasLoadedPersistedData) {
                  m.loadStoredData();
                  m.refreshFromUrl();
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No FlutterError was thrown, and the model still bootstrapped correctly.
      expect(tester.takeException(), isNull);
      expect(model.hasLoadedPersistedData, isTrue);
      expect(model.items.itemList.map((i) => i.name), contains('trending'));
    },
  );
}
