import 'package:sqflite/sqflite.dart';

import '../domain/tracker.dart';
import '../domain/tracker_repository.dart';

class LocalTrackerRepository implements TrackerRepository {
  const LocalTrackerRepository({required this.database});
  final Database database;
  @override
  Future<List<Tracker>> listTrackers() async => const [];
}
