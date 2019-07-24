class ItemType {
  static const collection = ItemType("collection");
  static const geekList = ItemType("geeklist");

  final String name;

  const ItemType(this.name);
}

class Item {
  final String name;
  ItemType itemType;

  Item(this.name) {
    var isNumeric = this.name.contains(RegExp(r"^\d+$"));
    this.itemType = isNumeric ? ItemType.geekList : ItemType.collection;
  }
}
