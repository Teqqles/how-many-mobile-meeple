import 'package:how_many_mobile_meeple/model/item.dart';
import 'package:test/test.dart';

void main() {
  group('Item auto-detection', () {
    test('numeric ID auto-detects as geekList', () {
      var item = Item('12345');
      expect(item.itemType, ItemType.geekList);
    });

    test('large numeric ID auto-detects as geekList', () {
      var item = Item('9876543210');
      expect(item.itemType, ItemType.geekList);
    });

    test('single digit auto-detects as geekList', () {
      var item = Item('5');
      expect(item.itemType, ItemType.geekList);
    });

    test('username auto-detects as collection', () {
      var item = Item('username123');
      expect(item.itemType, ItemType.collection);
    });

    test('alphanumeric string auto-detects as collection', () {
      var item = Item('abc123xyz');
      expect(item.itemType, ItemType.collection);
    });

    test('username with special chars auto-detects as collection', () {
      var item = Item('user_name-123');
      expect(item.itemType, ItemType.collection);
    });

    test('explicit itemType overrides auto-detection for numeric ID', () {
      var item = Item('12345', itemType: ItemType.collection);
      expect(item.itemType, ItemType.collection);
    });

    test('explicit itemType overrides auto-detection for username', () {
      var item = Item('username', itemType: ItemType.geekList);
      expect(item.itemType, ItemType.geekList);
    });

    test('empty string defaults to collection', () {
      var item = Item('');
      expect(item.itemType, ItemType.collection);
    });

    test('numeric string with spaces defaults to collection', () {
      var item = Item('123 456');
      expect(item.itemType, ItemType.collection);
    });

    test('numeric string with leading zero auto-detects as geekList', () {
      var item = Item('00123');
      expect(item.itemType, ItemType.geekList);
    });
  });

  group('Item serialization', () {
    test('toJson includes name and itemType', () {
      var item = Item('testuser', itemType: ItemType.collection);
      var json = item.toJson();
      expect(json['name'], 'testuser');
      expect(json['item_type'], ItemType.collection);
    });

    test('fromJson restores item correctly', () {
      var json = {
        'name': 'testuser',
        'item_type': {'name': 'collection'}
      };
      var item = Item.fromJson(json);
      expect(item.name, 'testuser');
      expect(item.itemType, ItemType.collection);
    });

    test('round-trip serialization preserves data', () {
      var original = Item('12345', itemType: ItemType.geekList);
      var json = original.toJson();
      var restored = Item.fromJson({
        'name': json['name'],
        'item_type': json['item_type'].toJson()
      });
      expect(restored.name, original.name);
      expect(restored.itemType, original.itemType);
    });
  });

  group('Item equality', () {
    test('items with same name and type are equal', () {
      var item1 = Item('test', itemType: ItemType.collection);
      var item2 = Item('test', itemType: ItemType.collection);
      expect(item1, equals(item2));
    });

    test('items with different names are not equal', () {
      var item1 = Item('test1');
      var item2 = Item('test2');
      expect(item1, isNot(equals(item2)));
    });

    test('items with different types are not equal', () {
      var item1 = Item('12345', itemType: ItemType.collection);
      var item2 = Item('12345', itemType: ItemType.geekList);
      expect(item1, isNot(equals(item2)));
    });
  });
}
