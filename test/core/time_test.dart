import 'package:flutter_test/flutter_test.dart';
import 'package:everdun/core/time/app_clock.dart';

void main() {
  test('fixed clock is deterministic', () {
    final expected = DateTime.utc(2026, 1, 2, 3, 4);
    expect(FixedAppClock(expected).now, expected);
  });
}
