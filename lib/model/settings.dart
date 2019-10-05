import 'package:how_many_mobile_meeple/model/setting.dart';

class Settings {
  static Setting fieldsToReturnFromApi = Setting("fieldsToUse",
      header: "Bgg-Field-Whitelist",
      value: "name,maxplayers,minplayers,maxplaytime,image,thumbnail,stats",
      enabled: true);

  static Setting filterNumberOfPlayers =
      Setting("numberOfPlayers", header: "Bgg-Filter-Player-Count", value: 5);

  static Setting filterMinimumTimeToPlay = Setting("minimumTimeToPlay",
      header: "Bgg-Filter-Min-Duration", value: 30);

  static Setting filterMaximumTimeToPlay = Setting("maximumTimeToPlay",
      header: "Bgg-Filter-Max-Duration", value: 90);

  static Setting filterComplexity = Setting("maximumComplexity",
      header: "Bgg-Filter-Max-Complexity", value: 2.5);

  static Setting filterUsingUserRecommendations = Setting(
      "useUserRecommendedFilters",
      header: "Bgg-Filter-Using-Recommended-Players",
      value: true,
      enabled: true);

  static Setting filterMechanics = Setting("mechanicsFilters",
      header: "Bgg-Filter-Mechanic", value: List<String>());

  static Setting filterUseAllMechanics =
      Setting("useAllMechanicsFilters", value: false, enabled: true);

  static Setting filterIncludesExpansions = Setting("includeExpansions",
      header: "Bgg-Include-Expansions", value: false, enabled: true);

  static Setting filterMinRating =
      Setting("minimumRating", header: "Bgg-Filter-Min-Rating", value: 5.0);

  Map<String, Setting> _settings = Map<String, Setting>();

  Map<String, Setting> get allSettings => _settings;

  Map<String, Setting> get enabledSettings {
    Map<String, Setting> filteredSettings = Map.from(_settings);
    filteredSettings.removeWhere(
        (_, setting) => !setting.enabled || setting.header == null);
    return filteredSettings;
  }

  Setting setting(String name) {
    return _settings[name];
  }

  void updateSetting(Setting setting) => _settings[setting.name] = setting;

  Settings(this._settings);

  toJson() {
    return {'settings': allSettings};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settings &&
          runtimeType == other.runtimeType &&
          allSettings.toString() == other.allSettings.toString();

  @override
  int get hashCode => allSettings.toString().hashCode;

  @override
  String toString() => allSettings.toString();

  Settings clone() => Settings(allSettings);
}
