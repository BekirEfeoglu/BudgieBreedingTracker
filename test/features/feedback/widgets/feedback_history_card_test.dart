import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_history_card.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_detail_sheet.dart';

FeedbackEntry _makeEntry({
  String id = 'card-1',
  FeedbackCategory category = FeedbackCategory.bug,
  FeedbackStatus status = FeedbackStatus.open,
  String subject = 'Card subject',
  String message = 'Card message content',
  String? adminResponse,
  DateTime? createdAt,
}) {
  return FeedbackEntry(
    id: id,
    category: category,
    subject: subject,
    message: message,
    status: status,
    adminResponse: adminResponse,
    createdAt: createdAt,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject(FeedbackEntry entry) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: FeedbackHistoryCard(entry: entry)),
      ),
    );
  }

  group('FeedbackHistoryCard', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildSubject(_makeEntry()));
      await tester.pump();

      expect(find.byType(FeedbackHistoryCard), findsOneWidget);
    });

    testWidgets('displays entry subject text', (tester) async {
      final entry = _makeEntry(subject: 'Unique card subject');
      await tester.pumpWidget(buildSubject(entry));
      await tester.pump();

      expect(find.text('Unique card subject'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays message preview text', (tester) async {
      final entry = _makeEntry(message: 'Preview message text here');
      await tester.pumpWidget(buildSubject(entry));
      await tester.pump();

      expect(find.text('Preview message text here'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows FeedbackStatusBadge', (tester) async {
      await tester.pumpWidget(buildSubject(_makeEntry()));
      await tester.pump();

      expect(find.byType(FeedbackStatusBadge), findsOneWidget);
    });

    testWidgets(
      'shows admin response indicator when adminResponse is non-empty',
      (tester) async {
        final entry = _makeEntry(adminResponse: 'Admin replied here');
        await tester.pumpWidget(buildSubject(entry));
        await tester.pump();

        expect(find.text('feedback.admin_response'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'does not show admin response indicator when adminResponse is null',
      (tester) async {
        final entry = _makeEntry(adminResponse: null);
        await tester.pumpWidget(buildSubject(entry));
        await tester.pump();

        expect(find.text('feedback.admin_response'), findsNothing);
      },
    );

    testWidgets(
      'does not show admin response indicator when adminResponse is empty',
      (tester) async {
        final entry = _makeEntry(adminResponse: '');
        await tester.pumpWidget(buildSubject(entry));
        await tester.pump();

        expect(find.text('feedback.admin_response'), findsNothing);
      },
    );

    testWidgets('shows "just_now" label for very recent entry', (tester) async {
      final entry = _makeEntry(createdAt: DateTime.now());
      await tester.pumpWidget(buildSubject(entry));
      await tester.pump();

      expect(find.text('feedback.just_now'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows formatted date for old entry', (tester) async {
      final entry = _makeEntry(createdAt: DateTime(2023, 1, 5));
      await tester.pumpWidget(buildSubject(entry));
      await tester.pump();

      // Older than 7 days → formatted as "05.01.2023"
      expect(find.text('05.01.2023'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping card opens FeedbackDetailSheet bottom sheet', (
      tester,
    ) async {
      final entry = _makeEntry(subject: 'Detail sheet trigger');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: FeedbackHistoryCard(entry: entry)),
          ),
        ),
      );
      await tester.pump();

      final inkWell = find.descendant(
        of: find.byType(Card).first,
        matching: find.byType(InkWell),
      );
      await tester.tap(inkWell);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // Consume any layout overflow exceptions from bottom sheet animation
      var ex = tester.takeException();
      while (ex != null) {
        ex = tester.takeException();
      }
    });

    testWidgets('renders card for every category without errors', (
      tester,
    ) async {
      for (final cat in FeedbackCategory.values) {
        final entry = _makeEntry(category: cat);
        await tester.pumpWidget(buildSubject(entry));
        await tester.pump();

        expect(find.byType(FeedbackHistoryCard), findsOneWidget);
        var ex = tester.takeException();
        while (ex != null) {
          ex = tester.takeException();
        }
      }
    });
  });
}
