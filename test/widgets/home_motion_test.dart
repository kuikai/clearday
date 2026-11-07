import 'package:clearday/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('clearday/today_widget'),
          (_) async => null,
        );
  });

  testWidgets('groups collapse and the page still scrolls', (tester) async {
    tester.view.physicalSize = const Size(390, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = await createTestContainer(isPro: true);
    for (var index = 0; index < 6; index++) {
      await addNamedGroup(container, 'Group $index');
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );

    expect(find.text('Group 0'), findsOneWidget);

    final list = find.byKey(const Key('group-list'));
    final openHeight = tester.getSize(list).height;
    expect(openHeight, greaterThan(100));

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    expect(position.maxScrollExtent, greaterThan(0));

    await tester.drag(find.text('Group 0'), const Offset(0, -240));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(position.pixels, greaterThan(0));

    position.jumpTo(0);
    await tester.pump();

    await tester.tap(find.text('Groups'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final midHeight = tester.getSize(list).height;
    expect(midHeight, greaterThan(0));
    expect(midHeight, lessThan(openHeight));

    await tester.pumpAndSettle(
      const Duration(milliseconds: 50),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(tester.getSize(list).height, 0);
  });
}
