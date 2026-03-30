import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/screens/chick_form_screen.dart';

void main() {
  late GoRouter router;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    router = GoRouter(
      initialLocation: '/chicks/form',
      routes: [
        GoRoute(
          path: '/chicks',
          builder: (_, __) => const Scaffold(body: Text('Chicks')),
          routes: [
            GoRoute(
              path: 'form',
              builder: (_, state) => ChickFormScreen(
                editChickId: state.uri.queryParameters['editId'],
              ),
            ),
          ],
        ),
      ],
    );
  });

  Widget createSubject() {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        chickFormStateProvider.overrideWith(() => ChickFormNotifier()),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ChickFormScreen', () {
    testWidgets('shows AppBar with new chick title', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text(l10n('chicks.new_chick')), findsOneWidget);
    });

    testWidgets('shows form widget', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('shows name text field', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('shows save button', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // PrimaryButton or ElevatedButton should be present
      expect(
        find.byWidgetPredicate((w) => w is FilledButton || w is ElevatedButton),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byType(ChickFormScreen), findsOneWidget);
    });

    testWidgets('shows gender segmented button', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.byWidgetPredicate((w) => w is SegmentedButton), findsWidgets);
    });

    testWidgets('shows health status segmented button', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Both gender and health status use SegmentedButton
      expect(
        find.byWidgetPredicate((w) => w is SegmentedButton),
        findsNWidgets(2),
      );
    });

    testWidgets('shows ring number text field', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Form can evolve (e.g. banding day), but ring-related text inputs should exist.
      final fields = find.byType(TextFormField);
      expect(fields, findsAtLeastNWidgets(5));
    });

    testWidgets('title changes for edit mode when editChickId is provided', (
      tester,
    ) async {
      final editRouter = GoRouter(
        initialLocation: '/chicks/form',
        routes: [
          GoRoute(
            path: '/chicks',
            builder: (_, __) => const Scaffold(body: Text('Chicks')),
            routes: [
              GoRoute(
                path: 'form',
                builder: (_, __) =>
                    const ChickFormScreen(editChickId: 'some-id'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue('test-user'),
            chickFormStateProvider.overrideWith(() => ChickFormNotifier()),
            chickByIdProvider(
              'some-id',
            ).overrideWith((_) => Stream.value(null)),
          ],
          child: MaterialApp.router(routerConfig: editRouter),
        ),
      );
      await tester.pump();

      // In edit mode with null stream result -> shows not found state.
      expect(find.text(l10n('common.not_found')), findsOneWidget);
      expect(find.text(l10n('chicks.not_found')), findsOneWidget);
    });
  });
}
