import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:how_many_mobile_meeple/model/items.dart';
import 'package:how_many_mobile_meeple/model/setting.dart';
import 'package:how_many_mobile_meeple/model/settings.dart';
import 'package:how_many_mobile_meeple/platform/web/url_fragment_encoder.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockItems extends Mock implements Items {}
class MockSettings extends Mock implements Settings {}

main() {
  var expectedName = '/pagename';
  group('encode', () {
    test('returns name when only a name given', () {
      var encodedName = UrlFragmentEncoder.encode(expectedName);
      expect(encodedName, expectedName);
    });

    test('returns name when empty items given', () {
      final mockItems = MockItems();

      when(mockItems.itemList).thenReturn([]);
      var encodedName = UrlFragmentEncoder.encode(expectedName, items: mockItems);
      expect(encodedName, expectedName);
    });

    test('returns name and single item', () {
      final mockItems = MockItems();

      when(mockItems.itemList).thenReturn([Item('test')]);
      var expectedEncodedName = expectedName + '/test';
      var encodedName = UrlFragmentEncoder.encode(expectedName, items: mockItems);
      expect(encodedName, expectedEncodedName);
    });

    test('returns name and plus separated items', () {
      final mockItems = MockItems();

      when(mockItems.itemList).thenReturn([Item('test'), Item('test2')]);
      var expectedEncodedName = expectedName + '/test+test2';
      var encodedName = UrlFragmentEncoder.encode(expectedName, items: mockItems);
      expect(encodedName, expectedEncodedName);
    });


    test('returns name when empty settings given', () {
      final mockSettings = MockSettings();

      when(mockSettings.allSettings).thenReturn({});
      var encodedName = UrlFragmentEncoder.encode(expectedName, settings: mockSettings);
      expect(encodedName, expectedName);
    });

    test('returns name, item and setting', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([Item('test')]);
      when(mockSettings.changedSettings).thenReturn({'test': Setting('setting', value: 'value')});
      var expectedEncodedName = expectedName + '/test?setting=value';
      var encodedName = UrlFragmentEncoder.encode(expectedName, items: mockItems, settings: mockSettings);
      expect(encodedName, expectedEncodedName);
    });

    test('returns name, item and settings with correct separation', () {
      final mockItems = MockItems();
      final mockSettings = MockSettings();

      when(mockItems.itemList).thenReturn([Item('test')]);
      when(mockSettings.changedSettings).thenReturn({
        'test': Setting('setting', value: 'value'),
        'test2': Setting('setting2', value: 'value2')});
      var expectedEncodedName = expectedName + '/test?setting=value&setting2=value2';
      var encodedName = UrlFragmentEncoder.encode(expectedName, items: mockItems, settings: mockSettings);
      expect(encodedName, expectedEncodedName);
    });

  });
}
