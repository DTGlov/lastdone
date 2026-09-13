import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/time/app_clock.dart';
import '../../subscriptions/domain/subscription.dart';
import '../../subscriptions/domain/subscription_repository.dart';
import '../../today/domain/today_overview.dart';
import '../../trackers/domain/tracker_repository.dart';
import '../data/notification_gateway.dart';
import '../domain/reminder.dart';
import '../domain/reminder_repository.dart';

class ReminderCoordinator with WidgetsBindingObserver {
  ReminderCoordinator({
    required this.reminders,
    required this.trackerRepository,
    required this.subscriptionRepository,
    required this.gateway,
    required this.clock,
  });

  final ReminderRepository reminders;
  final TrackerRepository trackerRepository;
  final SubscriptionRepository subscriptionRepository;
  final NotificationGateway gateway;
  final AppClock clock;
  StreamSubscription<List<ReminderPreference>>? _remindersSubscription;
  StreamSubscription<List<TrackerOverview>>? _trackersSubscription;
  StreamSubscription<List<Subscription>>? _subscriptionsSubscription;
  bool _running = false;
  bool _queued = false;
  bool _disposed = false;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      await gateway.initialize();
      _remindersSubscription = reminders.watchPreferences().listen(
        (_) => reconcile(),
      );
      if (trackerRepository case final TrackerOverviewRepository value) {
        _trackersSubscription = value.watchOverview().listen(
          (_) => reconcile(),
        );
      }
      _subscriptionsSubscription = subscriptionRepository
          .watchSubscriptions()
          .listen((_) => reconcile());
      await reconcile();
    } catch (_) {
      // Notification failures must never prevent the app from starting.
    }
  }

  Future<void> reconcile() async {
    if (_disposed || !_running) return;
    if (_queued) return;
    _queued = true;
    try {
      await _reconcileOnce();
    } catch (_) {
      // Preferences remain authoritative; a later lifecycle or repository
      // change retries platform scheduling.
    } finally {
      _queued = false;
    }
  }

  Future<void> _reconcileOnce() async {
    final preferences = await reminders.listPreferences();
    final permission = await gateway.permissionStatus();
    final trackers = trackerRepository is TrackerOverviewRepository
        ? await (trackerRepository as TrackerOverviewRepository)
              .watchOverview()
              .first
        : (await trackerRepository.listTrackers())
              .map((tracker) => TrackerOverview(tracker: tracker))
              .toList(growable: false);
    final subscriptions = await subscriptionRepository
        .watchSubscriptions()
        .first;
    final candidates = <ReminderCandidate>[];
    final validIds = <int>{};
    for (final preference in preferences.where((item) => item.enabled)) {
      final candidate = _candidateFor(preference, trackers, subscriptions);
      if (candidate != null) {
        candidates.add(candidate);
        validIds.add(preference.notificationId);
      }
    }
    candidates.sort((a, b) => a.fireAt.compareTo(b.fireAt));
    final scheduledIds = candidates
        .take(60)
        .map((item) => item.preference.notificationId)
        .toSet();
    for (final id in await gateway.pendingIds()) {
      if (id != 999999 &&
          (!validIds.contains(id) || !scheduledIds.contains(id))) {
        await gateway.cancel(id);
      }
    }
    if (permission != NotificationPermissionStatus.authorized) return;
    for (final candidate in candidates.take(60)) {
      if (candidate.fireAt.isAfter(clock.now)) {
        await gateway.schedule(candidate);
      }
    }
  }

  ReminderCandidate? _candidateFor(
    ReminderPreference preference,
    List<TrackerOverview> trackers,
    List<Subscription> subscriptions,
  ) {
    final date = switch (preference.target.type) {
      ReminderTargetType.tracker => _trackerDue(preference.target.id, trackers),
      ReminderTargetType.subscription => _subscriptionDue(
        preference.target.id,
        subscriptions,
      ),
    };
    if (date == null) return null;
    final today = _dateOnly(clock.now);
    final preferred = _atLocalTime(
      date.subtract(Duration(days: preference.leadTime.days)),
      preference,
    );
    final dueTime = _atLocalTime(date, preference);
    final fireAt = preferred.isAfter(clock.now)
        ? preferred
        : dueTime.isAfter(clock.now)
        ? dueTime
        : null;
    if (fireAt == null || !fireAt.isAfter(clock.now)) return null;
    final kind = preference.target.type == ReminderTargetType.tracker
        ? 'is due'
        : 'renews';
    final title =
        '${_nameFor(preference.target, trackers, subscriptions)} $kind ${_relative(fireAt, today)}';
    return ReminderCandidate(
      preference: preference,
      fireAt: fireAt,
      occurrenceKey:
          '${preference.target.type.name}:${preference.target.id}:${date.toIso8601String()}:${preference.leadTime.days}:${preference.localHour}:${preference.localMinute}',
      title: title,
      body: preference.target.type == ReminderTargetType.tracker
          ? 'A quick nudge from Dun.'
          : 'A quick heads-up from Dun.',
    );
  }

  DateTime? _trackerDue(String id, List<TrackerOverview> values) {
    final overview = values.where((item) => item.tracker.id == id).firstOrNull;
    if (overview == null || overview.latestCompletion == null) return null;
    return TodayClassifier.nextDueDateFor(
      _dateOnly(overview.latestCompletion!.completedAt),
      overview.tracker,
    );
  }

  DateTime? _subscriptionDue(String id, List<Subscription> values) {
    final value = values.where((item) => item.id == id).firstOrNull;
    if (value == null || !value.active) return null;
    return nextChargeOnOrAfter(
      value.nextChargeDate,
      value.frequency,
      _dateOnly(clock.now),
    );
  }

  String _nameFor(
    ReminderTarget target,
    List<TrackerOverview> trackers,
    List<Subscription> subscriptions,
  ) => target.type == ReminderTargetType.tracker
      ? trackers
                .where((item) => item.tracker.id == target.id)
                .firstOrNull
                ?.tracker
                .title ??
            'Your tracker'
      : subscriptions.where((item) => item.id == target.id).firstOrNull?.name ??
            'Your subscription';

  DateTime _atLocalTime(DateTime date, ReminderPreference preference) {
    final local = date.toLocal();
    return DateTime(
      local.year,
      local.month,
      local.day,
      preference.localHour,
      preference.localMinute,
    );
  }

  static String _relative(DateTime date, DateTime today) {
    final days = _dateOnly(date).difference(today).inDays;
    if (days == 0) return 'today';
    if (days == 1) return 'tomorrow';
    return 'in $days days';
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  Future<void> dispose() async {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    await _remindersSubscription?.cancel();
    await _trackersSubscription?.cancel();
    await _subscriptionsSubscription?.cancel();
    if (gateway case final LocalNotificationGateway local) {
      await local.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(gateway.initialize().then((_) => reconcile()));
    }
  }
}
