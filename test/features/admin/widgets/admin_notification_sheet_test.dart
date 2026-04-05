import 'dart:async';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_actions_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_notification_sheet.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_localization.dart';

/// Stub notifier that records calls and allows controlling success/error state.
class _StubAdminActionsNotifier extends Notifier<AdminActionState>
    implements AdminActionsNotifier {
  bool sendNotificationCalled = false;
  bool sendBulkNotificationCalled = false;
  String? capturedTargetUserId;
  List<String>? capturedTargetUserIds;
  String? capturedTitle;
  String? capturedBody;
  bool shouldSucceed = true;

  @override
  AdminActionState build() => const AdminActionState();

  @override
  Future<void> sendNotification(
    String targetUserId,
    String title,
    String body,
  ) async {
    sendNotificationCalled = true;
    capturedTargetUserId = targetUserId;
    capturedTitle = title;
    capturedBody = body;
    if (shouldSucceed) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: 'Notification sent',
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Send failed',
      );
    }
  }

  @override
  Future<void> sendBulkNotification(
    List<String> userIds,
    String title,
    String body,
  ) async {
    sendBulkNotificationCalled = true;
    capturedTargetUserIds = userIds;
    capturedTitle = title;
    capturedBody = body;
    if (shouldSucceed) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        successMessage: 'Bulk sent',
      );
    } else {
      state = state.copyWith(isLoading: false, error: 'Bulk send failed');
    }
  }

  @override
  void reset() => state = const AdminActionState();

  // Stubs for other AdminActionsNotifier methods we don't test here.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Wrapper that opens the notification sheet on button press.
class _SheetLauncher extends ConsumerWidget {
  final String? targetUserId;
  final List<String>? targetUserIds;

  const _SheetLauncher({this.targetUserId, this.targetUserIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => showAdminNotificationSheet(
            context,
            ref: ref,
            targetUserId: targetUserId,
            targetUserIds: targetUserIds,
          ),
          child: const Text('Open'),
        ),
      ),
    );
  }
}

