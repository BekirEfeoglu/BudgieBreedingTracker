import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart'
    show SyncErrorDetail;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/widgets/sync_detail_sheet.dart';

import '../../../helpers/test_localization.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSubject({
    List<SyncErrorDetail> pending = const [],
    List<SyncErrorDetail> errors = const [],
    List<SyncConflict> conflicts = const [],
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('user-1'),
        pendingByTableProvider('user-1').overrideWith(
          (_) => Stream.value(pending),
        ),
        syncErrorDetailsProvider('user-1').overrideWith(
          (_) => Stream.value(errors),
        ),
        conflictHistoryProvider.overrideWith(
          () => _FakeConflictNotifier(conflicts),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSyncDetailSheet(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  group('SyncDetailSheet', () {
    testWidgets('opens bottom sheet with title', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('sync.error_details_title'), findsOneWidget);
    });

    testWidgets('shows close button', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.x), findsOneWidget);
    });

    testWidgets('shows empty state when no data', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('sync.no_errors'), findsOneWidget);
      expect(find.byIcon(LucideIcons.checkCircle), findsOneWidget);
    });

    testWidgets('shows sync now button', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('sync.sync_now_action'), findsOneWidget);
    });

    testWidgets('hides clear conflict button when no conflicts', (
      tester,
    ) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('sync.clear_conflict_history'), findsNothing);
    });

    testWidgets('shows clear conflict button when conflicts exist', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          conflicts: [
            SyncConflict(
              table: 'birds',
              recordId: 'r-1',
              detectedAt: DateTime.now(),
              description: 'Server overwrote local bird',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('sync.clear_conflict_history'), findsOneWidget);
    });

    testWidgets('shows pending section when pending records exist', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          pending: [
            const SyncErrorDetail(
              tableName: 'birds',
              errorCount: 3,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('sync.pending_section'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows failed section when errors exist', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          errors: [
            const SyncErrorDetail(
              tableName: 'eggs',
              errorCount: 2,
              lastError: 'Network timeout',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('sync.failed_section'), findsOneWidget);
      expect(find.text('Network timeout'), findsOneWidget);
    });

    testWidgets('shows conflict description', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          conflicts: [
            SyncConflict(
              table: 'birds',
              recordId: 'r-1',
              detectedAt: DateTime.now(),
              description: 'Server overwrote local bird',
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Server overwrote local bird'), findsOneWidget);
      expect(find.text('sync.conflict_section'), findsOneWidget);
    });

    testWidgets('close button pops the bottom sheet', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      // Bottom sheet should be gone, title no longer visible
      expect(find.text('sync.error_details_title'), findsNothing);
    });
  });
}

class _FakeConflictNotifier extends ConflictHistoryNotifier {
  final List<SyncConflict> _initial;
  _FakeConflictNotifier(this._initial);

  @override
  List<SyncConflict> build() => _initial;
}
