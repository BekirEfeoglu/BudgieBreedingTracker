import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_feedback_screen.dart';

final _testFeedbackItems = [
  {
    'id': 'f-1',
    'type': 'bug',
    'status': 'open',
    'priority': 'high',
    'subject': 'App crashes on startup',
    'email': 'user1@test.com',
    'created_at': '2024-03-01T10:00:00Z',
  },
  {
    'id': 'f-2',
    'type': 'feature',
    'status': 'resolved',
    'priority': 'normal',
    'subject': 'Add dark mode',
    'email': 'user2@test.com',
    'created_at': '2024-03-02T11:00:00Z',
  },
  {
    'id': 'f-3',
    'type': 'general',
    'status': 'open',
    'priority': 'low',
    'subject': 'Great app!',
    'email': 'user3@test.com',
    'created_at': '2024-03-03T12:00:00Z',
  },
];

Widget _createSubject({
  AsyncValue<List<Map<String, dynamic>>> feedbackAsync = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [adminFeedbackProvider.overrideWithValue(feedbackAsync)],
    child: const MaterialApp(home: AdminFeedbackScreen()),
  );
}

void main() {
  group('AdminFeedbackScreen', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(AdminFeedbackScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with title', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.text('admin.feedback_admin'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when provider fails', (tester) async {
      await tester.pumpWidget(
        _createSubject(
          feedbackAsync: const AsyncError('fetch error', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.text('common.data_load_error'), findsOneWidget);
    });

    testWidgets('shows status filter bar when data loaded', (tester) async {
      await tester.pumpWidget(
        _createSubject(feedbackAsync: AsyncData(_testFeedbackItems)),
      );
      await tester.pump();

      expect(find.byType(FilterChip), findsAtLeastNWidgets(1));
    });

    testWidgets('shows feedback items when data loaded', (tester) async {
      await tester.pumpWidget(
        _createSubject(feedbackAsync: AsyncData(_testFeedbackItems)),
      );
      await tester.pump();

      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state when no items', (tester) async {
      await tester.pumpWidget(
        _createSubject(feedbackAsync: const AsyncData([])),
      );
      await tester.pump();

      expect(find.text('admin.no_feedback'), findsOneWidget);
    });

    testWidgets('shows item count in filter bar', (tester) async {
      await tester.pumpWidget(
        _createSubject(feedbackAsync: AsyncData(_testFeedbackItems)),
      );
      await tester.pump();

      // feedback_count renders total count
      expect(
        find.textContaining(_testFeedbackItems.length.toString()),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows status filter chips', (tester) async {
      await tester.pumpWidget(
        _createSubject(feedbackAsync: AsyncData(_testFeedbackItems)),
      );
      await tester.pump();

      expect(find.text('admin.feedback_status_all'), findsOneWidget);
    });

    testWidgets('shows refresh icon button in AppBar', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();

      expect(find.byType(IconButton), findsAtLeastNWidgets(1));
    });
  });
}
