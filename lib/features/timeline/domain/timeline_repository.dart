import 'timeline.dart';

abstract interface class TimelineRepository {
  Stream<void> watchTimelineChanges();
  Future<TimelinePage> queryTimeline(TimelineQuery query, {int pageSize = 40});
}

class UnavailableTimelineRepository implements TimelineRepository {
  const UnavailableTimelineRepository();

  @override
  Stream<void> watchTimelineChanges() async* {
    yield null;
  }

  @override
  Future<TimelinePage> queryTimeline(
    TimelineQuery query, {
    int pageSize = 40,
  }) async => const TimelinePage(entries: [], hasMore: false, monthlyCount: 0);
}
