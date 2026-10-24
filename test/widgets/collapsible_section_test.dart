import 'package:clearday/widgets/collapsible_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CollapsibleSection reveals its child from Show', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              CollapsibleSection(
                title: 'App Skin',
                collapsedSubtitle: 'Current: Clear',
                expandedSubtitle: 'Try a different color.',
                child: Text('Ocean'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Current: Clear'), findsOneWidget);
    expect(find.text('Show'), findsOneWidget);
    final collapsedHeight = tester.getSize(find.byType(Card)).height;

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle();

    expect(find.text('Try a different color.'), findsOneWidget);
    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('Ocean'), findsOneWidget);
    expect(
      tester.getSize(find.byType(Card)).height,
      greaterThan(collapsedHeight),
    );
  });
}
