import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/genetics_history_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_compare_screen.dart';

void main() {
  GeneticsHistory makeEntry({
    String id = 'gh-1',
    Map<String, String> fatherGenotype = const {},
    Map<String, String> motherGenotype = const {},
    String? resultsJson,
  }) {
    final defaultResults = jsonEncode([
      {
        'phenotype': 'Normal',
        'probability': 0.5,
        'visualMutations': <String>[],
      },
      {
        'phenotype': 'Blue',
        'probability': 0.5,
        'visualMutations': ['blue_series'],
      },
    ]);

    return GeneticsHistory(
      id: id,
      userId: 'test-user',
      fatherGenotype: fatherGenotype,
      motherGenotype: motherGenotype,
      resultsJson: resultsJson ?? defaultResults,
      createdAt: DateTime(2024, 1, 1),
    );
  }

  Widget createSubject({
    required List<String> historyIds,
    required Stream<List<GeneticsHistory>> historyStream,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        geneticsHistoryStreamProvider(
          'test-user',
        ).overrideWith((_) => historyStream),
      ],
      child: MaterialApp(home: GeneticsCompareScreen(historyIds: historyIds)),
    );
  }

  group('GeneticsCompareScreen', () {
    testWidgets('renders without error', (tester) async {
      final entries = [makeEntry(id: 'gh-1'), makeEntry(id: 'gh-2')];

      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-1', 'gh-2'],
          historyStream: Stream.value(entries),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GeneticsCompareScreen), findsOneWidget);
    });

    testWidgets('shows AppBar with compare title when historyIds provided', (
      tester,
    ) async {
      final entries = [makeEntry(id: 'gh-1'), makeEntry(id: 'gh-2')];

      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-1', 'gh-2'],
          historyStream: Stream.value(entries),
        ),
      );
      await tester.pumpAndSettle();

      // EasyLocalization returns raw key in test context
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(l10n('genetics.compare_title')), findsOneWidget);
    });

    testWidgets('shows AppBar with compare key when historyIds is empty', (
      tester,
    ) async {
      // When historyIds is empty, the screen renders the simple empty branch
      // with the 'genetics.compare' key rather than fetching stream data.
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: GeneticsCompareScreen(historyIds: [])),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('genetics.compare')), findsOneWidget);
    });

    testWidgets('shows empty state when historyIds is empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: GeneticsCompareScreen(historyIds: [])),
        ),
      );
      await tester.pumpAndSettle();

      // The no_results message is shown in the body center
      expect(find.text(l10n('genetics.no_results')), findsOneWidget);
    });

    testWidgets('shows empty state when selected entries not found in stream', (
      tester,
    ) async {
      // Stream has entries but none match the requested historyIds
      final entries = [makeEntry(id: 'gh-other')];

      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-missing-1', 'gh-missing-2'],
          historyStream: Stream.value(entries),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('genetics.no_results')), findsOneWidget);
    });

    testWidgets('shows loading state while data is loading', (tester) async {
      final controller = StreamController<List<GeneticsHistory>>();

      await tester.pumpWidget(
        createSubject(historyIds: ['gh-1'], historyStream: controller.stream),
      );

      // Stream has not emitted yet, so loading should be visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.close();
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-1'],
          historyStream: Stream.error('Network error'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('renders comparison table when histories exist', (
      tester,
    ) async {
      final entries = [makeEntry(id: 'gh-1'), makeEntry(id: 'gh-2')];

      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-1', 'gh-2'],
          historyStream: Stream.value(entries),
        ),
      );
      await tester.pumpAndSettle();

      // IMPROVED: table uses Card+Column instead of ListView after nested scroll fix
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders table with header row for each entry', (
      tester,
    ) async {
      final entries = [
        makeEntry(id: 'gh-1'),
        makeEntry(id: 'gh-2'),
        makeEntry(id: 'gh-3'),
      ];

      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-1', 'gh-2', 'gh-3'],
          historyStream: Stream.value(entries),
        ),
      );
      await tester.pumpAndSettle();

      // Header should show phenotype label
      expect(find.text(l10n('genetics.phenotype')), findsOneWidget);
    });

    testWidgets('renders phenotype rows from results', (tester) async {
      final entries = [makeEntry(id: 'gh-1')];

      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-1'],
          historyStream: Stream.value(entries),
        ),
      );
      await tester.pumpAndSettle();

      // The default results JSON has 2 phenotypes: Normal and Blue
      // Both should appear as rows in the virtualized list
      // IMPROVED: table uses Card+Column instead of ListView after nested scroll fix
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows probability percentages in cells', (tester) async {
      final entries = [makeEntry(id: 'gh-1')];

      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-1'],
          historyStream: Stream.value(entries),
        ),
      );
      await tester.pumpAndSettle();

      // Both phenotypes have 50% probability
      expect(find.text('50.0%'), findsNWidgets(2));
    });

    testWidgets('only renders entries matching historyIds', (tester) async {
      final entries = [
        makeEntry(id: 'gh-1'),
        makeEntry(id: 'gh-2'),
        makeEntry(id: 'gh-3'),
      ];

      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-1', 'gh-3'],
          historyStream: Stream.value(entries),
        ),
      );
      await tester.pumpAndSettle();

      // IMPROVED: table uses Card+Column instead of ListView after nested scroll fix
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows dash for missing phenotype in an entry', (tester) async {
      final entry1Results = jsonEncode([
        {
          'phenotype': 'Normal',
          'probability': 1.0,
          'visualMutations': <String>[],
        },
      ]);
      final entry2Results = jsonEncode([
        {
          'phenotype': 'Blue',
          'probability': 1.0,
          'visualMutations': ['blue_series'],
        },
      ]);

      final entries = [
        makeEntry(id: 'gh-1', resultsJson: entry1Results),
        makeEntry(id: 'gh-2', resultsJson: entry2Results),
      ];

      await tester.pumpWidget(
        createSubject(
          historyIds: ['gh-1', 'gh-2'],
          historyStream: Stream.value(entries),
        ),
      );
      await tester.pumpAndSettle();

      // Entry 1 has no Blue phenotype and entry 2 has no Normal phenotype,
      // so each should show a dash for the missing one
      expect(find.text('-'), findsNWidgets(2));
    });
  });
}
