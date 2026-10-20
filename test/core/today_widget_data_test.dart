import 'dart:convert';

import 'package:clearday/core/today_widget_data.dart';
import 'package:clearday/models/app_data.dart';
import 'package:clearday/models/task.dart';
import 'package:clearday/models/task_group.dart';
import 'package:clearday/services/today_widget_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 19, 15);
  final home = TaskGroup(
    id: 'home',
    name: 'Home',
    createdAt: DateTime(2026, 10, 1),
  );

  Task task({
    required String id,
    String? title,
    DateTime? dueAt,
    bool hasTime = false,
    bool completed = false,
  }) {
    return Task(
      id: id,
      groupId: home.id,
      title: title ?? id,
      createdAt: DateTime(2026, 10, 1),
      dueAt: dueAt,
      dueHasTime: hasTime,
      isCompleted: completed,
    );
  }

  AppData dataWith(List<Task> tasks) {
    return AppData(
      groups: [home],
      tasks: tasks,
      selectedGroupId: home.id,
    );
  }

  group('todayWidgetTasks', () {
    test('keeps overdue, today, and the next week', () {
      final tasks = todayWidgetTasks(
        dataWith([
          task(id: 'done', dueAt: now, completed: true),
          task(id: 'blank', title: '   ', dueAt: now),
          task(id: 'none'),
          task(id: 'old', dueAt: DateTime(2026, 10, 17)),
          task(
            id: 'timed',
            title: 'Call  mom',
            dueAt: DateTime(2026, 10, 19, 17),
            hasTime: true,
          ),
          task(id: 'soon', dueAt: DateTime(2026, 10, 26)),
          task(id: 'far', dueAt: DateTime(2026, 10, 27)),
        ]),
        now,
      );

      expect(tasks.map((item) => item.title), ['Call mom', 'old', 'soon']);
      expect(tasks.first.hasTime, isTrue);
      expect(tasks.first.dueMillis, DateTime(2026, 10, 19, 17).millisecondsSinceEpoch);
    });

    test('keeps today when overdue tasks fill the cap', () {
      final overdue = [
        for (var day = 1; day <= 3; day++)
          task(id: 'old-$day', dueAt: DateTime(2026, 10, day)),
      ];
      final tasks = todayWidgetTasks(
        dataWith([
          ...overdue,
          task(id: 'bins', dueAt: DateTime(2026, 10, 19)),
        ]),
        now,
        cap: 2,
      );

      expect(tasks.map((item) => item.title), ['bins', 'old-1']);
    });
  });

  test('encodeTodayWidgetTasks writes title, due, and time', () {
    final raw = encodeTodayWidgetTasks(const [
      TodayWidgetTask(title: 'Bins', dueMillis: 10, hasTime: false),
    ]);
    expect(jsonDecode(raw), [
      {'t': 'Bins', 'd': 10, 'h': false},
    ]);
  });

  test('publishTodayWidget stores the snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await publishTodayWidget(
      prefs,
      dataWith([task(id: 'bins', dueAt: DateTime.now())]),
    );

    final saved = jsonDecode(prefs.getString(todayWidgetPrefsKey)!) as List;
    expect(saved, hasLength(1));
    expect(saved.first['t'], 'bins');
  });
}
