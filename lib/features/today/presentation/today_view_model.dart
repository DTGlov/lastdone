import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/time/app_clock.dart';
import '../../../core/text/count_text.dart';
import '../../trackers/domain/tracker_repository.dart';
import '../domain/today_overview.dart';

enum TodayLoadState { loading, content, empty, error }

class TodayViewModel extends ChangeNotifier with WidgetsBindingObserver {
  TodayViewModel({required this.repository, required this.clock}) {
    currentDate = _dateOnly(clock.now);
    WidgetsBinding.instance.addObserver(this);
    _subscription = _watchOverview().listen(
      _receiveOverview,
      onError: _receiveError,
    );
  }
  final TrackerRepository repository;
  final AppClock clock;
  late DateTime currentDate;
  TodayLoadState state = TodayLoadState.loading;
  TodaySections sections = const TodaySections(
    needsAttention: [],
    comingUp: [],
    recentlyDone: [],
  );
  String? errorMessage;
  StreamSubscription<List<TrackerOverview>>? _subscription;
  bool _disposed = false;

  String get formattedDate =>
      '${_monthName(currentDate.month)} ${currentDate.day}, ${currentDate.year}';
  String get greeting => switch (clock.now.hour) {
    >= 5 && < 12 => 'Good morning',
    >= 12 && < 18 => 'Good afternoon',
    _ => 'Good evening',
  };
  bool get needsAttention => sections.needsAttention.isNotEmpty;
  String get summary {
    if (state == TodayLoadState.loading) return 'Taking a look at your day.';
    if (state == TodayLoadState.error) {
      return 'Your day is waiting for a refresh.';
    }
    if (sections.needsAttention.isNotEmpty) {
      final count = sections.needsAttention.length;
      return '$count little ${count == 1 ? 'thing could' : 'things could'} use your attention.';
    }
    if (sections.count == 0) return 'Let’s get your first tracker going.';
    final next = sections.comingUp
        .where((item) => item.nextDueDate != null)
        .map((item) => item.nextDueDate!)
        .fold<DateTime?>(
          null,
          (earliest, date) =>
              earliest == null || date.isBefore(earliest) ? date : earliest,
        );
    if (next != null) {
      final days = next.difference(currentDate).inDays;
      if (days > 0) return 'Your next thing is due in ${daysText(days)}.';
    }
    return 'Everything looks nicely handled.';
  }

  Future<void> retry() async {
    if (_disposed) return;
    state = TodayLoadState.loading;
    errorMessage = null;
    notifyListeners();
    try {
      await _refreshOverview();
    } catch (_) {
      _receiveError();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  void _receiveOverview(List<TrackerOverview> overviews) {
    if (_disposed) return;
    currentDate = _dateOnly(clock.now);
    sections = TodayClassifier.classify(
      currentDate: currentDate,
      overviews: overviews,
    );
    errorMessage = null;
    state = sections.isEmpty ? TodayLoadState.empty : TodayLoadState.content;
    notifyListeners();
  }

  void _receiveError([Object? error, StackTrace? stackTrace]) {
    if (_disposed) return;
    state = TodayLoadState.error;
    errorMessage = 'We could not load your day. Please try again.';
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_disposed) return;
    final date = _dateOnly(clock.now);
    if (date != currentDate) {
      currentDate = date;
      unawaited(retry());
    }
  }

  Stream<List<TrackerOverview>> _watchOverview() async* {
    if (repository case final TrackerOverviewRepository overviewRepository) {
      yield* overviewRepository.watchOverview();
      return;
    }
    final trackers = await repository.listTrackers();
    yield List<TrackerOverview>.unmodifiable(
      trackers.map((tracker) => TrackerOverview(tracker: tracker)),
    );
  }

  Future<void> _refreshOverview() async {
    if (repository case final TrackerOverviewRepository overviewRepository) {
      await overviewRepository.refreshOverview();
      return;
    }
    _receiveOverview(
      (await repository.listTrackers())
          .map((tracker) => TrackerOverview(tracker: tracker))
          .toList(),
    );
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static String _monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}
