import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';

import 'load_games.dart';

class AppModel extends Model {
  static AppModel of(BuildContext context) => ScopedModel.of<AppModel>(context);

  static int _defaultCacheDurationInMinutes = 30;
  static int _unsetCacheDurationInMinutes = -1;

  List<Item> _items = [];
  BggCache _bggCache = BggCache(Games(), _unsetCacheDurationInMinutes);
  Settings _settings = Settings(5, 30, 90);
  Orientation screenOrientation;

  List<Item> get items => _items;

  BggCache get bggCache => _bggCache;

  Settings get settings => _settings;

  void addItem(Item item) {
    this.invalidateCache();
    _items.add(item);
  }

  void invalidateCache() {
    _bggCache.makeStale();
  }

  void replaceCache(Games games) {
    _bggCache = BggCache(games, _defaultCacheDurationInMinutes);
    notifyListeners();
  }

  void deleteItem(Item item) {
    this.invalidateCache();
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
  int _durationMinutes;
  int _cacheTimestamp;

  Games get games => _games;

  int get durationInMinutes => _durationMinutes;
  Game _stickyRandom;

  Game get random {
    var selectedGame = Random().nextInt(games.games.length);
    this._stickyRandom = games.games[selectedGame];
    return this._stickyRandom;
  }

  Game get lastRandom => _stickyRandom ?? random;

  BggCache(this._games, this._durationMinutes) {
    this._cacheTimestamp =
        epochToSeconds(DateTime.now().millisecondsSinceEpoch) +
            (this.durationInMinutes * 60);
  }

  int epochToSeconds(int millisEpoch) => (millisEpoch / 1000).floor();

  bool isStale() =>
      this._cacheTimestamp <
      epochToSeconds(DateTime.now().millisecondsSinceEpoch);

  void makeStale() => this._cacheTimestamp = 0;
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
