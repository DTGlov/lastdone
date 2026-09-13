import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseBootstrap {
  static const version = 4;
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
        await db.execute('''CREATE TABLE subscriptions (
            id TEXT PRIMARY KEY, catalog_service_id TEXT, name TEXT NOT NULL,
            category TEXT NOT NULL, logo_key TEXT, amount_minor INTEGER NOT NULL,
            currency TEXT NOT NULL, frequency TEXT NOT NULL,
            next_charge_date TEXT NOT NULL, active INTEGER NOT NULL DEFAULT 1,
            note TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''');
        await db.execute(
          'CREATE INDEX subscriptions_next_charge ON subscriptions (active, next_charge_date)',
        );
        await _createReminders(db);
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
        if (oldVersion < 3) {
          await db.execute(
            '''CREATE TABLE subscriptions (
              id TEXT PRIMARY KEY, catalog_service_id TEXT, name TEXT NOT NULL,
              category TEXT NOT NULL, logo_key TEXT, amount_minor INTEGER NOT NULL,
              currency TEXT NOT NULL, frequency TEXT NOT NULL,
              next_charge_date TEXT NOT NULL, active INTEGER NOT NULL DEFAULT 1,
              note TEXT, created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
          );
          await db.execute(
            'CREATE INDEX subscriptions_next_charge ON subscriptions (active, next_charge_date)',
          );
        }
        if (oldVersion < 4) await _createReminders(db);
      },
    ),
  );

  static Future<void> _createReminders(DatabaseExecutor db) async {
    await db.execute('''CREATE TABLE reminder_preferences (
        notification_id INTEGER PRIMARY KEY,
        target_type TEXT NOT NULL,
        target_id TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 0,
        lead_days INTEGER NOT NULL DEFAULT 0,
        local_hour INTEGER NOT NULL DEFAULT 9,
        local_minute INTEGER NOT NULL DEFAULT 0,
        last_occurrence_key TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        UNIQUE(target_type, target_id))''');
    await db.execute(
      'CREATE INDEX reminder_preferences_enabled ON reminder_preferences (enabled)',
    );
  }
}
