import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_card.dart';

/// Pumps ChickCard inside a ProviderScope with the given provider overrides.
/// Always overrides chickParentsProvider to return null unless a specific
/// override is given in [overrides].
Future<void> _pumpChickCard(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  // Include the base chickParentsProvider override only when no specific
  // override for it is provided.
  final allOverrides = overrides.isEmpty
      ? [chickParentsProvider.overrideWith((ref, eggId) => Future.value(null))]
      : overrides;

  await tester.pumpWidget(
    ProviderScope(
      overrides: allOverrides.cast(),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
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
            )),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
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
