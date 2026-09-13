import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseBootstrap {
  static const version = 2;
  static Future<Database> open({
    String? databasePath,
    DatabaseFactory? factory,
  }) async => (factory ?? databaseFactory).openDatabase(
    databasePath ?? path.join(await getDatabasesPath(), 'lastdone.db'),
    options: OpenDatabaseOptions(
      version: version,
      onCreate: (db, _) async {
        await db.execute('''CREATE TABLE trackers (
            id TEXT PRIMARY KEY, title TEXT NOT NULL, repeat_rule TEXT NOT NULL,
            repeat_interval INTEGER NOT NULL DEFAULT 1,
            category_key TEXT NOT NULL DEFAULT 'custom',
            icon_key TEXT NOT NULL DEFAULT 'checklist',
            color_key TEXT NOT NULL DEFAULT 'plum',
            created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
        await db.execute('''CREATE TABLE completions (
            id TEXT PRIMARY KEY, tracker_id TEXT NOT NULL, completed_at TEXT NOT NULL,
            FOREIGN KEY (tracker_id) REFERENCES trackers (id))''');
        await db.execute(
          'CREATE INDEX completions_tracker_id ON completions (tracker_id)',
        );
        await db.execute(
          'CREATE INDEX completions_completed_at ON completions (completed_at)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE trackers ADD COLUMN repeat_interval INTEGER NOT NULL DEFAULT 1",
          );
          await db.execute(
            "ALTER TABLE trackers ADD COLUMN category_key TEXT NOT NULL DEFAULT 'custom'",
          );
          await db.execute(
            "ALTER TABLE trackers ADD COLUMN icon_key TEXT NOT NULL DEFAULT 'checklist'",
          );
          await db.execute(
            "ALTER TABLE trackers ADD COLUMN color_key TEXT NOT NULL DEFAULT 'plum'",
          );
        }
      },
    ),
  );
}
