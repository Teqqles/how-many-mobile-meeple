import 'dart:math';

import 'package:scoped_model/scoped_model.dart';

import 'load_games.dart';

class AppModel extends Model {
  List<Item> _items = [];
  BggCache _bggCache = BggCache(Games());
  Settings _settings = Settings(5, 30, 90);

  List<Item> get items => _items;

  BggCache get bggCache => _bggCache;

  Settings get settings => _settings;

  void addItem(Item item) => _items.add(item);

  void replaceCache(Games games) {
    _bggCache = BggCache(games);
    notifyListeners();
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

class BggCache {
  Games _games;

  Games get games => _games;
  Game _stickyRandom;

  Game get random {
    var selectedGame = Random().nextInt(games.games.length);
    this._stickyRandom = games.games[selectedGame];
    return this._stickyRandom;
  }

  Game get lastRandom => _stickyRandom ?? random;

  BggCache(this._games);
}

class Settings {
  int playerCount;
  int minTime;
  int maxTime;

  Settings(this.playerCount, this.minTime, this.maxTime);
}

class Item {
  final String name;
  ItemType itemType;

  Item(this.name) {
    var isNumeric = this.name.contains(RegExp(r"^\d+$"));
    this.itemType = isNumeric ? ItemType.geekList : ItemType.collection;
  }
}
