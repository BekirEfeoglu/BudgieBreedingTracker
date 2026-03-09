import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';

void main() {
  testWidgets('shows error message and retry button', (tester) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorState(
            message: 'Something failed',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Something failed'), findsOneWidget);
    expect(find.byIcon(LucideIcons.alertCircle), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(retried, isTrue);
  });
}
