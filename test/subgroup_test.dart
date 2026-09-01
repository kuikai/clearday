import 'package:clearday/models/app_data.dart';
import 'package:clearday/models/task_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 8, 17);

  test('subgroups sit under a parent group', () {
    final home = TaskGroup(id: 'home', name: 'Home', createdAt: createdAt);
    final kitchen = TaskGroup(
      id: 'kitchen',
      name: 'Kitchen',
      createdAt: createdAt,
      parentId: 'home',
    );
    final data = AppData(
      groups: [home, kitchen],
      tasks: const [],
      selectedGroupId: 'home',
    );

    expect(data.topLevelGroups.map((group) => group.id), ['home']);
    expect(data.subgroupsOf('home').map((group) => group.id), ['kitchen']);
    expect(data.groupPath('kitchen'), 'Home · Kitchen');
    expect(data.descendantGroupIds('home'), {'home', 'kitchen'});
  });

  test('subgroups can nest under another subgroup', () {
    final home = TaskGroup(id: 'home', name: 'Home', createdAt: createdAt);
    final kitchen = TaskGroup(
      id: 'kitchen',
      name: 'Kitchen',
      createdAt: createdAt,
      parentId: 'home',
    );
    final sink = TaskGroup(
      id: 'sink',
      name: 'Sink',
      createdAt: createdAt,
      parentId: 'kitchen',
    );
    final data = AppData(
      groups: [home, kitchen, sink],
      tasks: const [],
      selectedGroupId: 'kitchen',
    );

    expect(data.subgroupsOf('kitchen').map((group) => group.id), ['sink']);
    expect(data.groupPath('sink'), 'Home · Kitchen · Sink');
    expect(data.groupsForPicker().map((group) => group.id), [
      'home',
      'kitchen',
      'sink',
    ]);
  });
}
