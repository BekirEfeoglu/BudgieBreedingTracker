import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/screens/feedback_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        feedbackFormStateProvider.overrideWith(() => FeedbackFormNotifier()),
      ],
      child: const MaterialApp(home: FeedbackScreen()),
    );
  }

  group('FeedbackScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(FeedbackScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with feedback title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('feedback.title'), findsOneWidget);
    });

    testWidgets('shows two tab labels', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('feedback.new_feedback'), findsOneWidget);
      expect(find.text('feedback.my_submissions'), findsOneWidget);
    });

    testWidgets('shows text form fields on form tab', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Subject, message, and email fields
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows submit button', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('feedback.submit'), findsOneWidget);
    });

    testWidgets('shows TabBar widget', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOneWidget);
    });
  });
}
