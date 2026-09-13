import 'package:flutter_test/flutter_test.dart';
import 'package:lastdone/features/trackers/domain/tracker.dart';

void main() {
  test('tracker and completion retain domain invariants', () {
    final date = DateTime.utc(2026);
    final tracker = Tracker(
      id: 't1',
      title: 'Water plants',
      repeatRule: RepeatRule.weekly,
      createdAt: date,
      updatedAt: date,
    );
    final completion = Completion(
      id: 'c1',
      trackerId: tracker.id,
      completedAt: date,
    );
    expect(tracker.repeatRule, RepeatRule.weekly);
    expect(completion.trackerId, tracker.id);
  });
}
