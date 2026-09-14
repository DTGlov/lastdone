import 'timeline.dart';

abstract interface class PlannerRepository {
  Future<List<TimelineEntry>> queryCompletionsInRange(
    DateTime start,
    DateTime end,
  );
}

class UnavailablePlannerRepository implements PlannerRepository {
  const UnavailablePlannerRepository();
  @override
  Future<List<TimelineEntry>> queryCompletionsInRange(
    DateTime start,
    DateTime end,
  ) async => const [];
}
