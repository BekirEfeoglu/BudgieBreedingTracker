import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/screens/admin_feedback_screen.dart';

Widget _createSubject({
  AsyncValue<List<Map<String, dynamic>>> feedbackData = const AsyncLoading(),
}) {
  return ProviderScope(
    overrides: [
      adminFeedbackProvider.overrideWithValue(feedbackData),
    ],
    child: const MaterialApp(
      home: Scaffold(body: AdminFeedbackScreen()),
    ),
  );
}

final _sampleFeedback = [
  {
    'id': 'fb-1',
    'type': 'bug',
    'status': 'open',
    'priority': 'high',
    'subject': 'App crashes on startup',
    'email': 'user@test.com',
    'created_at': '2024-03-15T10:30:00Z',
  },
  {
    'id': 'fb-2',
    'type': 'feature',
    'status': 'resolved',
    'priority': 'normal',
    'subject': 'Add dark mode',
    'email': 'user2@test.com',
    'created_at': '2024-03-14T09:00:00Z',
  },
  {
    'id': 'fb-3',
    'type': 'general',
    'status': 'open',
    'priority': 'low',
    'subject': 'Nice app',
    'created_at': '2024-03-13T08:00:00Z',
  },
];

void main() {
  group('AdminFeedbackScreen tiles', () {
    testWidgets('should_show_loading_when_data_is_loading', (tester) async {
      await tester.pumpWidget(_createSubject());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should_show_feedback_tiles_when_data_exists',
        (tester) async {
      await tester.pumpWidget(
        _createSubject(feedbackData: AsyncData(_sampleFeedback)),
      );
      await tester.pump();
      expect(find.text('App crashes on startup'), findsOneWidget);
      expect(find.text('Add dark mode'), findsOneWidget);
    });

    testWidgets('should_show_bug_type_label', (tester) async {
      await tester.pumpWidget(
        _createSubject(feedbackData: AsyncData(_sampleFeedback)),
      );
      await tester.pump();
      expect(find.text(l10n('admin.feedback_type_bug')), findsOneWidget);
    });

    testWidgets('should_show_resolved_check_icon', (tester) async {
      await tester.pumpWidget(
        _createSubject(feedbackData: AsyncData(_sampleFeedback)),
      );
      await tester.pump();
      // Resolved items show a checkCircle2 icon
      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('should_show_filter_bar_with_status_chips', (tester) async {
      await tester.pumpWidget(
        _createSubject(feedbackData: AsyncData(_sampleFeedback)),
      );
      await tester.pump();
      expect(find.text(l10n('admin.feedback_status_all')), findsOneWidget);
      expect(find.text(l10n('admin.feedback_status_open')), findsOneWidget);
      expect(
        find.text(l10n('admin.feedback_status_resolved')),
        findsOneWidget,
      );
    });
  });
}
