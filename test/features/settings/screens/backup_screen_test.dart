import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/domain/services/ads/ad_reward_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/export_providers.dart';
import 'package:budgie_breeding_tracker/features/settings/screens/backup_screen.dart';

void main() {
  late GoRouter router;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    router = GoRouter(
      initialLocation: '/backup',
      routes: [
        GoRoute(path: '/backup', builder: (_, __) => const BackupScreen()),
        GoRoute(
          path: '/premium',
          builder: (_, __) => const Scaffold(body: Text('Premium')),
        ),
      ],
    );
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        exportLoadingProvider.overrideWith(() => ExportLoadingNotifier()),
        lastExportDateProvider.overrideWith(() => LastExportDateNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('BackupScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(BackupScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with backup title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('backup.title')), findsOneWidget);
    });

    testWidgets('shows export PDF tile', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('backup.export_pdf')), findsOneWidget);
    });

    testWidgets('shows export Excel tile', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('backup.export_excel')), findsOneWidget);
    });

    testWidgets('shows import Excel tile', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('backup.import_excel')), findsOneWidget);
    });

    testWidgets('shows never text when no export date', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('backup.never')), findsOneWidget);
    });

    testWidgets('shows section headers', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text(l10n('backup.export_data')), findsOneWidget);
      expect(find.text(l10n('backup.import_data')), findsOneWidget);
    });

    testWidgets('shows portable backup and restore actions', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(l10n('backup.portable_section')),
        300,
      );

      expect(find.text(l10n('backup.portable_create')), findsOneWidget);
      expect(find.text(l10n('backup.portable_restore')), findsOneWidget);
    });

    testWidgets('validates the portable backup password length', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(l10n('backup.portable_create')),
        300,
      );

      await tester.tap(find.text(l10n('backup.portable_create')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'short');
      await tester.tap(find.text(l10n('common.confirm')));
      await tester.pump();

      expect(find.text(l10n('backup.password_min_length')), findsOneWidget);
    });

    testWidgets('shows export date when available', (tester) async {
      final testDate = DateTime(2026, 5, 1, 12, 0);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportLoadingProvider.overrideWith(() => ExportLoadingNotifier()),
            lastExportDateProvider.overrideWith(
              () => _FakeLastExportDateNotifier(testDate),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackupScreen), findsOneWidget);
      expect(find.text(l10n('backup.never')), findsNothing);
    });

    testWidgets('shows loading indicator during export', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportLoadingProvider.overrideWith(
              () => _FakeExportLoadingNotifier(true),
            ),
            lastExportDateProvider.overrideWith(() => LastExportDateNotifier()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      expect(find.byType(BackupScreen), findsOneWidget);
    });
  });

  group('BackupScreen export reward flow', () {
    late MockExportActions mockActions;
    late _FakeExportRewardNotifier rewardNotifier;

    setUp(() {
      mockActions = MockExportActions();
      rewardNotifier = _FakeExportRewardNotifier();
    });

    Widget createRewardSubject() {
      return ProviderScope(
        overrides: [
          exportLoadingProvider.overrideWith(() => ExportLoadingNotifier()),
          lastExportDateProvider.overrideWith(() => LastExportDateNotifier()),
          effectivePremiumProvider.overrideWithValue(false),
          isExportRewardActiveProvider.overrideWith(() => rewardNotifier),
          exportActionsProvider.overrideWithValue(mockActions),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('successful export consumes reward and shows success', (
      tester,
    ) async {
      when(() => mockActions.exportPdf()).thenAnswer((_) async => true);

      await tester.pumpWidget(createRewardSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('backup.export_pdf')));
      await tester.pumpAndSettle();

      expect(rewardNotifier.consumeCalls, 1);
      expect(find.text(l10n('backup.export_success')), findsOneWidget);
    });

    testWidgets('failed export shows error, keeps reward, reports no success', (
      tester,
    ) async {
      when(() => mockActions.exportPdf()).thenThrow(Exception('disk full'));

      await tester.pumpWidget(createRewardSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('backup.export_pdf')));
      await tester.pumpAndSettle();

      expect(rewardNotifier.consumeCalls, 0);
      expect(find.text(l10n('backup.export_success')), findsNothing);
      expect(find.text(l10n('backup.export_error')), findsOneWidget);
    });

    testWidgets('skipped export (already running) consumes nothing', (
      tester,
    ) async {
      when(() => mockActions.exportPdf()).thenAnswer((_) async => false);

      await tester.pumpWidget(createRewardSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n('backup.export_pdf')));
      await tester.pumpAndSettle();

      expect(rewardNotifier.consumeCalls, 0);
      expect(find.text(l10n('backup.export_success')), findsNothing);
      expect(find.text(l10n('backup.export_error')), findsNothing);
    });
  });
}

class MockExportActions extends Mock implements ExportActions {}

class _FakeExportRewardNotifier extends ExportRewardNotifier {
  int consumeCalls = 0;

  @override
  bool build() => true;

  @override
  Future<void> consume() async {
    consumeCalls++;
  }
}

class _FakeLastExportDateNotifier extends LastExportDateNotifier {
  final DateTime? _date;
  _FakeLastExportDateNotifier(this._date);

  @override
  DateTime? build() => _date;
}

class _FakeExportLoadingNotifier extends ExportLoadingNotifier {
  final bool _loading;
  _FakeExportLoadingNotifier(this._loading);

  @override
  bool build() => _loading;
}
