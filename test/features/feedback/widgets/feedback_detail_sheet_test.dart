import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_detail_sheet.dart';

void _consumeExceptions(WidgetTester tester) {
  var ex = tester.takeException();
  while (ex != null) {
    ex = tester.takeException();
  }
}

FeedbackEntry _makeEntry({
  FeedbackCategory category = FeedbackCategory.bug,
  FeedbackStatus status = FeedbackStatus.open,
  String subject = 'Test subject',
  String message = 'Test message body',
  String? adminResponse,
  DateTime? createdAt,
}) {
  return FeedbackEntry(
    id: 'test-id-1',
    category: category,
    subject: subject,
    message: message,
    status: status,
    adminResponse: adminResponse,
    createdAt: createdAt ?? DateTime(2024, 6, 15, 10, 30),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject(FeedbackEntry entry) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FeedbackDetailSheet(
                entry: entry,
                scrollController: ScrollController(),
              );
            },
          ),
        ),
      ),
    );
  }

  group('FeedbackStatusBadge', () {
    testWidgets('renders for open status', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackStatusBadge(status: FeedbackStatus.open),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FeedbackStatusBadge), findsOneWidget);
    });

    testWidgets('renders for every status without errors', (tester) async {
      for (final status in FeedbackStatus.values) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: FeedbackStatusBadge(status: status)),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(FeedbackStatusBadge), findsOneWidget);
        _consumeExceptions(tester);
      }
    });

    testWidgets('shows status label text', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackStatusBadge(status: FeedbackStatus.resolved),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(FeedbackStatus.resolved.label), findsAtLeastNWidgets(1));
    });
  });

  group('FeedbackDetailSheet', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildSubject(_makeEntry()));
      await tester.pump();

      expect(find.byType(FeedbackDetailSheet), findsOneWidget);
    });

    testWidgets('displays subject text', (tester) async {
      final entry = _makeEntry(subject: 'My test subject');
      await tester.pumpWidget(buildSubject(entry));
      await tester.pump();

      expect(find.text('My test subject'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays message text', (tester) async {
      final entry = _makeEntry(message: 'Detailed message here');
      await tester.pumpWidget(buildSubject(entry));
      await tester.pump();

      expect(find.text('Detailed message here'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows FeedbackStatusBadge for the entry status', (
      tester,
    ) async {
      final entry = _makeEntry(status: FeedbackStatus.inProgress);
      await tester.pumpWidget(buildSubject(entry));
      await tester.pump();

      expect(find.byType(FeedbackStatusBadge), findsOneWidget);
    });

    testWidgets(
      'shows admin response section when adminResponse is non-empty',
      (tester) async {
        final entry = _makeEntry(adminResponse: 'We are working on it!');
        await tester.pumpWidget(buildSubject(entry));
        await tester.pump();

        expect(find.text('We are working on it!'), findsAtLeastNWidgets(1));
        // admin_response key label
        expect(find.text('feedback.admin_response'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'does not show admin response section when adminResponse is null',
      (tester) async {
        final entry = _makeEntry(adminResponse: null);
        await tester.pumpWidget(buildSubject(entry));
        await tester.pump();

        expect(find.text('feedback.admin_response'), findsNothing);
      },
    );

    testWidgets('shows formatted date when createdAt is set', (tester) async {
      final entry = _makeEntry(createdAt: DateTime(2024, 6, 15, 10, 30));
      await tester.pumpWidget(buildSubject(entry));
      await tester.pump();

      // Expect date formatted as "15.06.2024 10:30"
      expect(find.text('15.06.2024 10:30'), findsAtLeastNWidgets(1));
    });

    testWidgets('does not crash when createdAt is null', (tester) async {
      const entry = FeedbackEntry(
        id: 'no-date',
        category: FeedbackCategory.general,
        subject: 'No date',
        message: 'Message',
        status: FeedbackStatus.open,
        createdAt: null,
      );
      await tester.pumpWidget(buildSubject(entry));
      await tester.pump();

      expect(find.byType(FeedbackDetailSheet), findsOneWidget);
      _consumeExceptions(tester);
    });
  });
}
