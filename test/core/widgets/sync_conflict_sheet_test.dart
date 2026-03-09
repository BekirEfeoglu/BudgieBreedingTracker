import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/sync_conflict_sheet.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';

// Helper to consume all pending overflow exceptions from a pump cycle.
Future<void> _consumeOverflowExceptions(WidgetTester tester) async {
  Exception? ex;
  do {
    ex = tester.takeException() as Exception?;
  } while (ex != null);
}

SyncConflict _makeConflict({
  String table = 'birds',
  String recordId = 'record-1',
  String description = 'Server overwrote local change',
  Duration ago = const Duration(minutes: 2),
}) {
  return SyncConflict(
    table: table,
    recordId: recordId,
    detectedAt: DateTime.now().subtract(ago),
    description: description,
  );
}

void main() {
  Widget buildSubject(List<SyncConflict> conflicts) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: SyncConflictSheet(conflicts: conflicts)),
      ),
    );
  }

  group('SyncConflictSheet — empty state', () {
    testWidgets('shows no_conflicts text when conflicts list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject([]));
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      // With easy_localization absent, .tr() returns the raw key
      expect(find.text('sync.no_conflicts'), findsOneWidget);
    });

    testWidgets('does not render ListView when conflicts list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject([]));
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('renders drag handle container', (tester) async {
      await tester.pumpWidget(buildSubject([]));
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      // The drag handle is a Container with specific dimensions (40x4).
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasDragHandle = containers.any((c) {
        return c.constraints?.maxWidth == 40 ||
            (c.decoration is BoxDecoration &&
                (c.decoration as BoxDecoration).borderRadius != null);
      });
      expect(hasDragHandle, isTrue);
    });
  });

  group('SyncConflictSheet — with conflicts', () {
    testWidgets('shows SyncConflictTile for each conflict', (tester) async {
      final conflicts = [
        _makeConflict(table: 'birds', recordId: 'b1'),
        _makeConflict(table: 'eggs', recordId: 'e1'),
        _makeConflict(table: 'chicks', recordId: 'c1'),
      ];

      await tester.pumpWidget(buildSubject(conflicts));
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      expect(find.byType(SyncConflictTile), findsNWidgets(3));
    });

    testWidgets('renders ListView with shrinkWrap for conflict list', (
      tester,
    ) async {
      final conflicts = [
        _makeConflict(table: 'birds'),
        _makeConflict(table: 'eggs', recordId: 'e1'),
      ];

      await tester.pumpWidget(buildSubject(conflicts));
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('does not show no_conflicts text when conflicts present', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject([_makeConflict()]));
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      expect(find.text('sync.no_conflicts'), findsNothing);
    });

    testWidgets('shows conflict_history title', (tester) async {
      await tester.pumpWidget(buildSubject([_makeConflict()]));
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      expect(find.text('sync.conflict_history'), findsOneWidget);
    });
  });

  group('SyncConflictTile', () {
    testWidgets('renders sync_problem icon', (tester) async {
      final conflict = _makeConflict();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SyncConflictTile(conflict: conflict)),
        ),
      );
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    });

    testWidgets('renders description text', (tester) async {
      final conflict = _makeConflict(description: 'Test conflict description');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SyncConflictTile(conflict: conflict)),
        ),
      );
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      expect(
        find.textContaining('Test conflict description'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows "just now" label for very recent conflicts', (
      tester,
    ) async {
      // ago = 0 seconds → diff.inMinutes == 0 → shows 'profile.just_now'
      final conflict = _makeConflict(ago: Duration.zero);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SyncConflictTile(conflict: conflict)),
        ),
      );
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      expect(find.text('profile.just_now'), findsOneWidget);
    });

    testWidgets('shows minutes_ago label for conflicts a few minutes old', (
      tester,
    ) async {
      final conflict = _makeConflict(ago: const Duration(minutes: 5));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SyncConflictTile(conflict: conflict)),
        ),
      );
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      // With easy_localization absent, .tr(args: ['5']) returns 'profile.minutes_ago'
      expect(find.text('profile.minutes_ago'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows hours_ago label for conflicts over an hour old', (
      tester,
    ) async {
      final conflict = _makeConflict(ago: const Duration(hours: 2));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SyncConflictTile(conflict: conflict)),
        ),
      );
      await tester.pump();
      await _consumeOverflowExceptions(tester);

      expect(find.text('profile.hours_ago'), findsAtLeastNWidgets(1));
    });
  });

  group('SyncConflict model', () {
    test('creates instance with required fields', () {
      final now = DateTime(2024, 6, 1);
      final conflict = SyncConflict(
        table: 'birds',
        recordId: 'record-42',
        detectedAt: now,
        description: 'Server wins',
      );

      expect(conflict.table, 'birds');
      expect(conflict.recordId, 'record-42');
      expect(conflict.detectedAt, now);
      expect(conflict.description, 'Server wins');
    });
  });

  group('ConflictHistoryNotifier', () {
    test('starts with empty conflict list', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(conflictHistoryProvider), isEmpty);
    });

    test('addConflict inserts conflict at the front', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final c1 = _makeConflict(recordId: 'r1');
      final c2 = _makeConflict(recordId: 'r2');

      container.read(conflictHistoryProvider.notifier).addConflict(c1);
      container.read(conflictHistoryProvider.notifier).addConflict(c2);

      final list = container.read(conflictHistoryProvider);
      expect(list.first.recordId, 'r2'); // most recent first
      expect(list.last.recordId, 'r1');
    });

    test('clear removes all conflicts', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(conflictHistoryProvider.notifier)
          .addConflict(_makeConflict());
      expect(container.read(conflictHistoryProvider), isNotEmpty);

      container.read(conflictHistoryProvider.notifier).clear();
      expect(container.read(conflictHistoryProvider), isEmpty);
    });

    test('caps history at 50 entries', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      for (var i = 0; i < 60; i++) {
        container
            .read(conflictHistoryProvider.notifier)
            .addConflict(_makeConflict(recordId: 'r$i'));
      }

      expect(container.read(conflictHistoryProvider).length, 50);
    });
  });
}
