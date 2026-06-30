// coverage:ignore-file
abstract class DatabaseMigration {
  final Map<int, String> patches;

  DatabaseMigration(this.patches);

  Map<int, String> upgradesForVersion(int oldVersion, int newVersion) =>
      Map.fromIterable(
          patches.keys.where((k) => k <= newVersion && k > oldVersion),
          key: (k) => k,
          value: (k) => patches[k]!);

  bool hasUpgrade(int oldVersion, int newVersion) {
    var upgrades = upgradesForVersion(oldVersion, newVersion);
    return upgrades.length != 0;
  }
}
