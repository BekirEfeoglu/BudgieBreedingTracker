import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_detail_sheet.dart';

import '../../../helpers/test_localization.dart';
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
      await pumpLocalizedApp(tester,
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackStatusBadge(status: FeedbackStatus.open),
            ),
          ),
        ),
      );
      expect(find.byType(FeedbackStatusBadge), findsOneWidget);
    });

    testWidgets('renders for every status without errors', (tester) async {
      for (final status in FeedbackStatus.values) {
        await pumpLocalizedApp(tester,
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: FeedbackStatusBadge(status: status)),
            ),
          ),
        );
        expect(find.byType(FeedbackStatusBadge), findsOneWidget);
      }
    });

    testWidgets('shows status label text', (tester) async {
      await pumpLocalizedApp(tester,
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackStatusBadge(status: FeedbackStatus.resolved),
            ),
          ),
        ),
      );
      expect(find.text(FeedbackStatus.resolved.label), findsAtLeastNWidgets(1));
    });
  });

  group('FeedbackDetailSheet', () {
    testWidgets('renders without errors', (tester) async {
      await pumpLocalizedApp(tester,buildSubject(_makeEntry()));
      expect(find.byType(FeedbackDetailSheet), findsOneWidget);
    });

    testWidgets('displays subject text', (tester) async {
      final entry = _makeEntry(subject: 'My test subject');
      await pumpLocalizedApp(tester,buildSubject(entry));
      expect(find.text('My test subject'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays message text', (tester) async {
      final entry = _makeEntry(message: 'Detailed message here');
      await pumpLocalizedApp(tester,buildSubject(entry));
      expect(find.text('Detailed message here'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows FeedbackStatusBadge for the entry status', (
      tester,
    ) async {
      final entry = _makeEntry(status: FeedbackStatus.inProgress);
      await pumpLocalizedApp(tester,buildSubject(entry));
      expect(find.byType(FeedbackStatusBadge), findsOneWidget);
    });

    testWidgets(
      'shows admin response section when adminResponse is non-empty',
      (tester) async {
        final entry = _makeEntry(adminResponse: 'We are working on it!');
        await pumpLocalizedApp(tester,buildSubject(entry));
        expect(find.text('We are working on it!'), findsAtLeastNWidgets(1));
        // admin_response key label
        expect(find.text('feedback.admin_response'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'does not show admin response section when adminResponse is null',
      (tester) async {
        final entry = _makeEntry(adminResponse: null);
        await pumpLocalizedApp(tester,buildSubject(entry));
        expect(find.text('feedback.admin_response'), findsNothing);
      },
    );

    testWidgets('shows formatted date when createdAt is set', (tester) async {
      final entry = _makeEntry(createdAt: DateTime(2024, 6, 15, 10, 30));
      await pumpLocalizedApp(tester,buildSubject(entry));
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
      await pumpLocalizedApp(tester,buildSubject(entry));
      expect(find.byType(FeedbackDetailSheet), findsOneWidget);
    });
  });
}
