import 'package:how_many_mobile_meeple/storage/database_migration.dart';
import 'package:how_many_mobile_meeple/storage/preferences_history.dart';

class PreferenceHistoryDBMigration extends DatabaseMigration {
  PreferenceHistoryDBMigration()
      : super({
          20191002: "ALTER TABLE ${PreferencesHistoryDb.table} ADD COLUMN setting_rating TEXT",
        });
}
