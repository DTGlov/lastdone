import 'tracker.dart';

class TrackerOverview {
  const TrackerOverview({required this.tracker, this.latestCompletion});
  final Tracker tracker;
  final Completion? latestCompletion;
}

class TrackerDetails {
  const TrackerDetails({required this.tracker, required this.completions});
  final Tracker tracker;
  final List<Completion> completions;

  Completion? get latestCompletion =>
      completions.isEmpty ? null : completions.first;
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

class UnavailableTrackerOverviewRepository
    implements TrackerOverviewRepository {
  const UnavailableTrackerOverviewRepository();

  @override
  Future<List<Tracker>> listTrackers() async => const [];

  @override
  Future<void> insertStarterTrackers(List<Tracker> trackers) async {}

  @override
  Stream<List<TrackerOverview>> watchOverview() => Stream.value(const []);

  @override
  Future<void> refreshOverview() async {}
}

abstract interface class TrackerArchiveRepository {
  Stream<List<Tracker>> watchArchivedTrackers();
  Future<void> archiveTracker(String trackerId, DateTime archivedAt);
  Future<void> restoreTracker(String trackerId, DateTime restoredAt);
}

abstract interface class TrackerEditorRepository
    implements TrackerOverviewRepository {
  Future<void> createTracker(Tracker tracker, Completion? initialCompletion);
  Future<void> updateTracker(Tracker tracker);
}

abstract interface class TrackerCompletionRepository
    implements TrackerEditorRepository {
  Stream<TrackerDetails?> watchDetails(String trackerId);
  Future<Completion?> completeToday(String trackerId, DateTime timestamp);
  Future<void> deleteCompletion(String completionId);
}
