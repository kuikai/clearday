import 'package:clearday/models/app_data.dart';
import 'package:clearday/models/task_group.dart';
import 'package:clearday/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fromJson keeps good tasks when one entry is invalid', () {
    final data = AppData.fromJson({
      'groups': [
        {
          'id': 'home',
          'name': 'Home',
          'createdAt': '2026-08-01T00:00:00.000',
        },
      ],
      'tasks': [
        {
          'id': 'ok',
          'groupId': 'home',
          'title': 'Take out trash',
          'createdAt': '2026-08-01T00:00:00.000',
        },
        {'title': 'missing id'},
        'not-a-map',
      ],
      'selectedGroupId': 'home',
    });

    expect(data.tasks.map((task) => task.id), ['ok']);
    expect(data.groups.single.id, 'home');
  });

  test('fromJson turns a group that parents itself into a top-level group', () {
    final data = AppData.fromJson({
      'groups': [
        {
          'id': 'loop',
          'name': 'Loop',
          'createdAt': '2026-08-01T00:00:00.000',
          'parentId': 'loop',
        },
      ],
      'tasks': [],
      'selectedGroupId': 'loop',
    });

    expect(data.groups.single.parentId, isNull);
  });

  test('groupsForPicker does not hang when a duplicate id forms a cycle', () {
    final createdAt = DateTime(2026, 8, 1);
    final data = AppData(
      groups: [
        TaskGroup(id: 'a', name: 'A', createdAt: createdAt),
        TaskGroup(id: 'b', name: 'B', createdAt: createdAt, parentId: 'a'),
        TaskGroup(id: 'a', name: 'A loop', createdAt: createdAt, parentId: 'b'),
      ],
      tasks: const [],
      selectedGroupId: 'a',
    );

    expect(data.groupsForPicker().map((group) => group.id), ['a', 'b']);
  });

  test('corrupt saved JSON is not overwritten on load', () async {
    SharedPreferences.setMockInitialValues({
      'clearday_data': '{not-json',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);

    final data = storage.loadAppData();

    expect(storage.loadCorrupt, isTrue);
    expect(data.groups, isNotEmpty);
    expect(prefs.getString('clearday_data'), '{not-json');
  });
}
