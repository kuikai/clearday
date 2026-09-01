import 'package:clearday/models/task.dart';
import 'package:clearday/providers/tasks_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Task task({
    required String id,
    DateTime? dueAt,
    bool completed = false,
  }) {
    return Task(
      id: id,
      groupId: 'home',
      title: id,
      createdAt: DateTime(2026, 8, 1),
      dueAt: dueAt,
      isCompleted: completed,
      completedAt: completed ? DateTime(2026, 8, 17) : null,
    );
  }

  test('groups tasks into overdue, today, upcoming, no date, and done', () {
    final now = DateTime(2026, 8, 17, 12);
    final groups = groupTasks(
      [
        task(id: 'overdue', dueAt: DateTime(2026, 8, 16)),
        task(id: 'today', dueAt: DateTime(2026, 8, 17, 18)),
        task(id: 'upcoming', dueAt: DateTime(2026, 8, 20)),
        task(id: 'none'),
        task(id: 'done', dueAt: DateTime(2026, 8, 17), completed: true),
      ],
      now,
    );

    expect(groups.overdue.map((item) => item.id), ['overdue']);
    expect(groups.today.map((item) => item.id), ['today']);
    expect(groups.upcoming.map((item) => item.id), ['upcoming']);
    expect(groups.noDate.map((item) => item.id), ['none']);
    expect(groups.done.map((item) => item.id), ['done']);
  });
}
