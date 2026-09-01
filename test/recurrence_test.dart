import 'package:clearday/models/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every N days advances by the interval', () {
    const recurrence = Recurrence(
      kind: RecurrenceKind.everyNDays,
      intervalDays: 5,
    );
    final next = recurrence.nextDueAfter(DateTime(2026, 8, 17, 9));
    expect(next, DateTime(2026, 8, 22, 9));
  });

  test('weekly jumps to the next matching weekday', () {
    const recurrence = Recurrence(
      kind: RecurrenceKind.weekly,
      weekday: DateTime.monday,
    );
    final wednesday = DateTime(2026, 8, 19, 8, 30);
    final next = recurrence.nextDueAfter(wednesday);
    expect(next.weekday, DateTime.monday);
    expect(next, DateTime(2026, 8, 24, 8, 30));
  });
}
