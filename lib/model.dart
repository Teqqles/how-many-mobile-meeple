import 'package:scoped_model/scoped_model.dart';

class AppModel extends Model {
  List<Item> _items = [];
  List<Item> get items => _items;
  Settings _settings = Settings(5);
  Settings get settings => _settings;

  void addItem(Item item) {
    _items.add(item);
  }

  void deleteItem(Item item) {
    _items.remove(item);
    notifyListeners();
  }
}

class ItemType {

  static const collection = ItemType("collection");
  static const geekList = ItemType("geeklist");

  final String name;
  const ItemType(this.name);
}

class Settings {
  int playerCount;
  Settings(this.playerCount);
}

class Item {
  final String name;
  ItemType itemType;

  Item(this.name) {
    var isNumeric = this.name.contains(RegExp(r"^\d+$"));
    this.itemType = isNumeric ? ItemType.geekList : ItemType.collection;
  }
}
