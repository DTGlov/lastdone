import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/time/app_clock.dart';
import '../../trackers/domain/tracker.dart';
import '../domain/timeline.dart';
import '../domain/timeline_repository.dart';

enum TimelineLoadState { loading, content, empty, error }

class TimelineViewModel extends ChangeNotifier with WidgetsBindingObserver {
  TimelineViewModel({required this.repository, required this.clock}) {
    currentDate = _dateOnly(clock.now);
    WidgetsBinding.instance.addObserver(this);
    _changes = repository.watchTimelineChanges().listen((_) {
      unawaited(refresh());
    }, onError: (_) {});
    unawaited(refresh(initial: true));
  }

  final TimelineRepository repository;
  final AppClock clock;
  late DateTime currentDate;
  TimelineLoadState state = TimelineLoadState.loading;
  List<TimelineEntry> entries = const [];
  int monthlyCount = 0;
  String searchQuery = '';
  TrackerCategory? selectedCategory;
  bool hasMore = false;
  bool isLoadingMore = false;
  bool isRefreshing = false;
  String? errorMessage;
  String? paginationError;

  late final StreamSubscription<void> _changes;
  Timer? _searchDebounce;
  TimelineCursor? _nextCursor;
  int _requestVersion = 0;
  bool _disposed = false;
  bool _refreshQueued = false;

  List<TimelineGroup> get groups {
    final grouped = <DateTime, List<TimelineEntry>>{};
    for (final entry in entries) {
      grouped.putIfAbsent(_dateOnly(entry.completedAt), () => []).add(entry);
    }
    return List.unmodifiable(
      grouped.entries.map(
        (group) => TimelineGroup(
          date: group.key,
          entries: List.unmodifiable(group.value),
        ),
      ),
    );
  }

  List<TrackerCategory> get availableCategories => List.unmodifiable(
    entries.map((entry) => entry.category).toSet().toList()
      ..sort((a, b) => a.name.compareTo(b.name)),
  );

  String get monthName => _monthName(currentDate.month);
  bool get hasFilters =>
      searchQuery.trim().isNotEmpty || selectedCategory != null;

  void setSearchQuery(String value) {
    if (searchQuery == value) return;
    searchQuery = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      unawaited(refresh());
    });
    notifyListeners();
  }

  void setCategory(TrackerCategory? value) {
    if (selectedCategory == value) return;
    selectedCategory = value;
    unawaited(refresh());
    notifyListeners();
  }

  void clearFilters() {
    if (searchQuery.isEmpty && selectedCategory == null) return;
    _searchDebounce?.cancel();
    searchQuery = '';
    selectedCategory = null;
    unawaited(refresh());
    notifyListeners();
  }

  Future<void> refresh({bool initial = false}) async {
    if (_disposed) return;
    if (isRefreshing) {
      _refreshQueued = true;
      return;
    }
    final version = ++_requestVersion;
    isRefreshing = true;
    if (initial || entries.isEmpty) state = TimelineLoadState.loading;
    errorMessage = null;
    paginationError = null;
    _nextCursor = null;
    hasMore = false;
    notifyListeners();
    try {
      final page = await repository.queryTimeline(_query(), pageSize: 40);
      if (_disposed || version != _requestVersion) return;
      entries = page.entries;
      monthlyCount = page.monthlyCount;
      hasMore = page.hasMore;
      _nextCursor = page.nextCursor;
      state = entries.isEmpty
          ? TimelineLoadState.empty
          : TimelineLoadState.content;
    } catch (_) {
      if (_disposed || version != _requestVersion) return;
      if (entries.isEmpty) {
        state = TimelineLoadState.error;
        errorMessage = 'We could not load your Timeline. Please try again.';
      } else {
        errorMessage = 'Your Timeline is waiting for a refresh.';
      }
    } finally {
      if (!_disposed && version == _requestVersion) {
        isRefreshing = false;
        notifyListeners();
        if (_refreshQueued) {
          _refreshQueued = false;
          unawaited(refresh());
        }
      }
    }
  }

  Future<void> loadMore() async {
    if (_disposed || !hasMore || isLoadingMore || _nextCursor == null) return;
    final version = _requestVersion;
    isLoadingMore = true;
    paginationError = null;
    notifyListeners();
    try {
      final page = await repository.queryTimeline(
        _query(cursor: _nextCursor),
        pageSize: 40,
      );
      if (_disposed || version != _requestVersion) return;
      final existingIds = entries.map((entry) => entry.completionId).toSet();
      entries = List.unmodifiable([
        ...entries,
        ...page.entries.where((entry) => existingIds.add(entry.completionId)),
      ]);
      hasMore = page.hasMore;
      _nextCursor = page.nextCursor;
      monthlyCount = page.monthlyCount;
    } catch (_) {
      if (!_disposed && version == _requestVersion) {
        paginationError = 'Could not load more yet.';
      }
    } finally {
      if (!_disposed && version == _requestVersion) {
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() => refresh(initial: entries.isEmpty);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _disposed) return;
    final date = _dateOnly(clock.now);
    if (date != currentDate) {
      currentDate = date;
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_changes.cancel());
    super.dispose();
  }

  TimelineQuery _query({TimelineCursor? cursor}) {
    final start = DateTime(currentDate.year, currentDate.month);
    return TimelineQuery(
      monthStart: start,
      monthEnd: DateTime(currentDate.year, currentDate.month + 1),
      search: searchQuery,
      category: selectedCategory,
      cursor: cursor,
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
