import 'package:how_many_mobile_meeple/model/settings.dart';

import 'items.dart';
import 'model.dart';

class AppPreferences {
  final String id;
  final String title;
  final Items items;
  final Settings settings;

  AppPreferences(this.id, this.title, this.items, this.settings);

  toJson() {
    return {'id': id, 'items': items, 'settings': settings};
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(json['id'], json['title'],
        Items.fromJson(json['items']), Settings.fromJson(json['settings']));
  }

  factory AppPreferences.fromModel(AppModel model) {
    String titleFromItems(Items items) =>
        items.itemList.map((item) => item.name).toString();
    String title = model.title ?? titleFromItems(model.items);
    return AppPreferences(
        title.hashCode.toString(), title, model.items, model.settings);
  }
}
