class ItemType {
  static const collection = ItemType("collection");
  static const geekList = ItemType("geeklist");
  static const hotList = ItemType("hot");

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
    : itemType =
          itemType ??
          (name.contains(RegExp(r"^\d+$"))
              ? ItemType.geekList
              : ItemType.collection);

  toJson() {
    return {'name': name, 'item_type': itemType};
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(json['name'], itemType: ItemType.fromJson(json['item_type']));
  }

  /// Encodes this item as a single URL-fragment token. A hotList item is
  /// wrapped in square brackets (e.g. `[trending]`) so that on reload it is
  /// restored as a hotList source rather than being mistaken for a BGG
  /// username - `trending` is a valid username BGG could one day assign.
  String toUrlToken() => itemType == ItemType.hotList ? '[$name]' : name;

  /// Restores an item from a [toUrlToken] fragment. A bracketed token is a
  /// hotList source; anything else falls back to name-based auto-detection.
  ///
  /// The token is percent-decoded first: browsers encode the square brackets
  /// as `%5B`/`%5D` in the URL fragment, so a hotList link arrives here as
  /// `%5Btrending%5D` rather than a literal `[trending]`.
  factory Item.fromUrlToken(String token) {
    final decoded = _tryDecode(token);
    if (decoded.length >= 2 &&
        decoded.startsWith('[') &&
        decoded.endsWith(']')) {
      return Item(
        decoded.substring(1, decoded.length - 1),
        itemType: ItemType.hotList,
      );
    }
    return Item(decoded);
  }

  static String _tryDecode(String token) {
    try {
      return Uri.decodeComponent(token);
    } on ArgumentError {
      // Malformed percent-encoding - fall back to the raw token.
      return token;
    }
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
