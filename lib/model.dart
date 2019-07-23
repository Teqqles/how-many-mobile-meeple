import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:how_many_mobile_meeple/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'load_games.dart';

import 'dart:convert';

class AppModel extends Model {
  static AppModel of(BuildContext context) => ScopedModel.of<AppModel>(context);

  static int _defaultCacheDurationInMinutes = 30;
  static int _unsetCacheDurationInMinutes = -1;

  List<Item> _items = [];
  BggCache _bggCache = BggCache(Games(), _unsetCacheDurationInMinutes);
  Settings _settings = Settings({
    Settings.fieldsToReturnFromApi.name: Settings.fieldsToReturnFromApi,
    Settings.filterMinimumTimeToPlay.name: Settings.filterMinimumTimeToPlay,
    Settings.filterMaximumTimeToPlay.name: Settings.filterMaximumTimeToPlay,
    Settings.filterNumberOfPlayers.name: Settings.filterNumberOfPlayers
  });
  Orientation screenOrientation;

  List<Item> get items => _items;

  BggCache get bggCache => _bggCache;

  Settings get settings => _settings;

  void addItem(Item item) {
    this.invalidateCache();
    _items.add(item);
    this.updateStore();
  }

  void invalidateCache() {
    _bggCache.makeStale();
  }

  void replaceCache(Games games) {
    _bggCache = BggCache(games, _defaultCacheDurationInMinutes);
    this.updateStore();
  }

  void deleteItem(Item item) {
    _items.remove(item);
    this.updateStore();
  }

  void updateStore() {
    _storeSettings(settings);
    this.invalidateCache();
    notifyListeners();
  }

  void _storeSettings(Settings settings) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    for (var setting in settings.allSettings.values) {
      await prefs.setString(setting.name, json.encode(setting));
    }
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

class Item {
  final String name;
  ItemType itemType;

  Item(this.name) {
    var isNumeric = this.name.contains(RegExp(r"^\d+$"));
    this.itemType = isNumeric ? ItemType.geekList : ItemType.collection;
  }
}
