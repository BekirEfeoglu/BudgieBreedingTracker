import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_conflict_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/sync_conflict_badge.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

void main() {
  Widget subject({required bool hasConflict, String userId = 'user-1'}) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(userId),
        conflictExistsForRecordProvider.overrideWith(
          (ref, key) async => hasConflict,
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: RecordSyncConflictBadge(tableName: 'birds', recordId: 'bird-1'),
        ),
      ),
    );
  }

  group('RecordSyncConflictBadge', () {
    testWidgets('renders badge when record has conflict', (tester) async {
      await tester.pumpWidget(subject(hasConflict: true));
      await tester.pump();

      expect(find.text(l10n('sync.conflict_badge')), findsOneWidget);
    });

    testWidgets('stays hidden when record has no conflict', (tester) async {
      await tester.pumpWidget(subject(hasConflict: false));
      await tester.pump();

      expect(find.text(l10n('sync.conflict_badge')), findsNothing);
    });

    testWidgets('stays hidden without current user', (tester) async {
      await tester.pumpWidget(subject(hasConflict: true, userId: ''));
      await tester.pump();

      expect(find.text(l10n('sync.conflict_badge')), findsNothing);
    });
  });
}
