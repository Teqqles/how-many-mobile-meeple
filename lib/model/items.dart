import 'item.dart';

class Items {
  static final String itemStoreNamePrefix = 'bgg-item-';

  List<Item> items;

  Items(this.items);

  toJson() {
    return {'items': items};
  }

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(
        json['items'].map((value) => Items.fromJson(value)).toList());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Items &&
              runtimeType == other.runtimeType &&
              items.toString() == other.items.toString();

  @override
  int get hashCode => items.toString().hashCode;

  @override
  String toString() => items.toString();
}