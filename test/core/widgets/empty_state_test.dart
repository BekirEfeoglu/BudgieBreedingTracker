import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';

void main() {
  testWidgets('shows message, icon and optional action button', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: const Icon(Icons.inbox),
            title: 'No data',
            subtitle: 'Try adding a record',
            actionLabel: 'Create',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No data'), findsOneWidget);
    expect(find.text('Try adding a record'), findsOneWidget);
    expect(find.byIcon(Icons.inbox), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