Widget _buildApp({
  _StubAdminActionsNotifier? notifier,
  String? targetUserId,
  List<String>? targetUserIds,
}) {
  final stub = notifier ?? _StubAdminActionsNotifier();
  return ProviderScope(
    overrides: [
      adminActionsProvider.overrideWith(() => stub),
    ],
    child: MaterialApp(
      home: _SheetLauncher(
        targetUserId: targetUserId,
        targetUserIds: targetUserIds,
      ),
    ),
  );
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  group('AdminNotificationSheet', () {
    testWidgets('renders title and form fields for single user', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        _buildApp(targetUserId: 'user-1'),
      );
      await _openSheet(tester);

      expect(
        find.text(l10n('admin.send_notification')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('admin.notification_title_label')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('admin.notification_message_label')),
        findsOneWidget,
      );
      expect(find.text(l10n('admin.send')), findsOneWidget);
    });

    testWidgets('renders bulk title with user count', (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildApp(targetUserIds: ['u1', 'u2', 'u3']),
      );
      await _openSheet(tester);

      expect(
        find.text(l10n('admin.bulk_send_notification')),
        findsOneWidget,
      );
      // Shows "3 admin.users"
      expect(find.textContaining('3'), findsAtLeastNWidgets(1));
    });

    testWidgets('validates empty title', (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildApp(targetUserId: 'user-1'),
      );
      await _openSheet(tester);

      // Tap send without filling fields
      await tester.tap(find.text(l10n('admin.send')));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('admin.notification_title_required')),
        findsOneWidget,
      );
    });

    testWidgets('validates empty message', (tester) async {
      await pumpLocalizedApp(
        tester,
        _buildApp(targetUserId: 'user-1'),
      );
      await _openSheet(tester);

      // Fill title only
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test Title',
      );
      await tester.tap(find.text(l10n('admin.send')));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('admin.notification_message_required')),
        findsOneWidget,
      );
    });

    testWidgets('calls sendNotification on valid submit', (tester) async {
      final notifier = _StubAdminActionsNotifier();
      await pumpLocalizedApp(
        tester,
        _buildApp(targetUserId: 'user-1', notifier: notifier),
      );
      await _openSheet(tester);

      // Fill title
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test Title',
      );
      // Fill message
      await tester.enterText(
        find.byType(TextFormField).last,
        'Test Message',
      );
      await tester.tap(find.text(l10n('admin.send')));
      await tester.pumpAndSettle();

      expect(notifier.sendNotificationCalled, isTrue);
      expect(notifier.capturedTargetUserId, 'user-1');
      expect(notifier.capturedTitle, 'Test Title');
      expect(notifier.capturedBody, 'Test Message');
    });

    testWidgets('calls sendBulkNotification for bulk mode', (tester) async {
      final notifier = _StubAdminActionsNotifier();
      await pumpLocalizedApp(
        tester,
        _buildApp(
          targetUserIds: ['u1', 'u2'],
          notifier: notifier,
        ),
      );
      await _openSheet(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Bulk Title',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Bulk Message',
      );
      await tester.tap(find.text(l10n('admin.send')));
      await tester.pumpAndSettle();

      expect(notifier.sendBulkNotificationCalled, isTrue);
      expect(notifier.capturedTargetUserIds, ['u1', 'u2']);
      expect(notifier.capturedTitle, 'Bulk Title');
      expect(notifier.capturedBody, 'Bulk Message');
    });

    testWidgets('closes sheet on success', (tester) async {
      final notifier = _StubAdminActionsNotifier()..shouldSucceed = true;
      await pumpLocalizedApp(
        tester,
        _buildApp(targetUserId: 'user-1', notifier: notifier),
      );
      await _openSheet(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Title',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Message',
      );
      await tester.tap(find.text(l10n('admin.send')));
      await tester.pumpAndSettle();

      // Sheet should be dismissed — form fields gone
      expect(find.text(l10n('admin.notification_title_label')), findsNothing);
    });

    testWidgets('stays open and shows error snackbar on failure', (
      tester,
    ) async {
      final notifier = _StubAdminActionsNotifier()..shouldSucceed = false;
      await pumpLocalizedApp(
        tester,
        _buildApp(targetUserId: 'user-1', notifier: notifier),
      );
      await _openSheet(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Title',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Message',
      );
      await tester.tap(find.text(l10n('admin.send')));
      await tester.pumpAndSettle();

      // Sheet should still be visible
      expect(
        find.text(l10n('admin.notification_title_label')),
        findsOneWidget,
      );
      // Error snackbar shown
      expect(find.text('Send failed'), findsOneWidget);
    });

    testWidgets('send button is disabled while loading', (tester) async {
      // Use a notifier that never completes to keep loading state
      final notifier = _NeverCompletesNotifier();
      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            adminActionsProvider.overrideWith(() => notifier),
          ],
          child: const MaterialApp(
            home: _SheetLauncher(targetUserId: 'user-1'),
          ),
        ),
      );
      await _openSheet(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Title',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Message',
      );
      await tester.tap(find.text(l10n('admin.send')));
      await tester.pump(); // single frame — stays in loading

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

/// Notifier whose sendNotification never resolves (simulates slow network).
class _NeverCompletesNotifier extends Notifier<AdminActionState>
    implements AdminActionsNotifier {
  @override
  AdminActionState build() => const AdminActionState();

  @override
  Future<void> sendNotification(
    String targetUserId,
    String title,
    String body,
  ) {
    // Never completes — keeps the sheet in loading state
    return Completer<void>().future;
  }

  @override
  Future<void> sendBulkNotification(
    List<String> userIds,
    String title,
    String body,
  ) {
    return Completer<void>().future;
  }

  @override
  void reset() => state = const AdminActionState();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
