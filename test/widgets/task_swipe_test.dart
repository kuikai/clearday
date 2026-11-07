import 'package:clearday/widgets/task_swipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('swipe left marks done once', (tester) async {
    var done = 0;
    var tomorrow = 0;
    await _pumpSwipe(
      tester,
      allowTomorrow: true,
      onDone: () => done++,
      onTomorrow: () => tomorrow++,
    );

    await tester.drag(find.text('Dishes'), const Offset(-90, 0));
    await tester.pumpAndSettle();

    expect(done, 1);
    expect(tomorrow, 0);
  });

  testWidgets('a short drag does not mark done', (tester) async {
    var done = 0;
    await _pumpSwipe(tester, allowTomorrow: true, onDone: () => done++);

    await tester.drag(find.text('Dishes'), const Offset(-20, 0));
    await tester.pumpAndSettle();

    expect(done, 0);
  });

  testWidgets('swipe right moves an open task to tomorrow', (tester) async {
    var done = 0;
    var tomorrow = 0;
    await _pumpSwipe(
      tester,
      allowTomorrow: true,
      onDone: () => done++,
      onTomorrow: () => tomorrow++,
    );

    await tester.drag(find.text('Dishes'), const Offset(90, 0));
    await tester.pumpAndSettle();

    expect(tomorrow, 1);
    expect(done, 0);
  });

  testWidgets('a vertical drag still scrolls the page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              TaskSwipe(
                allowTomorrow: true,
                markingDone: true,
                onTomorrow: () {},
                onDone: () {},
                child: const SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: Text('Dishes'),
                ),
              ),
              const SizedBox(height: 1200),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.text('Dishes'), const Offset(0, -300));
    await tester.pumpAndSettle();

    final position = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position;
    expect(position.pixels, greaterThan(0));
  });

  testWidgets('a finished task cannot move to tomorrow', (tester) async {
    var done = 0;
    var tomorrow = 0;
    await _pumpSwipe(
      tester,
      allowTomorrow: false,
      onDone: () => done++,
      onTomorrow: () => tomorrow++,
    );

    await tester.drag(find.text('Dishes'), const Offset(90, 0));
    await tester.pumpAndSettle();
    expect(tomorrow, 0);

    await tester.drag(find.text('Dishes'), const Offset(-90, 0));
    await tester.pumpAndSettle();
    expect(done, 1);
  });
}

Future<void> _pumpSwipe(
  WidgetTester tester, {
  required bool allowTomorrow,
  required VoidCallback onDone,
  VoidCallback? onTomorrow,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TaskSwipe(
          allowTomorrow: allowTomorrow,
          markingDone: allowTomorrow,
          onTomorrow: onTomorrow ?? () {},
          onDone: onDone,
          child: const SizedBox(
            width: double.infinity,
            height: 64,
            child: Text('Dishes'),
          ),
        ),
      ),
    ),
  );
}
