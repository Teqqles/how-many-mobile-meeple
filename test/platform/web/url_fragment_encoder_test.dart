@Tags(['unit'])
library;

import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_encoder.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'url_fragment_encoder_test.mocks.dart';

@GenerateMocks([Items, Settings])
main() {
  var expectedName = '/pagename';
  group('encode', () {
    test('returns name when only a name given', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();
      when(mockItems.itemList).thenReturn([]);
      when(mockSettings.changedSettings).thenReturn({});
      var encodedName = UrlFragmentEncoder.encode(expectedName,
          items: mockItems, settings: mockSettings);
      expect(encodedName, expectedName);
    });

    test('returns name when empty items given', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([]);
      when(mockSettings.changedSettings).thenReturn({});
      var encodedName = UrlFragmentEncoder.encode(expectedName,
          items: mockItems, settings: mockSettings);
      expect(encodedName, expectedName);
    });

    test('returns name and single item', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([Item('test')]);
      when(mockSettings.changedSettings).thenReturn({});
      var expectedEncodedName = expectedName + '/test';
      var encodedName = UrlFragmentEncoder.encode(expectedName,
          items: mockItems, settings: mockSettings);
      expect(encodedName, expectedEncodedName);
    });

    test('returns name and plus separated items', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([Item('test'), Item('test2')]);
      when(mockSettings.changedSettings).thenReturn({});
      var expectedEncodedName = expectedName + '/test+test2';
      var encodedName = UrlFragmentEncoder.encode(expectedName,
          items: mockItems, settings: mockSettings);
      expect(encodedName, expectedEncodedName);
    });

    test('returns name when empty settings given', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([]);
      when(mockSettings.changedSettings).thenReturn({});
      var encodedName = UrlFragmentEncoder.encode(expectedName,
          items: mockItems, settings: mockSettings);
      expect(encodedName, expectedName);
    });

    test('returns name, item and setting', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([Item('test')]);
      when(mockSettings.changedSettings)
          .thenReturn({'test': Setting('setting', value: 'value')});
      var expectedEncodedName = expectedName + '/test?setting=value';
      var encodedName = UrlFragmentEncoder.encode(expectedName,
          items: mockItems, settings: mockSettings);
      expect(encodedName, expectedEncodedName);
    });

    test('returns name, item and settings with correct separation', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([Item('test')]);
      when(mockSettings.changedSettings).thenReturn({
        'test': Setting('setting', value: 'value'),
        'test2': Setting('setting2', value: 'value2')
      });
      var expectedEncodedName =
          expectedName + '/test?setting=value&setting2=value2';
      var encodedName = UrlFragmentEncoder.encode(expectedName,
          items: mockItems, settings: mockSettings);
      expect(encodedName, expectedEncodedName);
    });

    test('encodes geeklist item by name', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([Item('12345')]);
      when(mockSettings.changedSettings).thenReturn({});
      var expectedEncodedName = expectedName + '/12345';
      var encodedName = UrlFragmentEncoder.encode(expectedName,
          items: mockItems, settings: mockSettings);
      expect(encodedName, expectedEncodedName);
    });

    test('encodes mixed geeklist and collection items separated by plus', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([Item('testuser'), Item('12345')]);
      when(mockSettings.changedSettings).thenReturn({});
      var expectedEncodedName = expectedName + '/testuser+12345';
      var encodedName = UrlFragmentEncoder.encode(expectedName,
          items: mockItems, settings: mockSettings);
      expect(encodedName, expectedEncodedName);
    });
  });
}
