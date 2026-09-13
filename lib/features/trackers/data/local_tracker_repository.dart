import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';

class LocalTrackerRepository implements TrackerCompletionRepository {
  LocalTrackerRepository({required this.database});
  final Database database;
  final StreamController<List<TrackerOverview>> _overviewChanges =
      StreamController<List<TrackerOverview>>.broadcast(sync: true);
  final StreamController<String> _detailChanges =
      StreamController<String>.broadcast(sync: true);
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

  Future<void> dispose() async {
    await _overviewChanges.close();
    await _detailChanges.close();
  }

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
    for (final tracker in trackers) {
      _detailChanges.add(tracker.id);
    }
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
    _detailChanges.add(tracker.id);
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
    _detailChanges.add(tracker.id);
  }

  @override
  Stream<TrackerDetails?> watchDetails(String trackerId) async* {
    yield await _queryDetails(trackerId);
    await for (final changedId in _detailChanges.stream) {
      if (changedId == trackerId) yield await _queryDetails(trackerId);
    }
  }

  @override
  Future<Completion?> completeToday(
    String trackerId,
    DateTime timestamp,
  ) async {
    final localTimestamp = timestamp.toLocal();
    final start = DateTime(
      localTimestamp.year,
      localTimestamp.month,
      localTimestamp.day,
    );
    final end = start.add(const Duration(days: 1));
    Completion? inserted;
    await database.transaction((transaction) async {
      final existingRows = await transaction.query(
        'completions',
        columns: ['id', 'tracker_id', 'completed_at'],
        where: 'tracker_id = ?',
        whereArgs: [trackerId],
      );
      final trackerRows = await transaction.query(
        'trackers',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [trackerId],
        limit: 1,
      );
      if (trackerRows.isEmpty) return;
      final alreadyDone = existingRows.any((row) {
        final completedAt = DateTime.parse(row['completed_at']! as String)
            .toLocal();
        return !completedAt.isBefore(start) && completedAt.isBefore(end);
      });
      if (alreadyDone) return;
      inserted = Completion(
        id: 'completion-${localTimestamp.microsecondsSinceEpoch}',
        trackerId: trackerId,
        completedAt: localTimestamp,
      );
      await transaction.insert('completions', {
        'id': inserted!.id,
        'tracker_id': trackerId,
        'completed_at': inserted!.completedAt.toIso8601String(),
      });
    });
    if (inserted != null) {
      await refreshOverview();
      _detailChanges.add(trackerId);
    }
    return inserted;
  }

  @override
  Future<void> deleteCompletion(String completionId) async {
    String? trackerId;
    await database.transaction((transaction) async {
      final rows = await transaction.query(
        'completions',
        columns: ['tracker_id'],
        where: 'id = ?',
        whereArgs: [completionId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      trackerId = rows.first['tracker_id']! as String;
      await transaction.delete(
        'completions',
        where: 'id = ?',
        whereArgs: [completionId],
      );
    });
    if (trackerId != null) {
      await refreshOverview();
      _detailChanges.add(trackerId!);
    }
  }

  Future<TrackerDetails?> _queryDetails(String trackerId) async {
    final trackerRows = await database.query(
      'trackers',
      where: 'id = ?',
      whereArgs: [trackerId],
      limit: 1,
    );
    if (trackerRows.isEmpty) return null;
    final row = trackerRows.first;
    final tracker = _trackerFromRow(row);
    final completionRows = await database.query(
      'completions',
      where: 'tracker_id = ?',
      whereArgs: [trackerId],
      orderBy: 'completed_at DESC, id DESC',
      limit: 5,
    );
    return TrackerDetails(
      tracker: tracker,
      completions: List.unmodifiable(
        completionRows.map(
          (completion) => Completion(
            id: completion['id']! as String,
            trackerId: completion['tracker_id']! as String,
            completedAt: DateTime.parse(completion['completed_at']! as String),
          ),
        ),
      ),
    );
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
        final tracker = _trackerFromRow(row);
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

  static Tracker _trackerFromRow(Map<String, Object?> row) => Tracker(
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

  static TrackerCategory _categoryFrom(String? value) =>
      TrackerCategory.values.any((item) => item.name == value)
      ? TrackerCategory.values.byName(value!)
      : TrackerCategory.custom;

  static TrackerColor _colorFrom(String? value) =>
      TrackerColor.values.any((item) => item.name == value)
      ? TrackerColor.values.byName(value!)
      : TrackerColor.plum;
}
