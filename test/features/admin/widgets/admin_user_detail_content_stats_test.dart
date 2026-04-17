import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_user_detail_content.dart';

final _detail = AdminUserDetail(
  id: 'user-1',
  email: 'test@test.com',
  fullName: 'Test User',
  createdAt: DateTime(2024, 1, 15),
  birdsCount: 10,
  pairsCount: 3,
  eggsCount: 20,
  chicksCount: 5,
  healthRecordsCount: 8,
  eventsCount: 15,
);

final _emptyDetail = AdminUserDetail(
  id: 'user-2',
  email: 'empty@test.com',
  createdAt: DateTime(2024, 1, 1),
);

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));
}

void main() {
  group('UserDetailStatsRow', () {
    testWidgets('should_render_without_crashing', (tester) async {
      await tester.pumpWidget(_wrap(UserDetailStatsRow(detail: _detail)));
      await tester.pump();
      expect(find.byType(UserDetailStatsRow), findsOneWidget);
    });

    testWidgets('should_show_entity_summary_title', (tester) async {
      await tester.pumpWidget(_wrap(UserDetailStatsRow(detail: _detail)));
      await tester.pump();
      expect(find.text(l10n('admin.entity_summary')), findsOneWidget);
    });

    testWidgets('should_show_birds_count', (tester) async {
      await tester.pumpWidget(_wrap(UserDetailStatsRow(detail: _detail)));
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('should_show_pairs_count', (tester) async {
      await tester.pumpWidget(_wrap(UserDetailStatsRow(detail: _detail)));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should_show_eggs_count', (tester) async {
      await tester.pumpWidget(_wrap(UserDetailStatsRow(detail: _detail)));
      await tester.pump();
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('should_show_zero_counts_for_empty_detail', (tester) async {
      await tester.pumpWidget(_wrap(UserDetailStatsRow(detail: _emptyDetail)));
      await tester.pump();
      // All counts default to 0
      expect(find.text('0'), findsNWidgets(6));
    });

    testWidgets('should_show_all_six_stat_labels', (tester) async {
      await tester.pumpWidget(_wrap(UserDetailStatsRow(detail: _detail)));
      await tester.pump();
      expect(find.text(l10n('admin.birds')), findsOneWidget);
      expect(find.text(l10n('admin.pairs_count')), findsOneWidget);
      expect(find.text(l10n('admin.eggs_count')), findsOneWidget);
      expect(find.text(l10n('admin.chicks_count')), findsOneWidget);
      expect(find.text(l10n('admin.health_records_count')), findsOneWidget);
      expect(find.text(l10n('admin.events_count')), findsOneWidget);
    });
  });
}
