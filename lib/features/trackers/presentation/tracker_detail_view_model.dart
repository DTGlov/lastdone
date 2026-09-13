import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/time/app_clock.dart';
import '../../today/domain/today_overview.dart';
import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';

enum TrackerDetailLoadState { loading, content, missing, error }

class TrackerDetailViewModel extends ChangeNotifier {
  TrackerDetailViewModel({
    required this.repository,
    required this.clock,
    required this.trackerId,
  }) {
    _subscription = _watchDetails().listen(
      _receiveDetails,
      onError: _receiveError,
    );
  }

  final TrackerRepository repository;
  final AppClock clock;
  final String trackerId;
  TrackerDetailLoadState state = TrackerDetailLoadState.loading;
  TrackerDetails? details;
  late DateTime currentDate;
  bool isCompleting = false;
  bool completedToday = false;
  String? errorMessage;
  StreamSubscription<TrackerDetails?>? _subscription;
  bool _disposed = false;

  TodayTracker? get classifiedTracker {
    final current = details;
    if (current == null) return null;
    return TodayClassifier.classify(
      currentDate: currentDate,
      overviews: [
        TrackerOverview(
          tracker: current.tracker,
          latestCompletion: current.latestCompletion,
        ),
      ],
    ).all;
  }

  Future<Completion?> completeToday() async {
    if (_disposed || isCompleting || completedToday) return null;
    final completionRepository = repository is TrackerCompletionRepository
        ? repository as TrackerCompletionRepository
        : null;
    if (completionRepository == null) {
      errorMessage = 'Completion is not available right now. Please try again.';
      notifyListeners();
      return null;
    }
    isCompleting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final completion = await completionRepository.completeToday(
        trackerId,
        clock.now,
      );
      isCompleting = false;
      completedToday = true;
      notifyListeners();
      return completion;
    } catch (_) {
      isCompleting = false;
      errorMessage = 'We could not save that yet. Please try again.';
      notifyListeners();
      return null;
    }
  }

  Future<void> retry() async {
    if (_disposed) return;
    state = TrackerDetailLoadState.loading;
    errorMessage = null;
    notifyListeners();
    final completionRepository = repository is TrackerCompletionRepository
        ? repository as TrackerCompletionRepository
        : null;
    if (completionRepository == null) {
      _receiveError();
      return;
    }
    await _subscription?.cancel();
    _subscription = _watchDetails().listen(
      _receiveDetails,
      onError: _receiveError,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Stream<TrackerDetails?> _watchDetails() async* {
    if (repository case final TrackerCompletionRepository detailRepository) {
      yield* detailRepository.watchDetails(trackerId);
      return;
    }
    yield null;
  }

  void _receiveDetails(TrackerDetails? value) {
    if (_disposed) return;
    currentDate = _dateOnly(clock.now);
    details = value;
    state = value == null
        ? TrackerDetailLoadState.missing
        : TrackerDetailLoadState.content;
    completedToday =
        value?.completions.any(
          (completion) => _sameDate(completion.completedAt, currentDate),
        ) ??
        false;
    errorMessage = null;
    notifyListeners();
  }

  void _receiveError([Object? error, StackTrace? stackTrace]) {
    if (_disposed) return;
    state = TrackerDetailLoadState.error;
    errorMessage = 'We could not load this tracker. Please try again.';
    notifyListeners();
  }

  static DateTime _dateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool _sameDate(DateTime first, DateTime second) {
    final firstDate = _dateOnly(first);
    final secondDate = _dateOnly(second);
    return firstDate.year == secondDate.year &&
        firstDate.month == secondDate.month &&
        firstDate.day == secondDate.day;
  }
}

extension on TodaySections {
  TodayTracker? get all {
    final items = [...needsAttention, ...comingUp, ...recentlyDone];
    return items.length == 1 ? items.single : null;
  }
}
