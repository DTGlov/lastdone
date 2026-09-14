import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/time/app_clock.dart';
import '../../subscriptions/domain/subscription.dart';
import '../../subscriptions/domain/subscription_repository.dart';
import '../../today/domain/today_overview.dart';
import '../../trackers/domain/tracker.dart';
import '../../trackers/domain/tracker_repository.dart';
import '../domain/planner.dart';
import '../domain/planner_repository.dart';

enum PlannerLoadState { loading, ready, empty, error }

class PlannerViewModel extends ChangeNotifier with WidgetsBindingObserver {
  PlannerViewModel({
    required this.plannerRepository,
    required this.overviewRepository,
    required this.subscriptionRepository,
    required this.clock,
  }) {
    WidgetsBinding.instance.addObserver(this);
    _today = _dateOnly(clock.now);
    focusedMonth = DateTime(_today.year, _today.month);
    selectedDate = _today;
    _overviewSubscription = overviewRepository.watchOverview().listen(
      _setOverviews,
    );
    _subscriptionSubscription = subscriptionRepository
        .watchSubscriptions()
        .listen(_setSubscriptions);
  }

  final PlannerRepository plannerRepository;
  final TrackerOverviewRepository overviewRepository;
  final SubscriptionRepository subscriptionRepository;
  final AppClock clock;

  PlannerLoadState state = PlannerLoadState.loading;
  DateTime focusedMonth = DateTime(2000);
  DateTime selectedDate = DateTime(2000);
  DateTime _today = DateTime(2000);
  List<TrackerOverview> _overviews = const [];
  List<Subscription> _subscriptions = const [];
  Map<PlannerDate, List<PlannerItem>> itemsByDate = const {};
  PlannerMonthSummary monthSummary = const PlannerMonthSummary(
    dueCount: 0,
    handledCount: 0,
    subscriptionTotals: {},
  );
  String? errorMessage;

  late final StreamSubscription<List<TrackerOverview>> _overviewSubscription;
  late final StreamSubscription<List<Subscription>> _subscriptionSubscription;
  int _generation = 0;
  bool _disposed = false;
  bool _loading = false;
  bool _reloadQueued = false;

  DateTime get today => _today;
  DateTime get windowStart => DateTime(focusedMonth.year, focusedMonth.month);
  DateTime get windowEnd => DateTime(focusedMonth.year, focusedMonth.month + 1);
  DateTime get planningEnd => DateTime(_today.year, _today.month + 12);
  List<PlannerItem> get selectedItems =>
      itemsByDate[PlannerDate.from(selectedDate)] ?? const [];

  List<PlannerItem> itemsFor(DateTime day) =>
      itemsByDate[PlannerDate.from(day)] ?? const [];

  void _setOverviews(List<TrackerOverview> values) {
    _overviews = List.unmodifiable(values);
    _queueReload();
  }

  void _setSubscriptions(List<Subscription> values) {
    _subscriptions = List.unmodifiable(values);
    _queueReload();
  }

  void selectDay(DateTime day) {
    final value = _dateOnly(day);
    if (_sameDate(value, selectedDate)) return;
    selectedDate = value;
    notifyListeners();
  }

  void changeMonth(DateTime month) {
    final value = DateTime(month.year, month.month);
    final first = DateTime(_today.year, _today.month);
    final last = DateTime(_today.year, _today.month + 11);
    if (value.isBefore(first) ||
        value.isAfter(last) ||
        _sameDate(value, focusedMonth)) {
      return;
    }
    focusedMonth = value;
    final lastDay = DateTime(value.year, value.month + 1, 0);
    if (selectedDate.isBefore(value) || selectedDate.isAfter(lastDay)) {
      selectedDate = DateTime(value.year, value.month, 1);
    }
    _queueReload();
  }

  Future<void> retry() async => _reload();

  void _queueReload() {
    if (_disposed) return;
    if (_loading) {
      _reloadQueued = true;
      return;
    }
    unawaited(_reload());
  }

