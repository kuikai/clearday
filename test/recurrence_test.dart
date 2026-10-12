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
      weekdays: [DateTime.monday],
    );
    final wednesday = DateTime(2026, 8, 19, 8, 30);
    final next = recurrence.nextDueAfter(wednesday);
    expect(next.weekday, DateTime.monday);
    expect(next, DateTime(2026, 8, 24, 8, 30));
  });

  test('weekly with several days uses the soonest upcoming day', () {
    const recurrence = Recurrence(
      kind: RecurrenceKind.weekly,
      weekdays: [DateTime.thursday, DateTime.monday],
    );
    final wednesday = DateTime(2026, 8, 19, 8, 30);
    final next = recurrence.nextDueAfter(wednesday);
    expect(next, DateTime(2026, 8, 20, 8, 30));

    final afterThursday = recurrence.nextDueAfter(next);
    expect(afterThursday, DateTime(2026, 8, 24, 8, 30));
  });

  test('toggleWeekday keeps at least one day selected', () {
    const recurrence = Recurrence(
      kind: RecurrenceKind.weekly,
      weekdays: [DateTime.monday],
    );
    expect(
      recurrence.toggleWeekday(DateTime.monday).selectedWeekdays,
      [DateTime.monday],
    );
    expect(
      recurrence.toggleWeekday(DateTime.friday).selectedWeekdays,
      [DateTime.monday, DateTime.friday],
    );
  });

  test('fromJson still reads a single saved weekday', () {
    final recurrence = Recurrence.fromJson({
      'kind': 'weekly',
      'intervalDays': 5,
      'weekday': DateTime.wednesday,
    });
    expect(recurrence.selectedWeekdays, [DateTime.wednesday]);
    expect(recurrence.toJson()['weekdays'], [DateTime.wednesday]);
  });
}
