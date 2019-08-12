import 'item.dart';

class Items {
  static final String itemStoreNamePrefix = 'bgg-item-';

  List<Item> itemList;

  Items(this.itemList);

  toJson() {
    return {'items': itemList};
  }

  factory Items.fromJson(Map<String, dynamic> json) {
    return Items(json['items'].map((value) => Items.fromJson(value)).toList());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Items &&
          runtimeType == other.runtimeType &&
          itemList.toString() == other.itemList.toString();

  @override
  int get hashCode => itemList.toString().hashCode;

  @override
  String toString() => itemList.toString();

  bool get isEmpty => itemList.isEmpty;
}
