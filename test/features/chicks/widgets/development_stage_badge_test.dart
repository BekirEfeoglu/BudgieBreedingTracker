import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/development_stage_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('DevelopmentStageBadge', () {
    testWidgets('renders without crashing for newborn stage', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.newborn)),
      );
      await tester.pump();

      expect(find.byType(DevelopmentStageBadge), findsOneWidget);
    });

    testWidgets('wraps a StatusBadge widget', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.newborn)),
      );
      await tester.pump();

      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('renders all stage values without crashing', (tester) async {
      for (final stage in DevelopmentStage.values) {
        await tester.pumpWidget(
          _wrap(DevelopmentStageBadge(stage: stage)),
        );
        await tester.pump();

        expect(find.byType(DevelopmentStageBadge), findsOneWidget);
      }
    });

    // Label tests
    testWidgets('newborn shows correct label', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.newborn)),
      );
      await tester.pump();

      expect(find.text('chicks.stage_newborn'), findsOneWidget);
    });

    testWidgets('nestling shows correct label', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.nestling)),
      );
      await tester.pump();

      expect(find.text('chicks.stage_nestling'), findsOneWidget);
    });

    testWidgets('fledgling shows correct label', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.fledgling)),
      );
      await tester.pump();

      expect(find.text('chicks.stage_fledgling'), findsOneWidget);
    });

    testWidgets('juvenile shows correct label', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.juvenile)),
      );
      await tester.pump();

      expect(find.text('chicks.stage_juvenile'), findsOneWidget);
    });

    testWidgets('unknown shows correct label', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.unknown)),
      );
      await tester.pump();

      expect(find.text('birds.unknown'), findsOneWidget);
    });

    // Color tests
    testWidgets('newborn uses stageNewborn color', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.newborn)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.stageNewborn);
    });

    testWidgets('nestling uses stageNestling color', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.nestling)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.stageNestling);
    });

    testWidgets('fledgling uses stageFledgling color', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.fledgling)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.stageFledgling);
    });

    testWidgets('juvenile uses stageJuvenile color', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.juvenile)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.stageJuvenile);
    });

    testWidgets('unknown uses neutral400 color', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.unknown)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.color, AppColors.neutral400);
    });

    // Icon tests
    testWidgets('each stage has a non-null icon', (tester) async {
      for (final stage in DevelopmentStage.values) {
        await tester.pumpWidget(
          _wrap(DevelopmentStageBadge(stage: stage)),
        );
        await tester.pump();

        final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
        expect(badge.icon, isNotNull);
      }
    });

    testWidgets('newborn uses egg icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.newborn)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.icon, isA<AppIcon>());
      final appIcon = badge.icon! as AppIcon;
      expect(appIcon.asset, AppIcons.egg);
    });

    testWidgets('nestling uses nest icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.nestling)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.icon, isA<AppIcon>());
      final appIcon = badge.icon! as AppIcon;
      expect(appIcon.asset, AppIcons.nest);
    });

    testWidgets('fledgling uses chick icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.fledgling)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.icon, isA<AppIcon>());
      final appIcon = badge.icon! as AppIcon;
      expect(appIcon.asset, AppIcons.chick);
    });

    testWidgets('juvenile uses bird icon', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.juvenile)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.icon, isA<AppIcon>());
      final appIcon = badge.icon! as AppIcon;
      expect(appIcon.asset, AppIcons.bird);
    });

    testWidgets('unknown uses Icon (not AppIcon)', (tester) async {
      await tester.pumpWidget(
        _wrap(const DevelopmentStageBadge(stage: DevelopmentStage.unknown)),
      );
      await tester.pump();

      final badge = tester.widget<StatusBadge>(find.byType(StatusBadge));
      expect(badge.icon, isA<Icon>());
    });
  });

  group('developmentStageColor', () {
    test('returns stageNewborn for newborn', () {
      expect(
        developmentStageColor(DevelopmentStage.newborn),
        AppColors.stageNewborn,
      );
    });

    test('returns stageNestling for nestling', () {
      expect(
        developmentStageColor(DevelopmentStage.nestling),
        AppColors.stageNestling,
      );
    });

    test('returns stageFledgling for fledgling', () {
      expect(
        developmentStageColor(DevelopmentStage.fledgling),
        AppColors.stageFledgling,
      );
    });

    test('returns stageJuvenile for juvenile', () {
      expect(
        developmentStageColor(DevelopmentStage.juvenile),
        AppColors.stageJuvenile,
      );
    });

    test('returns neutral400 for unknown', () {
      expect(
        developmentStageColor(DevelopmentStage.unknown),
        AppColors.neutral400,
      );
    });
  });

  group('developmentStageIconWidget', () {
    testWidgets('returns AppIcon for newborn', (tester) async {
      final icon = developmentStageIconWidget(DevelopmentStage.newborn);
      await tester.pumpWidget(_wrap(icon));
      await tester.pump();

      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('returns AppIcon for nestling', (tester) async {
      final icon = developmentStageIconWidget(DevelopmentStage.nestling);
      await tester.pumpWidget(_wrap(icon));
      await tester.pump();

      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('returns AppIcon for fledgling', (tester) async {
      final icon = developmentStageIconWidget(DevelopmentStage.fledgling);
      await tester.pumpWidget(_wrap(icon));
      await tester.pump();

      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('returns AppIcon for juvenile', (tester) async {
      final icon = developmentStageIconWidget(DevelopmentStage.juvenile);
      await tester.pumpWidget(_wrap(icon));
      await tester.pump();

      expect(find.byType(AppIcon), findsOneWidget);
    });

    testWidgets('returns Icon for unknown', (tester) async {
      final icon = developmentStageIconWidget(DevelopmentStage.unknown);
      await tester.pumpWidget(_wrap(icon));
      await tester.pump();

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('respects custom size parameter', (tester) async {
      final icon = developmentStageIconWidget(
        DevelopmentStage.newborn,
        size: 32,
      );
      await tester.pumpWidget(_wrap(icon));
      await tester.pump();

      final appIcon = tester.widget<AppIcon>(find.byType(AppIcon));
      expect(appIcon.size, 32);
    });

    testWidgets('respects custom color parameter', (tester) async {
      final icon = developmentStageIconWidget(
        DevelopmentStage.newborn,
        color: Colors.red,
      );
      await tester.pumpWidget(_wrap(icon));
      await tester.pump();

      final appIcon = tester.widget<AppIcon>(find.byType(AppIcon));
      expect(appIcon.color, Colors.red);
    });
  });

}
