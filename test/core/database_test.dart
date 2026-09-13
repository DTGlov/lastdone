import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:everdun/core/database/database_bootstrap.dart';

void main() {
  setUpAll(() => sqfliteFfiInit());
  test('initializes versioned schema and indexes', () async {
    final db = await DatabaseBootstrap.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    expect(DatabaseBootstrap.version, 1);
    expect(
      await db.query(
        'sqlite_master',
        where: "type = 'table' AND name IN ('trackers', 'completions')",
      ),
      hasLength(2),
    );
    await db.close();
  });
}
