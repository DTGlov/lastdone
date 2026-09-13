import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';

class LocalTrackerRepository implements TrackerEditorRepository {
  LocalTrackerRepository({required this.database});
  final Database database;
  final StreamController<List<TrackerOverview>> _overviewChanges =
      StreamController<List<TrackerOverview>>.broadcast(sync: true);
  @override
  Future<List<Tracker>> listTrackers() async {
    final rows = await database.query('trackers', orderBy: 'created_at ASC');
    return rows
        .map(
          (row) => Tracker(
            id: row['id']! as String,
            title: row['title']! as String,
            repeatRule: RepeatRule.values.byName(row['repeat_rule']! as String),
            repeatInterval: (row['repeat_interval'] as int?) ?? 1,
            category: _categoryFrom(row['category_key'] as String?),
            iconKey: (row['icon_key'] as String?) ?? TrackerIconKeys.checklist,
            color: _colorFrom(row['color_key'] as String?),
            createdAt: DateTime.parse(row['created_at']! as String),
            updatedAt: DateTime.parse(row['updated_at']! as String),
          ),
        )
        .toList();
  }

  @override
  Stream<List<TrackerOverview>> watchOverview() async* {
    yield await _queryOverview();
    yield* _overviewChanges.stream;
  }

  @override
  Future<void> refreshOverview() async {
    _overviewChanges.add(await _queryOverview());
  }

  Future<void> dispose() => _overviewChanges.close();

  @override
  Future<void> insertStarterTrackers(List<Tracker> trackers) async {
    await database.transaction((transaction) async {
      for (final tracker in trackers) {
        await transaction.insert('trackers', {
          'id': tracker.id,
          'title': tracker.title,
          'repeat_rule': tracker.repeatRule.name,
          'repeat_interval': tracker.repeatInterval,
          'category_key': tracker.category.name,
          'icon_key': tracker.iconKey,
          'color_key': tracker.color.name,
          'created_at': tracker.createdAt.toIso8601String(),
          'updated_at': tracker.updatedAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
    await refreshOverview();
  }

  @override
  Future<void> createTracker(
    Tracker tracker,
    Completion? initialCompletion,
  ) async {
    await database.transaction((transaction) async {
      await transaction.insert('trackers', _trackerValues(tracker));
      if (initialCompletion != null) {
        await transaction.insert('completions', {
          'id': initialCompletion.id,
          'tracker_id': initialCompletion.trackerId,
          'completed_at': initialCompletion.completedAt.toIso8601String(),
        });
      }
    });
    await refreshOverview();
  }

  @override
  Future<void> updateTracker(Tracker tracker) async {
    await database.update(
      'trackers',
      _trackerValues(tracker),
      where: 'id = ?',
      whereArgs: [tracker.id],
    );
    await refreshOverview();
  }

  Future<List<TrackerOverview>> _queryOverview() async {
    final rows = await database.rawQuery('''
      SELECT t.id, t.title, t.repeat_rule, t.repeat_interval,
             t.category_key, t.icon_key, t.color_key, t.created_at, t.updated_at,
             c.id AS completion_id, c.tracker_id AS completion_tracker_id,
             c.completed_at
      FROM trackers t
      LEFT JOIN completions c ON c.id = (
        SELECT latest.id
        FROM completions latest
        WHERE latest.tracker_id = t.id
        ORDER BY latest.completed_at DESC, latest.id DESC
        LIMIT 1
      )
      ORDER BY t.created_at ASC
    ''');
    return List<TrackerOverview>.unmodifiable(
      rows.map((row) {
        final tracker = Tracker(
          id: row['id']! as String,
          title: row['title']! as String,
          repeatRule: RepeatRule.values.byName(row['repeat_rule']! as String),
          repeatInterval: (row['repeat_interval'] as int?) ?? 1,
          category: _categoryFrom(row['category_key'] as String?),
          iconKey: (row['icon_key'] as String?) ?? TrackerIconKeys.checklist,
          color: _colorFrom(row['color_key'] as String?),
          createdAt: DateTime.parse(row['created_at']! as String),
          updatedAt: DateTime.parse(row['updated_at']! as String),
        );
        final completionId = row['completion_id'] as String?;
        return TrackerOverview(
          tracker: tracker,
          latestCompletion: completionId == null
              ? null
              : Completion(
                  id: completionId,
                  trackerId: row['completion_tracker_id']! as String,
                  completedAt: DateTime.parse(row['completed_at']! as String),
                ),
        );
      }),
    );
  }

  Map<String, Object?> _trackerValues(Tracker tracker) => {
    'id': tracker.id,
    'title': tracker.title,
    'repeat_rule': tracker.repeatRule.name,
    'repeat_interval': tracker.repeatInterval,
    'category_key': tracker.category.name,
    'icon_key': tracker.iconKey,
    'color_key': tracker.color.name,
    'created_at': tracker.createdAt.toIso8601String(),
    'updated_at': tracker.updatedAt.toIso8601String(),
  };

  static TrackerCategory _categoryFrom(String? value) =>
      TrackerCategory.values.any((item) => item.name == value)
      ? TrackerCategory.values.byName(value!)
      : TrackerCategory.custom;

  static TrackerColor _colorFrom(String? value) =>
      TrackerColor.values.any((item) => item.name == value)
      ? TrackerColor.values.byName(value!)
      : TrackerColor.plum;
}
