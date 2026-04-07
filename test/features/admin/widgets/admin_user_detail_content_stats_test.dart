import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_user_detail_content.dart';

import '../../../helpers/test_localization.dart';

final _detail = AdminUserDetail(
  id: 'u1',
  email: 'test@example.com',
  createdAt: DateTime(2024, 1, 1),
  birdsCount: 10,
  pairsCount: 3,
  eggsCount: 15,
  chicksCount: 7,
  healthRecordsCount: 4,
  eventsCount: 20,
);

Widget _wrap(AdminUserDetail detail) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: UserDetailStatsRow(detail: detail),
      ),
    ),
  );
}

void main() {
  group('UserDetailStatsRow', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_detail));
      expect(find.byType(UserDetailStatsRow), findsOneWidget);
    });

    testWidgets('shows entity summary title', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_detail));
      expect(
        find.textContaining(l10n('admin.entity_summary')),
        findsOneWidget,
      );
    });

    testWidgets('displays birds count', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_detail));
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('displays pairs count', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_detail));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('displays eggs count', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_detail));
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('displays chicks count', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_detail));
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('displays health records count', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_detail));
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('displays events count', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_detail));
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('shows label localization keys', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_detail));
      expect(find.textContaining(l10n('admin.birds')), findsOneWidget);
      expect(find.textContaining(l10n('admin.pairs_count')), findsOneWidget);
      expect(find.textContaining(l10n('admin.eggs_count')), findsOneWidget);
      expect(find.textContaining(l10n('admin.chicks_count')), findsOneWidget);
      expect(find.textContaining(l10n('admin.health_records_count')), findsOneWidget);
      expect(find.textContaining(l10n('admin.events_count')), findsOneWidget);
    });

    testWidgets('renders with zero counts', (tester) async {
      final emptyDetail = AdminUserDetail(
        id: 'u2',
        email: 'empty@example.com',
        createdAt: DateTime(2024, 1, 1),
      );
      await pumpLocalizedApp(tester, _wrap(emptyDetail));
      expect(find.byType(UserDetailStatsRow), findsOneWidget);
      // All counts default to 0
      expect(find.text('0'), findsNWidgets(6));
    });
  });
}
