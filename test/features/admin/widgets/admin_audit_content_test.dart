import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_models.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_audit_content.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';

// 'admin-1' is 7 chars — not truncated, shown as-is
final _testLog = AdminLog(
  id: 'log-1',
  action: 'user_login',
  adminUserId: 'admin-1',
  createdAt: DateTime(2024, 1, 15, 10, 30),
);

// IDs > 8 chars get '...' suffix via _truncateId
final _deleteLog = AdminLog(
  id: 'log-2',
  action: 'delete_user',
  adminUserId: 'admin-longid', // 12 chars → 'admin-lo...'
  targetUserId: 'target-xyz123', // 13 chars → 'target-x...'
  details: 'User removed for policy violation',
  createdAt: DateTime(2024, 1, 15, 11, 0),
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
  });

  group('AuditContent', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(AuditContent(logs: [_testLog])));
      await tester.pump();
      expect(find.byType(AuditContent), findsOneWidget);
    });

    testWidgets('shows EmptyState when logs are empty', (tester) async {
      await tester.pumpWidget(_wrap(const AuditContent(logs: [])));
      await tester.pump();
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows CustomScrollView when logs are non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(AuditContent(logs: [_testLog])));
      await tester.pump();
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('shows AuditSummary when logs are non-empty', (tester) async {
      await tester.pumpWidget(_wrap(AuditContent(logs: [_testLog])));
      await tester.pump();
      expect(find.byType(AuditSummary), findsOneWidget);
    });

    testWidgets('shows clear logs button when callback provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AuditContent(logs: [_testLog], onClearLogs: () {})),
      );
      await tester.pump();
      expect(find.text(l10n('admin.clear_old_logs')), findsOneWidget);
    });

    testWidgets('hides clear logs button when callback is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(AuditContent(logs: [_testLog])));
      await tester.pump();
      expect(find.text(l10n('admin.clear_old_logs')), findsNothing);
    });

    testWidgets('shows load more button when hasMore is true', (tester) async {
      await tester.pumpWidget(
        _wrap(AuditContent(logs: [_testLog], hasMore: true, onLoadMore: () {})),
      );
      await tester.pump();
      expect(find.text(l10n('admin.load_more')), findsOneWidget);
    });

    testWidgets('hides load more button when hasMore is false', (tester) async {
      await tester.pumpWidget(
        _wrap(AuditContent(logs: [_testLog], hasMore: false)),
      );
      await tester.pump();
      expect(find.text(l10n('admin.load_more')), findsNothing);
    });

    testWidgets('triggers onClearLogs callback on tap', (tester) async {
      var called = false;
      await tester.pumpWidget(
        _wrap(AuditContent(logs: [_testLog], onClearLogs: () => called = true)),
      );
      await tester.pump();
      await tester.tap(find.text(l10n('admin.clear_old_logs')));
      expect(called, isTrue);
    });
  });

  group('AuditSummary', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const AuditSummary(totalLogs: 5)));
      await tester.pump();
      expect(find.byType(AuditSummary), findsOneWidget);
    });

    testWidgets('shows total logs count as text', (tester) async {
      await tester.pumpWidget(_wrap(const AuditSummary(totalLogs: 42)));
      await tester.pump();
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows admin.total_entries label', (tester) async {
      await tester.pumpWidget(_wrap(const AuditSummary(totalLogs: 0)));
      await tester.pump();
      expect(find.text(l10n('admin.total_entries')), findsOneWidget);
    });
  });

  group('AuditLogItem', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(AuditLogItem(log: _testLog)));
      await tester.pump();
      expect(find.byType(AuditLogItem), findsOneWidget);
    });

    testWidgets('shows action text', (tester) async {
      await tester.pumpWidget(_wrap(AuditLogItem(log: _testLog)));
      await tester.pump();
      expect(find.text('user_login'), findsOneWidget);
    });

    testWidgets('shows details when provided', (tester) async {
      await tester.pumpWidget(_wrap(AuditLogItem(log: _deleteLog)));
      await tester.pump();
      expect(find.text('User removed for policy violation'), findsOneWidget);
    });

    testWidgets('shows adminUserId when provided (short id, not truncated)', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(AuditLogItem(log: _testLog)));
      await tester.pump();
      // 'admin-1' is 7 chars (<=8), not truncated
      expect(find.textContaining('admin-1'), findsOneWidget);
    });

    testWidgets('shows targetUserId when provided (truncated)', (tester) async {
      await tester.pumpWidget(_wrap(AuditLogItem(log: _deleteLog)));
      await tester.pump();
      // 'target-xyz123' is 13 chars → first 8: 'target-x...'
      expect(find.textContaining('target-x...'), findsOneWidget);
    });

    testWidgets('renders without details when details is null', (tester) async {
      await tester.pumpWidget(_wrap(AuditLogItem(log: _testLog)));
      await tester.pump();
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders Card for each log item in AuditContent', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AuditContent(logs: [_testLog, _deleteLog])),
      );
      await tester.pump();
      // 1 AuditSummary card + 2 AuditLogItem cards = at least 3
      expect(find.byType(Card), findsAtLeastNWidgets(3));
    });

    // Icon rendering tests — _iconForAction uses AdminActionType.fromJson
    // delete/remove actions → AppIcon(AppIcons.delete) (SVG widget)
    // create/add actions   → AppIcon(AppIcons.add)    (SVG widget)
    // login actions        → Icon(LucideIcons.logIn)
    // logout actions       → Icon(LucideIcons.logOut)
    // unknown actions      → AppIcon(AppIcons.audit)  (SVG widget)

    testWidgets('renders AppIcon for delete action', (tester) async {
      final deleteLog = AdminLog(
        id: 'log-del',
        action: 'delete_user',
        createdAt: DateTime(2024, 1, 15),
      );
      await tester.pumpWidget(_wrap(AuditLogItem(log: deleteLog)));
      await tester.pump();
      // delete → AppIcon(AppIcons.delete) SVG widget
      expect(find.byType(AppIcon), findsWidgets);
    });

    testWidgets('renders AppIcon for create action', (tester) async {
      final createLog = AdminLog(
        id: 'log-crt',
        action: 'create_bird',
        createdAt: DateTime(2024, 1, 15),
      );
      await tester.pumpWidget(_wrap(AuditLogItem(log: createLog)));
      await tester.pump();
      // create → AppIcon(AppIcons.add) SVG widget
      expect(find.byType(AppIcon), findsWidgets);
    });

    testWidgets('renders logIn icon for login action', (tester) async {
      final loginLog = AdminLog(
        id: 'log-login',
        action: 'user_login',
        createdAt: DateTime(2024, 1, 15),
      );
      await tester.pumpWidget(_wrap(AuditLogItem(log: loginLog)));
      await tester.pump();
      expect(find.byIcon(LucideIcons.logIn), findsOneWidget);
    });

    testWidgets('renders logOut icon for logout action', (tester) async {
      final logoutLog = AdminLog(
        id: 'log-logout',
        action: 'user_logout',
        createdAt: DateTime(2024, 1, 15),
      );
      await tester.pumpWidget(_wrap(AuditLogItem(log: logoutLog)));
      await tester.pump();
      expect(find.byIcon(LucideIcons.logOut), findsOneWidget);
    });

    testWidgets('renders xCircle icon for revoke premium action', (
      tester,
    ) async {
      final revokeLog = AdminLog(
        id: 'log-revoke',
        action: 'revoke_premium',
        createdAt: DateTime(2024, 1, 15),
      );
      await tester.pumpWidget(_wrap(AuditLogItem(log: revokeLog)));
      await tester.pump();
      expect(find.byIcon(LucideIcons.xCircle), findsOneWidget);
    });

    testWidgets('renders toggleLeft icon for toggle_active action', (
      tester,
    ) async {
      final toggleLog = AdminLog(
        id: 'log-toggle',
        action: 'toggle_active',
        createdAt: DateTime(2024, 1, 15),
      );
      await tester.pumpWidget(_wrap(AuditLogItem(log: toggleLog)));
      await tester.pump();
      expect(find.byIcon(LucideIcons.toggleLeft), findsOneWidget);
    });
  });
}