  Future<void> _reload() async {
    if (_disposed) return;
    if (_loading) {
      _reloadQueued = true;
      return;
    }
    _loading = true;
    final generation = ++_generation;
    if (itemsByDate.isEmpty) state = PlannerLoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final start = DateTime(_today.year, _today.month);
      final end = planningEnd;
      final completions = await plannerRepository.queryCompletionsInRange(
        start,
        end,
      );
      if (_disposed || generation != _generation) return;
      final snapshot = _buildSnapshot(
        PlannerSources(
          overviews: _overviews,
          subscriptions: _subscriptions,
          completions: completions,
        ),
        start,
        end,
      );
      itemsByDate = snapshot.itemsByDate;
      monthSummary = snapshot.summary;
      state = itemsByDate.isEmpty
          ? PlannerLoadState.empty
          : PlannerLoadState.ready;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      state = PlannerLoadState.error;
      errorMessage = 'We could not load your Planner. Please try again.';
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        notifyListeners();
        if (_reloadQueued) {
          _reloadQueued = false;
          unawaited(_reload());
        }
      }
    }
  }

  PlannerSnapshot _buildSnapshot(
    PlannerSources source,
    DateTime start,
    DateTime end,
  ) {
    final indexed = <PlannerDate, List<PlannerItem>>{};
    final dueKeys = <String>{};
    final today = _today;

    void add(PlannerItem item) =>
        indexed.putIfAbsent(item.date, () => []).add(item);

    for (final overview in source.overviews) {
      final tracker = overview.tracker;
      final completion = overview.latestCompletion;
      DateTime? due = completion == null
          ? tracker.firstDueDate
          : TodayClassifier.nextDueDateFor(
              _dateOnly(completion.completedAt),
              tracker,
            );
      if (tracker.repeatRule == RepeatRule.unscheduled || due == null) continue;
      var first = true;
      while (due!.isBefore(end)) {
        if (!due.isBefore(start)) {
          final date = PlannerDate.from(due);
          final overdue = due.isBefore(today);
          final item = PlannerItem(
            id: 'due:${tracker.id}:${date.key}',
            type: PlannerItemType.trackerDue,
            title: tracker.title,
            date: date,
            status: overdue ? PlannerItemStatus.overdue : PlannerItemStatus.due,
            navigationTarget: '/trackers/${tracker.id}',
            trackerId: tracker.id,
            category: tracker.category,
            iconKey: tracker.iconKey,
            color: tracker.color,
            cadence: tracker.repeatRule.labelFor(tracker.repeatInterval),
          );
          add(item);
          dueKeys.add('${tracker.id}:${date.key}');
        } else if (first && due.isBefore(today)) {
          final date = PlannerDate.from(today);
          add(
            PlannerItem(
              id: 'due:${tracker.id}:${date.key}',
              type: PlannerItemType.trackerDue,
              title: tracker.title,
              date: date,
              status: PlannerItemStatus.overdue,
              navigationTarget: '/trackers/${tracker.id}',
              trackerId: tracker.id,
              category: tracker.category,
              iconKey: tracker.iconKey,
              color: tracker.color,
              cadence: tracker.repeatRule.labelFor(tracker.repeatInterval),
            ),
          );
          dueKeys.add('${tracker.id}:${date.key}');
        }
        first = false;
        due = TodayClassifier.nextDueDateFor(due, tracker);
      }
    }

    for (final entry in source.completions) {
      final date = PlannerDate.from(entry.completedAt);
      final key = '${entry.trackerId}:${date.key}';
      if (dueKeys.contains(key)) {
        final list = indexed[date];
        final index = list?.indexWhere((item) => item.id == 'due:$key') ?? -1;
        if (index >= 0) {
          final old = list![index];
          list[index] = PlannerItem(
            id: old.id,
            type: old.type,
            title: old.title,
            date: old.date,
            status: PlannerItemStatus.handled,
            navigationTarget: old.navigationTarget,
            trackerId: old.trackerId,
            category: old.category,
            iconKey: old.iconKey,
            color: old.color,
            cadence: old.cadence,
            completedAt: entry.completedAt,
          );
        }
        continue;
      }
      add(
        PlannerItem(
          id: 'completion:${entry.completionId}',
          type: PlannerItemType.completion,
          title: entry.title,
          date: date,
          status: PlannerItemStatus.handled,
          navigationTarget: '/trackers/${entry.trackerId}',
          trackerId: entry.trackerId,
          category: entry.category,
          iconKey: entry.iconKey,
          color: entry.color,
          cadence: entry.cadence,
          completedAt: entry.completedAt,
        ),
      );
    }

    for (final subscription in source.subscriptions.where(
      (item) => item.active,
    )) {
      var charge = nextChargeOnOrAfter(
        subscription.nextChargeDate,
        subscription.frequency,
        today,
      );
      while (charge.isBefore(end)) {
        if (!charge.isBefore(start)) {
          add(
            PlannerItem(
              id: 'charge:${subscription.id}:${PlannerDate.from(charge).key}',
              type: PlannerItemType.subscriptionCharge,
              title: subscription.name,
              date: PlannerDate.from(charge),
              status: PlannerItemStatus.upcoming,
              navigationTarget: '/subscriptions/${subscription.id}',
              amountMinor: subscription.amountMinor,
              currency: subscription.currency,
            ),
          );
        }
        charge = nextChargeAfter(charge, subscription.frequency);
      }
    }
    for (final items in indexed.values) {
      items.sort((a, b) => a.type.index.compareTo(b.type.index));
    }
    final monthItems = indexed.entries
        .where(
          (entry) =>
              entry.key.year == focusedMonth.year &&
              entry.key.month == focusedMonth.month,
        )
        .expand((entry) => entry.value);
    final monthDueCount = monthItems
        .where((item) => item.type == PlannerItemType.trackerDue)
        .length;
    final monthHandledCount = monthItems
        .where((item) => item.status == PlannerItemStatus.handled)
        .length;
    final monthTotals = <String, int>{};
    for (final item in monthItems.where(
      (item) => item.type == PlannerItemType.subscriptionCharge,
    )) {
      monthTotals[item.currency!] =
          (monthTotals[item.currency!] ?? 0) + item.amountMinor!;
    }
    return PlannerSnapshot(
      itemsByDate: Map.unmodifiable({
        for (final entry in indexed.entries)
          entry.key: List<PlannerItem>.unmodifiable(entry.value),
      }),
      summary: PlannerMonthSummary(
        dueCount: monthDueCount,
        handledCount: monthHandledCount,
        subscriptionTotals: Map.unmodifiable(monthTotals),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _disposed) return;
    final now = _dateOnly(clock.now);
    if (now != _today) {
      _today = now;
      focusedMonth = DateTime(now.year, now.month);
      selectedDate = now;
      _queueReload();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_overviewSubscription.cancel());
    unawaited(_subscriptionSubscription.cancel());
    super.dispose();
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime nextChargeAfter(DateTime date, BillingFrequency frequency) {
  final nextDay = date.add(const Duration(days: 1));
  return nextChargeOnOrAfter(nextDay, frequency, nextDay);
}
