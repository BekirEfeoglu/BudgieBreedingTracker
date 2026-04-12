import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });
}
