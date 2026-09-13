import 'tracker.dart';

class TrackerOverview {
  const TrackerOverview({required this.tracker, this.latestCompletion});
  final Tracker tracker;
  final Completion? latestCompletion;
}

abstract interface class TrackerRepository {
  Future<List<Tracker>> listTrackers();
  Future<void> insertStarterTrackers(List<Tracker> trackers);
}

abstract interface class TrackerOverviewRepository
    implements TrackerRepository {
  Stream<List<TrackerOverview>> watchOverview();
  Future<void> refreshOverview();
}

abstract interface class TrackerEditorRepository
    implements TrackerOverviewRepository {
  Future<void> createTracker(Tracker tracker, Completion? initialCompletion);
  Future<void> updateTracker(Tracker tracker);
}
