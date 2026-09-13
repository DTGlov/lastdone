import 'tracker.dart';

abstract interface class TrackerRepository {
  Future<List<Tracker>> listTrackers();
}
