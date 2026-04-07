import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_header.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_health_badge.dart';
import 'package:budgie_breeding_tracker/features/eggs/widgets/egg_list_item.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/punnett_square.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Pumps a widget wrapped in minimal app shell for testing.
Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const <dynamic>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

Egg _buildEgg({
  String id = 'egg-1',
  EggStatus status = EggStatus.laid,
  int? eggNumber = 1,
}) {
  return Egg(
    id: id,
    userId: 'user-1',
    layDate: DateTime(2026, 2, 1),
    status: status,
    eggNumber: eggNumber,
  );
}

BreedingPair _buildPair({BreedingStatus status = BreedingStatus.active}) {
  return BreedingPair(
    id: 'pair-1',
    userId: 'user-1',
    maleId: null,
    femaleId: null,
    status: status,
  );
}

void main() {
  group('ChickHealthBadge — AppIcons integration', () {
    testWidgets('healthy status renders AppIcons.health', (tester) async {
      await _pump(
        tester,
        const ChickHealthBadge(status: ChickHealthStatus.healthy),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.asset == AppIcons.health,
        ),
        findsOneWidget,
      );
    });

    testWidgets('sick status renders AppIcons.care (not health)', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChickHealthBadge(status: ChickHealthStatus.sick),
      );

      expect(
        find.byWidgetPredicate((w) => w is AppIcon && w.asset == AppIcons.care),
        findsOneWidget,
      );
      // Ensure it's NOT the health icon
      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.asset == AppIcons.health,
        ),
        findsNothing,
      );
    });

    testWidgets('deceased status renders LucideIcons.heartCrack', (
      tester,
    ) async {
      await _pump(
        tester,
        const ChickHealthBadge(status: ChickHealthStatus.deceased),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == LucideIcons.heartCrack,
        ),
        findsOneWidget,
      );
    });

    testWidgets('badge color matches status', (tester) async {
      await _pump(
        tester,
        const ChickHealthBadge(status: ChickHealthStatus.sick),
      );

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.warning);
    });
  });

  group('EggListItem — status-based AppIcons', () {
    testWidgets('default status (laid) renders AppIcons.egg', (tester) async {
      await _pump(tester, EggListItem(egg: _buildEgg(status: EggStatus.laid)));

      expect(
        find.byWidgetPredicate((w) => w is AppIcon && w.asset == AppIcons.egg),
        findsOneWidget,
      );
    });

    testWidgets('infertile status renders AppIcons.infertile', (tester) async {
      await _pump(
        tester,
        EggListItem(egg: _buildEgg(status: EggStatus.infertile)),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.asset == AppIcons.infertile,
        ),
        findsOneWidget,
      );
    });

    testWidgets('damaged status renders AppIcons.damaged', (tester) async {
      await _pump(
        tester,
        EggListItem(egg: _buildEgg(status: EggStatus.damaged)),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.asset == AppIcons.damaged,
        ),
        findsOneWidget,
      );
    });

    testWidgets('hatched status falls back to AppIcons.egg', (tester) async {
      await _pump(
        tester,
        EggListItem(egg: _buildEgg(status: EggStatus.hatched)),
      );

      expect(
        find.byWidgetPredicate((w) => w is AppIcon && w.asset == AppIcons.egg),
        findsOneWidget,
      );
    });

    testWidgets('delete button uses AppIcons.delete', (tester) async {
      await _pump(tester, EggListItem(egg: _buildEgg(), onDelete: () {}));

      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.asset == AppIcons.delete,
        ),
        findsOneWidget,
      );
    });
  });

  group('BreedingCardHeader — completed status AppIcon', () {
    testWidgets(
      'completed pair shows AppIcons.breedingComplete on StatusBadge',
      (tester) async {
        await _pump(
          tester,
          BreedingCardHeader(
            pair: _buildPair(status: BreedingStatus.completed),
          ),
        );

        final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
        final icon = badge.icon! as AppIcon;
        expect(icon.asset, AppIcons.breedingComplete);

        expect(
          find.byWidgetPredicate(
            (w) => w is AppIcon && w.asset == AppIcons.breedingComplete,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('active pair has no icon on StatusBadge', (tester) async {
      await _pump(
        tester,
        BreedingCardHeader(pair: _buildPair(status: BreedingStatus.active)),
      );

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.icon, isNull);
    });

    testWidgets('header shows male and female AppIcons', (tester) async {
      await _pump(tester, BreedingCardHeader(pair: _buildPair()));

      expect(
        find.byWidgetPredicate((w) => w is AppIcon && w.asset == AppIcons.male),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.asset == AppIcons.female,
        ),
        findsOneWidget,
      );
    });
  });

  group('PunnettSquareWidget — AppIcons.punnett integration', () {
    testWidgets('renders AppIcons.punnett in title row', (tester) async {
      const data = PunnettSquareData(
        mutationName: 'Blue Series',
        fatherAlleles: ['+', 'bl'],
        motherAlleles: ['+', 'bl'],
        cells: [
          ['+/+', '+/bl'],
          ['bl/+', 'bl/bl'],
        ],
        isSexLinked: false,
      );

      await _pump(tester, const PunnettSquareWidget(data: data));

      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.asset == AppIcons.punnett,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows sex-linked badge when isSexLinked is true', (
      tester,
    ) async {
      const data = PunnettSquareData(
        mutationName: 'Ino',
        fatherAlleles: ['ino', '+'],
        motherAlleles: ['ino', 'W'],
        cells: [
          ['ino/ino', 'ino/W'],
          ['+/ino', '+/W'],
        ],
        isSexLinked: true,
      );

      await _pump(tester, const PunnettSquareWidget(data: data));

      expect(find.text(l10n('genetics.sex_linked')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is AppIcon && w.asset == AppIcons.punnett,
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays correct allele count in table', (tester) async {
      const data = PunnettSquareData(
        mutationName: 'Test',
        fatherAlleles: ['A', 'a'],
        motherAlleles: ['A', 'a'],
        cells: [
          ['A/A', 'A/a'],
          ['a/A', 'a/a'],
        ],
        isSexLinked: false,
      );

      await _pump(tester, const PunnettSquareWidget(data: data));

      // Header row: corner cell + 2 mother alleles = 3 header cells
      // Data rows: 2 father alleles × (1 header + 2 data) = 6 cells
      // Total cells: 3 + 6 = 9
      // Verify the 4 data cells exist
      expect(find.text('A/A'), findsOneWidget);
      expect(find.text('A/a'), findsOneWidget);
      expect(find.text('a/A'), findsOneWidget);
      expect(find.text('a/a'), findsOneWidget);
    });
  });
}
