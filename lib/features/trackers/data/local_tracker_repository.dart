import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../core/time/app_clock.dart';
import '../../subscriptions/domain/subscription.dart';
import '../../subscriptions/domain/subscription_repository.dart';
import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';
import '../../timeline/domain/timeline.dart';
import '../../timeline/domain/timeline_repository.dart';
import '../../reminders/domain/reminder.dart';
import '../../reminders/domain/reminder_repository.dart';
import '../../profile/domain/profile_settings.dart';

class LocalTrackerRepository
    implements
        TrackerCompletionRepository,
        SubscriptionRepository,
        TimelineRepository,
        ReminderRepository,
        ProfileStatisticsRepository {
  LocalTrackerRepository({required this.database, this.clock});
  final Database database;
  final AppClock? clock;
  final StreamController<List<TrackerOverview>> _overviewChanges =
      StreamController<List<TrackerOverview>>.broadcast(sync: true);
  final StreamController<String> _detailChanges =
      StreamController<String>.broadcast(sync: true);
  final StreamController<List<Subscription>> _subscriptionChanges =
      StreamController<List<Subscription>>.broadcast(sync: true);
  final StreamController<void> _timelineChanges =
      StreamController<void>.broadcast(sync: true);
  final StreamController<List<ReminderPreference>> _reminderChanges =
      StreamController<List<ReminderPreference>>.broadcast(sync: true);
  final StreamController<ProfileStatistics> _profileChanges =
      StreamController<ProfileStatistics>.broadcast(sync: true);
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
            firstDueDate: _dateOnlyOrNull(row['first_due_date'] as String?),
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
    await _subscriptionChanges.close();
    await _timelineChanges.close();
    await _reminderChanges.close();
    await _profileChanges.close();
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
          'first_due_date': tracker.firstDueDate?.toIso8601String(),
          'created_at': tracker.createdAt.toIso8601String(),
          'updated_at': tracker.updatedAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
    await refreshOverview();
    for (final tracker in trackers) {
      _detailChanges.add(tracker.id);
    }
    _timelineChanges.add(null);
    _profileChanges.add(await getStatistics(clock?.now ?? DateTime.now()));
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
    _timelineChanges.add(null);
    _profileChanges.add(await getStatistics(clock?.now ?? DateTime.now()));
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
    _timelineChanges.add(null);
    _profileChanges.add(await getStatistics(clock?.now ?? DateTime.now()));
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
      _timelineChanges.add(null);
      _profileChanges.add(await getStatistics(clock?.now ?? DateTime.now()));
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
      _timelineChanges.add(null);
      _profileChanges.add(await getStatistics(clock?.now ?? DateTime.now()));
    }
  }

  @override
  Stream<List<Subscription>> watchSubscriptions() async* {
    yield await _querySubscriptions();
    yield* _subscriptionChanges.stream;
  }

  @override
  Future<void> refreshSubscriptions() async {
    _subscriptionChanges.add(await _querySubscriptions());
    _profileChanges.add(await getStatistics(clock?.now ?? DateTime.now()));
  }

  @override
  Future<void> createSubscription(Subscription subscription) async {
    await database.transaction(
      (transaction) => transaction.insert(
        'subscriptions',
        _subscriptionValues(subscription),
      ),
    );
    _subscriptionChanges.add(await _querySubscriptions());
    _profileChanges.add(await getStatistics(clock?.now ?? DateTime.now()));
  }

  @override
  Future<ProfileStatistics> getStatistics(DateTime now) async {
    final local = now.toLocal();
    final monthStart = DateTime(local.year, local.month);
    final monthEnd = DateTime(local.year, local.month + 1);
    final activeTrackers = await database.rawQuery(
      'SELECT COUNT(*) FROM trackers',
    );
    final monthCompletions = await database.rawQuery(
      'SELECT COUNT(*) FROM completions WHERE completed_at >= ? AND completed_at < ?',
      [monthStart.toIso8601String(), monthEnd.toIso8601String()],
    );
    final totalCompletions = await database.rawQuery(
      'SELECT COUNT(*) FROM completions',
    );
    final activeSubscriptions = await database.rawQuery(
      'SELECT COUNT(*) FROM subscriptions WHERE active = 1',
    );
    final subscriptionRows = await database.query(
      'subscriptions',
      columns: ['amount_minor', 'currency', 'frequency'],
      where: 'active = 1',
    );
    final totals = <String, int>{};
    for (final row in subscriptionRows) {
      final subscription = _subscriptionFromRow({
        ...row,
        'id': 'stats',
        'name': 'stats',
        'category': SubscriptionCategory.custom.name,
        'next_charge_date': monthStart.toIso8601String(),
        'active': 1,
        'created_at': monthStart.toIso8601String(),
        'updated_at': monthStart.toIso8601String(),
      });
      totals.update(
        subscription.currency,
        (value) => value + monthlyEstimateMinor(subscription),
        ifAbsent: () => monthlyEstimateMinor(subscription),
      );
    }
    return ProfileStatistics(
      activeTrackerCount: Sqflite.firstIntValue(activeTrackers) ?? 0,
      monthCompletionCount: Sqflite.firstIntValue(monthCompletions) ?? 0,
      totalCompletionCount: Sqflite.firstIntValue(totalCompletions) ?? 0,
      activeSubscriptionCount: Sqflite.firstIntValue(activeSubscriptions) ?? 0,
      monthlySubscriptionTotals: Map.unmodifiable(totals),
    );
  }

  @override
  Stream<ProfileStatistics> watchStatistics(DateTime now) async* {
    yield await getStatistics(now);
    yield* _profileChanges.stream;
  }

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    await database.transaction(
      (transaction) => transaction.update(
        'subscriptions',
        _subscriptionValues(subscription),
        where: 'id = ?',
        whereArgs: [subscription.id],
      ),
    );
    _subscriptionChanges.add(await _querySubscriptions());
  }

  @override
  Future<Subscription?> getSubscription(String id) async {
    final rows = await database.query(
      'subscriptions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _subscriptionFromRow(rows.first);
  }

  @override
  Stream<List<ReminderPreference>> watchPreferences() async* {
    yield await _queryReminders();
    yield* _reminderChanges.stream;
  }

  @override
  Future<List<ReminderPreference>> listPreferences() => _queryReminders();

  @override
  Future<ReminderPreference?> getPreference(ReminderTarget target) async {
    final rows = await database.query(
      'reminder_preferences',
      where: 'target_type = ? AND target_id = ?',
      whereArgs: [target.type.name, target.id],
      limit: 1,
    );
    return rows.isEmpty ? null : _reminderFromRow(rows.first);
  }

  @override
  Future<ReminderPreference> savePreference(
    ReminderDraft draft,
    DateTime now,
  ) async {
    if (draft.localHour < 0 ||
        draft.localHour > 23 ||
        draft.localMinute < 0 ||
        draft.localMinute > 59) {
      throw ArgumentError('Invalid reminder time');
    }
    late ReminderPreference result;
    await database.transaction((transaction) async {
      final existing = await transaction.query(
        'reminder_preferences',
        where: 'target_type = ? AND target_id = ?',
        whereArgs: [draft.target.type.name, draft.target.id],
        limit: 1,
      );
      final createdAt = existing.isEmpty
          ? now
          : DateTime.parse(existing.first['created_at']! as String);
      final notificationId = existing.isEmpty
          ? await _nextReminderId(transaction)
          : existing.first['notification_id']! as int;
      final values = {
        'notification_id': notificationId,
        'target_type': draft.target.type.name,
        'target_id': draft.target.id,
        'enabled': draft.enabled ? 1 : 0,
        'lead_days': draft.leadTime.days,
        'local_hour': draft.localHour,
        'local_minute': draft.localMinute,
        'last_occurrence_key': null,
        'created_at': createdAt.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };
      await transaction.insert(
        'reminder_preferences',
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      result = ReminderPreference(
        notificationId: notificationId,
        target: draft.target,
        enabled: draft.enabled,
        leadTime: draft.leadTime,
        localHour: draft.localHour,
        localMinute: draft.localMinute,
        createdAt: createdAt,
        updatedAt: now,
      );
    });
    _reminderChanges.add(await _queryReminders());
    return result;
  }

  @override
  Future<int> countEnabled(ReminderTargetType type) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) FROM reminder_preferences WHERE enabled = 1 AND target_type = ?',
      [type.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<ReminderPreference>> _queryReminders() async {
    final rows = await database.query(
      'reminder_preferences',
      orderBy: 'target_type ASC, target_id ASC',
    );
    return List.unmodifiable(rows.map(_reminderFromRow));
  }

  static ReminderPreference _reminderFromRow(Map<String, Object?> row) {
    final targetType = ReminderTargetType.values.byName(
      row['target_type']! as String,
    );
    return ReminderPreference(
      notificationId: row['notification_id']! as int,
      target: ReminderTarget(targetType, row['target_id']! as String),
      enabled: row['enabled']! as int == 1,
      leadTime: ReminderLeadTime.fromDays(row['lead_days']! as int),
      localHour: row['local_hour']! as int,
      localMinute: row['local_minute']! as int,
      lastScheduledOccurrenceKey: row['last_occurrence_key'] as String?,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  static Future<int> _nextReminderId(DatabaseExecutor executor) async {
    final rows = await executor.rawQuery(
      'SELECT COALESCE(MAX(notification_id), 1000) + 1 AS next_id FROM reminder_preferences',
    );
    final id = rows.first['next_id']! as int;
    if (id >= 2000000000) {
      throw StateError('Reminder identifier space exhausted');
    }
    return id;
  }

  Future<List<Subscription>> _querySubscriptions() async {
    final rows = await database.query(
      'subscriptions',
      orderBy: 'active DESC, next_charge_date ASC, name COLLATE NOCASE ASC',
    );
    return List.unmodifiable(rows.map(_subscriptionFromRow));
  }

  @override
  Stream<void> watchTimelineChanges() async* {
    yield null;
    yield* _timelineChanges.stream;
  }

  @override
  Future<TimelinePage> queryTimeline(
    TimelineQuery query, {
    int pageSize = 40,
  }) async {
    final args = <Object?>[];
    final filters = <String>[];
    final search = query.search.trim();
    if (search.isNotEmpty) {
      filters.add('LOWER(COALESCE(t.title, \'\')) LIKE ?');
      args.add('%${search.toLowerCase()}%');
    }
    if (query.category != null) {
      filters.add('t.category_key = ?');
      args.add(query.category!.name);
    }
    if (query.cursor != null) {
      filters.add('(c.completed_at < ? OR (c.completed_at = ? AND c.id < ?))');
      final cursorTimestamp = query.cursor!.completedAt.toIso8601String();
      args
        ..add(cursorTimestamp)
        ..add(cursorTimestamp)
        ..add(query.cursor!.completionId);
    }
    final where = filters.isEmpty ? '' : 'WHERE ${filters.join(' AND ')}';
    final rows = await database.rawQuery(
      '''
      SELECT c.id AS completion_id, c.tracker_id, c.completed_at,
             t.title, t.category_key, t.icon_key, t.color_key,
             t.repeat_rule, t.repeat_interval
      FROM completions c
      LEFT JOIN trackers t ON t.id = c.tracker_id
      $where
      ORDER BY c.completed_at DESC, c.id DESC
      LIMIT ?
    ''',
      [...args, pageSize + 1],
    );
    final hasMore = rows.length > pageSize;
    final visibleRows = hasMore ? rows.take(pageSize) : rows;
    final entries = List<TimelineEntry>.unmodifiable(
      visibleRows.map(_timelineEntryFromRow),
    );
    final monthlyCount =
        Sqflite.firstIntValue(
          await database.rawQuery(
            'SELECT COUNT(*) FROM completions WHERE completed_at >= ? AND completed_at < ?',
            [
              query.monthStart.toIso8601String(),
              query.monthEnd.toIso8601String(),
            ],
          ),
        ) ??
        0;
    return TimelinePage(
      entries: entries,
      hasMore: hasMore,
      monthlyCount: monthlyCount,
    );
  }

  static TimelineEntry _timelineEntryFromRow(Map<String, Object?> row) {
    final trackerExists = row['title'] != null;
    final category = _categoryFrom(row['category_key'] as String?);
    final iconKey = (row['icon_key'] as String?) ?? TrackerIconKeys.checklist;
    final color = _colorFrom(row['color_key'] as String?);
    final repeatRule = row['repeat_rule'] as String?;
    final repeatInterval = row['repeat_interval'] as int? ?? 1;
    final cadence = repeatRule == null
        ? null
        : RepeatRule.values.byName(repeatRule).labelFor(repeatInterval);
    return TimelineEntry(
      completionId: row['completion_id']! as String,
      trackerId: row['tracker_id']! as String,
      completedAt: DateTime.parse(row['completed_at']! as String),
      title: (row['title'] as String?) ?? 'Removed tracker',
      category: category,
      iconKey: iconKey,
      color: color,
      cadence: cadence,
      missingTracker: !trackerExists,
    );
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
             t.first_due_date,
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
    'first_due_date': tracker.firstDueDate?.toIso8601String(),
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
    firstDueDate: _dateOnlyOrNull(row['first_due_date'] as String?),
    createdAt: DateTime.parse(row['created_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );

  static DateTime? _dateOnlyOrNull(String? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    final local = parsed.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static Subscription _subscriptionFromRow(Map<String, Object?> row) =>
      Subscription(
        id: row['id']! as String,
        catalogServiceId: row['catalog_service_id'] as String?,
        name: row['name']! as String,
        category: SubscriptionCategory.values.byName(
          row['category']! as String,
        ),
        logoKey: row['logo_key'] as String?,
        amountMinor: row['amount_minor']! as int,
        currency: row['currency']! as String,
        frequency: BillingFrequency.values.byName(row['frequency']! as String),
        nextChargeDate: DateTime.parse(row['next_charge_date']! as String),
        active: (row['active']! as int) == 1,
        note: row['note'] as String?,
        createdAt: DateTime.parse(row['created_at']! as String),
        updatedAt: DateTime.parse(row['updated_at']! as String),
      );

  static Map<String, Object?> _subscriptionValues(Subscription value) => {
    'id': value.id,
    'catalog_service_id': value.catalogServiceId,
    'name': value.name,
    'category': value.category.name,
    'logo_key': value.logoKey,
    'amount_minor': value.amountMinor,
    'currency': value.currency,
    'frequency': value.frequency.name,
    'next_charge_date': value.nextChargeDate.toIso8601String(),
    'active': value.active ? 1 : 0,
    'note': value.note,
    'created_at': value.createdAt.toIso8601String(),
    'updated_at': value.updatedAt.toIso8601String(),
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
