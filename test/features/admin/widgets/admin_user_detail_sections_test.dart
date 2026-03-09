import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_user_detail_sections.dart';

final _log1 = AdminLog(
  id: 'log-1',
  action: 'password_changed',
  createdAt: DateTime(2024, 2, 10, 9, 0),
);

final _log2 = AdminLog(
  id: 'log-2',
  action: 'email_verified',
  details: 'User verified email successfully',
  createdAt: DateTime(2024, 2, 11, 15, 30),
);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('UserDetailActivityLogSection', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(const UserDetailActivityLogSection(logs: [])),
      );
      await tester.pump();
      expect(find.byType(UserDetailActivityLogSection), findsOneWidget);
    });

    testWidgets('shows activity log title', (tester) async {
      await tester.pumpWidget(
        _wrap(const UserDetailActivityLogSection(logs: [])),
      );
      await tester.pump();
      expect(find.text('admin.activity_log'), findsOneWidget);
    });

    testWidgets('shows admin.no_activity when logs are empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const UserDetailActivityLogSection(logs: [])),
      );
      await tester.pump();
      expect(find.text('admin.no_activity'), findsOneWidget);
    });

    testWidgets('hides no_activity text when logs present', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailActivityLogSection(logs: [_log1])),
      );
      await tester.pump();
      expect(find.text('admin.no_activity'), findsNothing);
    });

    testWidgets('shows action text of log', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailActivityLogSection(logs: [_log1])),
      );
      await tester.pump();
      expect(find.text('password_changed'), findsOneWidget);
    });

    testWidgets('shows details text when details is present', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailActivityLogSection(logs: [_log2])),
      );
      await tester.pump();
      expect(find.text('User verified email successfully'), findsOneWidget);
    });

    testWidgets('shows multiple log items', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailActivityLogSection(logs: [_log1, _log2])),
      );
      await tester.pump();
      expect(find.text('password_changed'), findsOneWidget);
      expect(find.text('email_verified'), findsOneWidget);
    });

    testWidgets('uses ListView.builder for non-empty logs', (tester) async {
      await tester.pumpWidget(
        _wrap(UserDetailActivityLogSection(logs: [_log1, _log2])),
      );
      await tester.pump();
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('does not use ListView for empty logs', (tester) async {
      await tester.pumpWidget(
        _wrap(const UserDetailActivityLogSection(logs: [])),
      );
      await tester.pump();
      expect(find.byType(ListView), findsNothing);
    });
  });
}
