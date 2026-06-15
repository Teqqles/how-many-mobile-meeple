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
    return GameRequest(items: items, headers: headers);
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
