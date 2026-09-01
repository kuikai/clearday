import 'package:clearday/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyState shows title and message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            title: 'A clear day starts here',
            message: 'Add a task or chore.',
          ),
        ),
      ),
    );

    expect(find.text('A clear day starts here'), findsOneWidget);
    expect(find.text('Add a task or chore.'), findsOneWidget);
  });
}
