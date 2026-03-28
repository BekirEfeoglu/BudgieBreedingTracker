import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card_header.dart';

import '../../../helpers/test_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

BreedingPair _buildPair({
  String id = 'pair-1',
  String userId = 'user-1',
  String? maleId,
  String? femaleId,
  String? cageNumber,
  BreedingStatus status = BreedingStatus.active,
}) {
  return BreedingPair(
    id: id,
    userId: userId,
    maleId: maleId,
    femaleId: femaleId,
    cageNumber: cageNumber,
    status: status,
  );
}

void main() {
  group('BreedingCardHeader', () {
    testWidgets('renders without crashing', (tester) async {
      final pair = _buildPair();

      await _pump(tester, BreedingCardHeader(pair: pair));

      expect(find.byType(BreedingCardHeader), findsOneWidget);
    });

    testWidgets('shows fallback names when birds not selected', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);

      await _pump(tester, BreedingCardHeader(pair: pair));

      expect(find.text('breeding.male_not_selected'), findsOneWidget);
      expect(find.text('breeding.female_not_selected'), findsOneWidget);
    });

    testWidgets('shows bird names from providers when available', (
      tester,
    ) async {
      final pair = _buildPair(maleId: 'male-1', femaleId: 'female-1');
      final birdsById = <String, Bird>{
        'male-1': createTestBird(
          id: 'male-1',
          name: 'Mavi',
          gender: BirdGender.male,
        ),
        'female-1': createTestBird(
          id: 'female-1',
          name: 'Sari',
          gender: BirdGender.female,
        ),
      };

      await _pump(
        tester,
        BreedingCardHeader(pair: pair),
        overrides: [
          birdByIdProvider.overrideWith(
            (ref, birdId) => Stream.value(birdsById[birdId]),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Mavi'), findsOneWidget);
      expect(find.text('Sari'), findsOneWidget);
    });

    testWidgets('shows multiply sign between bird names', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);

      await _pump(tester, BreedingCardHeader(pair: pair));

      expect(find.text('\u00D7'), findsOneWidget);
    });

    testWidgets('shows male icon', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);

      await _pump(tester, BreedingCardHeader(pair: pair));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppIcon &&
              widget.asset == AppIcons.male &&
              widget.color == AppColors.genderMale,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows female icon', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);

      await _pump(tester, BreedingCardHeader(pair: pair));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppIcon &&
              widget.asset == AppIcons.female &&
              widget.color == AppColors.genderFemale,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows cage number when provided', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null, cageNumber: 'C-5');

      await _pump(tester, BreedingCardHeader(pair: pair));

      expect(find.text('breeding.cage_label: C-5'), findsOneWidget);
    });

    testWidgets('does not show cage number when null', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null, cageNumber: null);

      await _pump(tester, BreedingCardHeader(pair: pair));

      expect(find.textContaining('breeding.cage_label'), findsNothing);
    });

    testWidgets('shows StatusBadge', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);

      await _pump(tester, BreedingCardHeader(pair: pair));

      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('active status shows correct label and color', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        status: BreedingStatus.active,
      );

      await _pump(tester, BreedingCardHeader(pair: pair));

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.label, 'breeding.active'.tr());
      expect(badge.color, AppColors.primaryLight);
    });

    testWidgets('ongoing status shows correct label and color', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        status: BreedingStatus.ongoing,
      );

      await _pump(tester, BreedingCardHeader(pair: pair));

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.label, 'breeding.in_progress'.tr());
      expect(badge.color, AppColors.warning);
    });

    testWidgets('completed status shows correct label, color, and icon', (
      tester,
    ) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        status: BreedingStatus.completed,
      );

      await _pump(tester, BreedingCardHeader(pair: pair));

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.label, 'breeding.completed'.tr());
      expect(badge.color, AppColors.success);
      final icon = badge.icon! as AppIcon;
      expect(icon.asset, AppIcons.breedingComplete);
    });

    testWidgets('cancelled status shows correct label and color', (
      tester,
    ) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        status: BreedingStatus.cancelled,
      );

      await _pump(tester, BreedingCardHeader(pair: pair));

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.label, 'breeding.cancelled'.tr());
      expect(badge.color, AppColors.neutral400);
    });

    testWidgets('unknown status shows correct label and color', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        status: BreedingStatus.unknown,
      );

      await _pump(tester, BreedingCardHeader(pair: pair));

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.label, 'common.unknown'.tr());
      expect(badge.color, AppColors.neutral400);
    });

    testWidgets('completed status badge has AppIcon', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        status: BreedingStatus.completed,
      );

      await _pump(tester, BreedingCardHeader(pair: pair));

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.icon, isA<AppIcon>());
    });

    testWidgets('non-completed status badge has no icon', (tester) async {
      final pair = _buildPair(
        maleId: null,
        femaleId: null,
        status: BreedingStatus.active,
      );

      await _pump(tester, BreedingCardHeader(pair: pair));

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.icon, isNull);
    });

    testWidgets('uses Row layout for bird names', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);

      await _pump(tester, BreedingCardHeader(pair: pair));

      expect(find.byType(Row), findsAtLeastNWidgets(1));
    });

    testWidgets('bird name texts have ellipsis overflow', (tester) async {
      final pair = _buildPair(maleId: null, femaleId: null);

      await _pump(tester, BreedingCardHeader(pair: pair));

      final nameTexts = tester.widgetList<Text>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text && widget.overflow == TextOverflow.ellipsis,
        ),
      );
      // At least the male and female name texts should have ellipsis
      expect(nameTexts.length, greaterThanOrEqualTo(2));
    });
  });
}
