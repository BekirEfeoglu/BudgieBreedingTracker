import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_parents.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';

import '../../../helpers/test_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('BirdDetailParents', () {
    testWidgets('returns SizedBox.shrink when no parents', (tester) async {
      final bird = createTestBird(fatherId: null, motherId: null);

      await _pump(tester, BirdDetailParents(bird: bird));

      expect(find.text(l10n('birds.parents')), findsNothing);
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('shows parents title when father is set', (tester) async {
      final bird = createTestBird(fatherId: 'father-1', motherId: null);
      final father = createTestBird(
        id: 'father-1',
        name: 'Baba',
        gender: BirdGender.male,
      );

      await _pump(
        tester,
        BirdDetailParents(bird: bird),
        overrides: [
          birdByIdProvider.overrideWith(
            (ref, id) =>
                id == 'father-1' ? Stream.value(father) : Stream.value(null),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.parents')), findsOneWidget);
    });

    testWidgets('shows father name when father is loaded', (tester) async {
      final bird = createTestBird(fatherId: 'father-1', motherId: null);
      final father = createTestBird(
        id: 'father-1',
        name: 'Baba Kus',
        gender: BirdGender.male,
      );

      await _pump(
        tester,
        BirdDetailParents(bird: bird),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => Stream.value(father)),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Baba Kus'), findsOneWidget);
    });

    testWidgets('shows both parents when both are set', (tester) async {
      final bird = createTestBird(fatherId: 'father-1', motherId: 'mother-1');
      final father = createTestBird(
        id: 'father-1',
        name: 'Baba',
        gender: BirdGender.male,
      );
      final mother = createTestBird(
        id: 'mother-1',
        name: 'Anne',
        gender: BirdGender.female,
      );

      final birdsById = {'father-1': father, 'mother-1': mother};

      await _pump(
        tester,
        BirdDetailParents(bird: bird),
        overrides: [
          birdByIdProvider.overrideWith(
            (ref, id) => Stream.value(birdsById[id]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Baba'), findsOneWidget);
      expect(find.text('Anne'), findsOneWidget);
    });

    testWidgets('shows loading text while parent data loads', (tester) async {
      final bird = createTestBird(fatherId: 'father-1');

      await _pump(
        tester,
        BirdDetailParents(bird: bird),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => const Stream.empty()),
        ],
      );

      // Before data loads, loading text should appear
      expect(find.text(l10n('common.loading')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows unknown when parent is null', (tester) async {
      final bird = createTestBird(fatherId: 'father-1');

      await _pump(
        tester,
        BirdDetailParents(bird: bird),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => Stream.value(null)),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.unknown')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows mother label', (tester) async {
      final bird = createTestBird(fatherId: null, motherId: 'mother-1');
      final mother = createTestBird(
        id: 'mother-1',
        name: 'Anne',
        gender: BirdGender.female,
      );

      await _pump(
        tester,
        BirdDetailParents(bird: bird),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => Stream.value(mother)),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.mother')), findsAtLeastNWidgets(1));
    });

    testWidgets('shows father label', (tester) async {
      final bird = createTestBird(fatherId: 'father-1', motherId: null);
      final father = createTestBird(
        id: 'father-1',
        name: 'Baba',
        gender: BirdGender.male,
      );

      await _pump(
        tester,
        BirdDetailParents(bird: bird),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => Stream.value(father)),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.father')), findsAtLeastNWidgets(1));
    });
  });
}
