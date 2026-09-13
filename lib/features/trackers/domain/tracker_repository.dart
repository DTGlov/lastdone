import 'tracker.dart';

abstract interface class TrackerRepository {
  Future<List<Tracker>> listTrackers();
  Future<void> insertStarterTrackers(List<Tracker> trackers);
}
