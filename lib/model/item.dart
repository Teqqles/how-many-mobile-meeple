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
}

class Item {
  final String name;
  ItemType itemType;

  Item(this.name, {this.itemType}) {
    if (this.itemType == null) {
      var isNumeric = this.name.contains(RegExp(r"^\d+$"));
      this.itemType = isNumeric ? ItemType.geekList : ItemType.collection;
    }
  }

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
  int get hashCode => this.toString().hashCode;
}
