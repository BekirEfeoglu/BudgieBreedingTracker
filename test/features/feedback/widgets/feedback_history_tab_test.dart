import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/providers/feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_history_tab.dart';
import 'package:budgie_breeding_tracker/features/feedback/widgets/feedback_history_card.dart';

FeedbackEntry _makeEntry(String id) {
  return FeedbackEntry(
    id: id,
    category: FeedbackCategory.bug,
    subject: 'Subject $id',
    message: 'Message $id',
    status: FeedbackStatus.open,
    createdAt: DateTime(2024, 6, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testUserId = 'test-user-123';

  Widget buildSubject({required AsyncValue<List<FeedbackEntry>> historyValue}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(testUserId),
        feedbackHistoryProvider(testUserId).overrideWithValue(historyValue),
      ],
      child: const MaterialApp(home: Scaffold(body: FeedbackHistoryTab())),
    );
  }

  group('FeedbackHistoryTab', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(buildSubject(historyValue: const AsyncLoading()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows FeedbackHistoryEmpty when data is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(historyValue: const AsyncData([])));
      await tester.pump();

      expect(find.byType(FeedbackHistoryEmpty), findsOneWidget);
    });

    testWidgets('shows no_submissions text in empty state', (tester) async {
      await tester.pumpWidget(buildSubject(historyValue: const AsyncData([])));
      await tester.pump();

      expect(find.text('feedback.no_submissions'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows no_submissions_hint text in empty state', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(historyValue: const AsyncData([])));
      await tester.pump();

      expect(
        find.text('feedback.no_submissions_hint'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows list of FeedbackHistoryCards when data is non-empty', (
      tester,
    ) async {
      final entries = [_makeEntry('1'), _makeEntry('2'), _makeEntry('3')];
      await tester.pumpWidget(buildSubject(historyValue: AsyncData(entries)));
      await tester.pump();

      expect(find.byType(FeedbackHistoryCard), findsNWidgets(3));
    });

    testWidgets('shows error state when history fails to load', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          historyValue: const AsyncError('Network error', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.byType(FeedbackHistoryError), findsOneWidget);
    });

    testWidgets('error state shows retry button', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          historyValue: const AsyncError('timeout', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.text('common.retry'), findsAtLeastNWidgets(1));
    });

    testWidgets('error state shows history_error key text', (tester) async {
      await tester.pumpWidget(
        buildSubject(historyValue: const AsyncError('boom', StackTrace.empty)),
      );
      await tester.pump();

      expect(find.text('feedback.history_error'), findsAtLeastNWidgets(1));
    });

    testWidgets('RefreshIndicator wraps the list', (tester) async {
      final entries = [_makeEntry('a'), _makeEntry('b')];
      await tester.pumpWidget(buildSubject(historyValue: AsyncData(entries)));
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('FeedbackHistoryEmpty', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackHistoryEmpty(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FeedbackHistoryEmpty), findsOneWidget);
    });
  });

  group('FeedbackHistoryError', () {
    testWidgets('calls onRetry when retry button tapped', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FeedbackHistoryError(onRetry: () => retryCalled = true),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(retryCalled, isTrue);
    });
  });
}
