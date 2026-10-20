import 'package:clearday/widgets/task_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('undo notice sits above the page and can undo', (tester) async {
    var undone = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Edit task')),
          body: const Text('Repeat'),
        ),
      ),
    );

    showUndoNotice(
      tester.element(find.text('Repeat')),
      message: 'Marked done',
      onUndo: () => undone = true,
    );
    await tester.pumpAndSettle();

    expect(find.text('Marked done'), findsOneWidget);
    final noticeTop = tester.getTopLeft(find.text('Marked done')).dy;
    final repeatTop = tester.getTopLeft(find.text('Repeat')).dy;
    expect(noticeTop, lessThan(repeatTop));

    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(undone, isTrue);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
