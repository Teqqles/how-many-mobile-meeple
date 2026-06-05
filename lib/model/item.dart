class ItemType {
  static const collection = ItemType("collection");
  static const geekList = ItemType("geeklist");

  final String name;

  const ItemType(this.name);

  toJson() {
    return {'name': name};
  }

  factory ItemType.fromJson(Map<String, dynamic> json) {
    return ItemType(json['name']);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemType &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

class Item {
  final String name;
  ItemType itemType;

  Item(this.name, {ItemType? itemType})
      : itemType = itemType ??
            (name.contains(RegExp(r"^\d+$"))
                ? ItemType.geekList
                : ItemType.collection);

  toJson() {
    return {'name': name, 'item_type': itemType};
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(json['name'], itemType: ItemType.fromJson(json['item_type']));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          this.toString() == other.toString();

  @override
  int get hashCode => this.toJson().hashCode;

  @override
  String toString() => this.toJson().toString();
}
