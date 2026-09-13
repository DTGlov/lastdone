import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseBootstrap {
  static const version = 1;
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
    ),
  );
}
