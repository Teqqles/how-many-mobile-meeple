import 'items.dart';
import 'settings.dart';

class GameRequest {
  final Items items;
  final Map<String, String> headers;

  GameRequest({required this.items, required this.headers});

  factory GameRequest.from(Settings settings, Items items) {
    final headers = Map.fromEntries(
      settings.enabledSettings.entries
          .where((e) => e.value.header != null)
          .map((e) => MapEntry(e.value.header!, e.value.value.toString())),
    );
    // Snapshot the items list so mutations after this point don't affect the
    // request's identity (e.g. deleteItem removing from the live list).
    final snapshot = Items(List.unmodifiable(items.itemList));
    return GameRequest(items: snapshot, headers: headers);
  }

  /// Returns a copy that also asks the API to return [field] in each game,
  /// appending it to the field whitelist. Used by the game night to fetch
  /// `mechanics`, which the default collection request omits.
  GameRequest withWhitelistField(String field) {
    final header = Settings.fieldsToReturnFromApi.header!;
    final current = headers[header];
    if (current == null || current.split(',').contains(field)) return this;
    final extended = Map<String, String>.from(headers)
      ..[header] = '$current,$field';
    return GameRequest(items: items, headers: extended);
  }

  String get _headersKey {
    final sorted = headers.entries.map((e) => '${e.key}=${e.value}').toList()
      ..sort();
    return sorted.join('&');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameRequest &&
          items == other.items &&
          _headersKey == other._headersKey;

  @override
  int get hashCode => Object.hash(items, _headersKey);
}
