import 'package:sqflite/sqflite.dart';

import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';

class LocalTrackerRepository implements TrackerRepository {
  const LocalTrackerRepository({required this.database});
  final Database database;
  @override
  Future<List<Tracker>> listTrackers() async {
    final rows = await database.query('trackers', orderBy: 'created_at ASC');
    return rows
        .map(
          (row) => Tracker(
            id: row['id']! as String,
            title: row['title']! as String,
            repeatRule: RepeatRule.values.byName(row['repeat_rule']! as String),
            createdAt: DateTime.parse(row['created_at']! as String),
            updatedAt: DateTime.parse(row['updated_at']! as String),
          ),
        )
        .toList();
  }

  @override
  Future<void> insertStarterTrackers(List<Tracker> trackers) async {
    await database.transaction((transaction) async {
      for (final tracker in trackers) {
        await transaction.insert('trackers', {
          'id': tracker.id,
          'title': tracker.title,
          'repeat_rule': tracker.repeatRule.name,
          'created_at': tracker.createdAt.toIso8601String(),
          'updated_at': tracker.updatedAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }
}
