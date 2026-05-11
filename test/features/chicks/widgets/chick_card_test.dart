import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_card.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_localization.dart';

/// Pumps ChickCard inside a ProviderScope with the given provider overrides.
/// Always overrides chickParentsProvider to return null unless a specific
/// override is given in [overrides].
Future<void> _pumpChickCard(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
  double? width,
}) async {
  // Include the base chickParentsProvider override only when no specific
  // override for it is provided.
  final allOverrides = overrides.isEmpty
      ? [chickParentsProvider.overrideWith((ref, eggId) => Future.value(null))]
      : overrides;

  await pumpTranslatedApp(
    tester,
    ProviderScope(
      overrides: allOverrides.cast(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: width == null ? child : SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
    settle: false,
  );
}

bool _textExceededMaxLines(WidgetTester tester, String text) {
  return tester
      .renderObject<RenderParagraph>(find.text(text))
      .didExceedMaxLines;
}

void main() {
  final testChick = Chick(
    id: 'chick-1',
    userId: 'user-1',
    name: 'Sarı Bebek',
    hatchDate: DateTime(2024, 1, 10),
    gender: BirdGender.unknown,
    healthStatus: ChickHealthStatus.healthy,
  );

  group('ChickCard', () {
    testWidgets('displays chick name when name is set', (tester) async {
      await _pumpChickCard(tester, ChickCard(chick: testChick));

      expect(find.text('Sarı Bebek'), findsOneWidget);
    });

    testWidgets('renders inside a Card widget', (tester) async {
      await _pumpChickCard(tester, ChickCard(chick: testChick));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('custom onTap is invoked', (tester) async {
      var tapped = false;

      await _pumpChickCard(
        tester,
        ChickCard(chick: testChick, onTap: () => tapped = true),
      );

      await tester.tap(find.byType(Card));
      expect(tapped, isTrue);
    });

    testWidgets('chick without name renders fallback', (tester) async {
      final namelessChick = Chick(
        id: 'chick-3',
        userId: 'user-1',
        hatchDate: DateTime(2024, 1, 10),
      );

      await _pumpChickCard(tester, ChickCard(chick: namelessChick));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('sick chick renders health badge', (tester) async {
      final sickChick = Chick(
        id: 'chick-4',
        userId: 'user-1',
        name: 'Hasta',
        hatchDate: DateTime(2024, 1, 10),
        healthStatus: ChickHealthStatus.sick,
      );

      await _pumpChickCard(tester, ChickCard(chick: sickChick));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('chick with eggId resolves parents from provider', (
      tester,
    ) async {
      final chickWithEgg = Chick(
        id: 'chick-5',
        userId: 'user-1',
        name: 'Yavru',
        hatchDate: DateTime(2024, 1, 10),
        eggId: 'egg-1',
      );

      // Override chickParentsProvider to return parent data directly.
      await _pumpChickCard(
        tester,
        ChickCard(chick: chickWithEgg),
        overrides: [
          chickParentsProvider.overrideWith(
            (ref, eggId) => Future.value((
              maleName: 'Mavi',
              femaleName: 'Sarı',
              maleId: 'male-1',
              femaleId: 'female-1',
              cageNumber: null,
            )),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows cage number from the breeding pair source', (
      tester,
    ) async {
      final eggRepo = MockEggRepository();
      final incubationRepo = MockIncubationRepository();
      final breedingPairRepo = MockBreedingPairRepository();
      final birdRepo = MockBirdRepository();
      final chickWithEgg = Chick(
        id: 'chick-7',
        userId: 'user-1',
        name: 'Yavru',
        hatchDate: DateTime(2024, 1, 10),
        eggId: 'egg-1',
      );

      when(() => eggRepo.getById('egg-1')).thenAnswer(
        (_) async => Egg(
          id: 'egg-1',
          userId: 'user-1',
          incubationId: 'inc-1',
          layDate: DateTime(2024, 1, 1),
        ),
      );
      when(() => incubationRepo.getById('inc-1')).thenAnswer(
        (_) async => const Incubation(
          id: 'inc-1',
          userId: 'user-1',
          species: Species.budgie,
          breedingPairId: 'pair-1',
        ),
      );
      when(() => breedingPairRepo.getById('pair-1')).thenAnswer(
        (_) async => const BreedingPair(
          id: 'pair-1',
          userId: 'user-1',
          maleId: 'male-1',
          femaleId: 'female-1',
          cageNumber: 'A-17',
        ),
      );
      when(() => birdRepo.getById('male-1')).thenAnswer(
        (_) async => const Bird(
          id: 'male-1',
          name: 'Mavi',
          gender: BirdGender.male,
          userId: 'user-1',
        ),
      );
      when(() => birdRepo.getById('female-1')).thenAnswer(
        (_) async => const Bird(
          id: 'female-1',
          name: 'Sarı',
          gender: BirdGender.female,
          userId: 'user-1',
        ),
      );

      await _pumpChickCard(
        tester,
        ChickCard(chick: chickWithEgg),
        overrides: [
          eggRepositoryProvider.overrideWithValue(eggRepo),
          incubationRepositoryProvider.overrideWithValue(incubationRepo),
          breedingPairRepositoryProvider.overrideWithValue(breedingPairRepo),
          birdRepositoryProvider.overrideWithValue(birdRepo),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('A-17'), findsOneWidget);
    });

    testWidgets('keeps parent names readable on narrow cards', (tester) async {
      final chickWithParents = Chick(
        id: 'chick-8',
        userId: 'user-1',
        name: 'Yavru',
        hatchDate: DateTime(2024, 1, 10),
        eggId: 'egg-1',
      );

      await _pumpChickCard(
        tester,
        ChickCard(
          chick: chickWithParents,
          parents: (
            maleName: 'Test Erkek 1',
            femaleName: 'Test Dişi 1',
            maleId: 'male-1',
            femaleId: 'female-1',
            cageNumber: '1',
          ),
        ),
        width: 390,
      );
      await tester.pumpAndSettle();

      expect(_textExceededMaxLines(tester, 'Test Erkek 1'), isFalse);
      expect(_textExceededMaxLines(tester, 'Test Dişi 1'), isFalse);
    });

    testWidgets('chick without eggId shows card without parent info', (
      tester,
    ) async {
      final chickNoEgg = Chick(
        id: 'chick-6',
        userId: 'user-1',
        name: 'Yalnız',
        hatchDate: DateTime(2024, 1, 10),
      );

      await _pumpChickCard(tester, ChickCard(chick: chickNoEgg));

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('Hero widget is present with correct tag', (tester) async {
      await _pumpChickCard(tester, ChickCard(chick: testChick));

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, contains('chick-1'));
    });
  });
}
