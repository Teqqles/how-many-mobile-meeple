import 'dart:convert';

import 'package:how_many_mobile_meeple/model/settings.dart';

import 'items.dart';
import 'model.dart';
import 'setting.dart';

class AppPreferences {
  final String id;
  final String title;
  final Items items;
  final Settings settings;

  AppPreferences(this.id, this.title, this.items, this.settings);

  toJson() {
    return {'id': id, 'items': items, 'settings': settings};
  }

  static List<String> storedSettings = [
    "setting_whitelist",  // we store whitelist but this is no longer loaded
    "setting_num_players",
    "setting_min_time",
    "setting_max_time",
    "setting_complexity",
    "setting_user_recommendations",
    "setting_mechanic",
    "setting_use_all_mechanics",
    "setting_include_expansions",
    "setting_rating"
  ];

  factory AppPreferences.fromDb(Map<String, dynamic> row) {
    var settings = [];
    for (var setting in storedSettings) {
      if (row[setting] != null) {
        var storedSetting = Setting.fromJson(json.decode(row[setting]));
        settings.add(storedSetting);
      }
    }

    return AppPreferences(
        row['id'],
        row['title'],
        Items.fromDb(json.decode(row['items'])),
        Settings(Map.fromEntries(
            settings.map((setting) => MapEntry(setting.name, setting)))));
  }

  factory AppPreferences.fromModel(AppModel model) {
    String titleFromItems(Items items) =>
        items.itemList.map((item) => item.name).toString();
    String title = model.title ?? titleFromItems(model.items);
    return AppPreferences(
        title.hashCode.toString(), title, model.items, model.settings);
  }
}
