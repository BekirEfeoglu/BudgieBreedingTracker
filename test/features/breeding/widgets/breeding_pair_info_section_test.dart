import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_pair_info_section.dart';

import '../../../helpers/test_helpers.dart';

BreedingPair _buildPair({
  String id = 'pair-1',
  String? maleId = 'male-1',
  String? femaleId = 'female-1',
  String? cageNumber,
}) {
  return BreedingPair(
    id: id,
    userId: 'user-1',
    maleId: maleId,
    femaleId: femaleId,
    cageNumber: cageNumber,
    status: BreedingStatus.active,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: List.from(overrides),
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('BreedingPairInfoSection', () {
    testWidgets('shows pair info title', (tester) async {
      final pair = _buildPair();

      await _pump(
        tester,
        BreedingPairInfoSection(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => const Stream.empty()),
        ],
      );

      expect(find.text('breeding.pair_info'), findsOneWidget);
    });

    testWidgets('shows loading text when birds loading', (tester) async {
      final pair = _buildPair();

      await _pump(
        tester,
        BreedingPairInfoSection(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => const Stream.empty()),
        ],
      );

      // Loading state shows "common.loading" for bird names
      expect(find.text('common.loading'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows male bird name when loaded', (tester) async {
      final pair = _buildPair(maleId: 'male-1', femaleId: null);
      final maleBird = createTestBird(
        id: 'male-1',
        name: 'Erkek Kus',
        gender: BirdGender.male,
      );

      await _pump(
        tester,
        BreedingPairInfoSection(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith(
            (ref, id) => Stream.value(id == 'male-1' ? maleBird : null),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Erkek Kus'), findsOneWidget);
    });

    testWidgets('shows female bird name when loaded', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: 'female-1');
      final femaleBird = createTestBird(
        id: 'female-1',
        name: 'Disi Kus',
        gender: BirdGender.female,
      );

      await _pump(
        tester,
        BreedingPairInfoSection(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith(
            (ref, id) => Stream.value(id == 'female-1' ? femaleBird : null),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Disi Kus'), findsOneWidget);
    });

    testWidgets('shows both bird names when both loaded', (tester) async {
      final pair = _buildPair(maleId: 'male-1', femaleId: 'female-1');
      final maleBird = createTestBird(
        id: 'male-1',
        name: 'Erkek',
        gender: BirdGender.male,
      );
      final femaleBird = createTestBird(
        id: 'female-1',
        name: 'Disi',
        gender: BirdGender.female,
      );
      final birdsById = {'male-1': maleBird, 'female-1': femaleBird};

      await _pump(
        tester,
        BreedingPairInfoSection(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith(
            (ref, id) => Stream.value(birdsById[id]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Erkek'), findsOneWidget);
      expect(find.text('Disi'), findsOneWidget);
    });

    testWidgets('shows cage number when set', (tester) async {
      final pair = _buildPair(cageNumber: 'Kafes-3');

      await _pump(
        tester,
        BreedingPairInfoSection(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => const Stream.empty()),
        ],
      );

      expect(find.textContaining('Kafes-3'), findsOneWidget);
    });

    testWidgets('does not show cage row when cage is null', (tester) async {
      final pair = _buildPair(cageNumber: null);

      await _pump(
        tester,
        BreedingPairInfoSection(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => const Stream.empty()),
        ],
      );

      expect(find.textContaining('breeding.cage_number'), findsNothing);
    });

    testWidgets('shows two BirdPairCards', (tester) async {
      final pair = _buildPair();

      await _pump(
        tester,
        BreedingPairInfoSection(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith((ref, id) => const Stream.empty()),
        ],
      );

      expect(find.byType(BirdPairCard), findsNWidgets(2));
    });
  });

  group('BirdPairCard', () {
    testWidgets('shows bird name when bird is provided', (tester) async {
      final bird = createTestBird(name: 'Test Kus', gender: BirdGender.male);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BirdPairCard(
              bird: bird,
              gender: BirdGender.male,
              label: 'Erkek',
            ),
          ),
        ),
      );

      expect(find.text('Test Kus'), findsOneWidget);
    });

    testWidgets('shows label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BirdPairCard(
              bird: null,
              gender: BirdGender.female,
              label: 'Disi',
            ),
          ),
        ),
      );

      expect(find.text('Disi'), findsOneWidget);
    });

    testWidgets('shows loading key when bird is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BirdPairCard(
              bird: null,
              gender: BirdGender.male,
              label: 'Erkek',
            ),
          ),
        ),
      );

      expect(find.text('common.loading'), findsOneWidget);
    });
  });
}
