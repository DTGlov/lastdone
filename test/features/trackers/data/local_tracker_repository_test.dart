import 'package:flutter_test/flutter_test.dart';
import 'package:lastdone/core/database/database_bootstrap.dart';
import 'package:lastdone/features/trackers/data/local_tracker_repository.dart';
import 'package:lastdone/features/trackers/domain/tracker.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('inserts starter trackers atomically and idempotently', () async {
    final database = await DatabaseBootstrap.open(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final repository = LocalTrackerRepository(database: database);
    final now = DateTime.utc(2026, 1, 2);
    final trackers = [
      Tracker(
        id: 'home-bedsheets',
        title: 'Change bedsheets',
        repeatRule: RepeatRule.everyTwoWeeks,
        createdAt: now,
        updatedAt: now,
      ),
      Tracker(
        id: 'vehicle-service',
        title: 'Service vehicle',
        repeatRule: RepeatRule.everyFourMonths,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await repository.insertStarterTrackers(trackers);
    await repository.insertStarterTrackers(trackers);

    final saved = await repository.listTrackers();
    expect(saved, hasLength(2));
    expect(saved.map((tracker) => tracker.repeatRule), [
      RepeatRule.everyTwoWeeks,
      RepeatRule.everyFourMonths,
    ]);
  });
}
