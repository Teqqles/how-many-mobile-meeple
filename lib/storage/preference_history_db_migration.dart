import 'package:how_many_mobile_meeple/storage/database_migration.dart';

class PreferenceHistoryDBMigration extends DatabaseMigration {
  PreferenceHistoryDBMigration()
      : super({
          20191001: "ALTER TABLE ADD COLUMN setting_rating TEXT",
        });
}
