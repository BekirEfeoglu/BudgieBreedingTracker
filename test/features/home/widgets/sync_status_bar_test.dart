import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/sync_status_bar.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockSyncOrchestrator mockOrchestrator;

  setUp(() {
    mockOrchestrator = MockSyncOrchestrator();
    when(
      () => mockOrchestrator.fullSync(),
    ).thenAnswer((_) async => SyncResult.success);
  });

  Widget createSubject({SyncDisplayStatus status = SyncDisplayStatus.synced}) {
    return ProviderScope(
      overrides: [
        syncStatusProvider.overrideWithValue(status),
        syncOrchestratorProvider.overrideWithValue(mockOrchestrator),
      ],
      child: const MaterialApp(home: Scaffold(body: SyncStatusBar())),
    );
  }

  group('SyncStatusBar', () {
    testWidgets('renders without crashing when synced', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(SyncStatusBar), findsOneWidget);
    });

    testWidgets('shows synced label when idle', (tester) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.synced));
      await tester.pump();

      expect(find.text('sync.synced'), findsOneWidget);
    });

    testWidgets('shows cloud_done icon when synced', (tester) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.synced));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('shows syncing label when sync is in progress', (tester) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.syncing));
      await tester.pump();

      expect(find.text('sync.syncing'), findsOneWidget);
    });

    testWidgets('shows sync icon with rotation when syncing', (tester) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.syncing));
      await tester.pump();

      expect(find.byIcon(Icons.sync), findsOneWidget);
      // RotationTransition wrapping the sync icon inside SyncStatusBar
      expect(
        find.descendant(
          of: find.byType(SyncStatusBar),
          matching: find.byType(RotationTransition),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows offline label when offline', (tester) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.offline));
      await tester.pump();

      expect(find.text('sync.offline'), findsOneWidget);
    });

    testWidgets('shows cloud_off icon when offline', (tester) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.offline));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('shows error label when sync has error', (tester) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.error));
      await tester.pump();

      expect(find.text('sync.sync_error'), findsOneWidget);
    });

    testWidgets('shows cloud_off icon when error', (tester) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.error));
      await tester.pump();

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('does not show RotationTransition when not syncing', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.synced));
      await tester.pump();

      // Only check within SyncStatusBar scope to avoid MaterialApp internals
      expect(
        find.descendant(
          of: find.byType(SyncStatusBar),
          matching: find.byType(RotationTransition),
        ),
        findsNothing,
      );
    });

    testWidgets('has GestureDetector for tap interaction', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));
    });

    testWidgets('has Semantics with correct label', (tester) async {
      await tester.pumpWidget(createSubject(status: SyncDisplayStatus.synced));
      await tester.pump();

      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Row layout with icon and text', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(Row), findsAtLeastNWidgets(1));
      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
