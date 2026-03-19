import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_detail_header.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_health_badge.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/development_stage_badge.dart';

import '../../../helpers/pump_helpers.dart';

Chick _createTestChick({
  String id = 'chick-1',
  String userId = 'user-1',
  String? name,
  String? ringNumber,
  String? photoUrl,
  BirdGender gender = BirdGender.unknown,
  ChickHealthStatus healthStatus = ChickHealthStatus.healthy,
  DateTime? hatchDate,
}) {
  return Chick(
    id: id,
    userId: userId,
    name: name,
    ringNumber: ringNumber,
    photoUrl: photoUrl,
    gender: gender,
    healthStatus: healthStatus,
    hatchDate: hatchDate,
  );
}

void main() {
  group('ChickDetailHeader', () {
    testWidgets('renders without error', (tester) async {
      final chick = _createTestChick(name: 'Sarı');

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      expect(find.byType(ChickDetailHeader), findsOneWidget);
    });

    testWidgets('shows chick name when set', (tester) async {
      final chick = _createTestChick(name: 'Mavi Bebek');

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      expect(find.text('Mavi Bebek'), findsOneWidget);
    });

    testWidgets('shows fallback text when name is null', (tester) async {
      final chick = _createTestChick(id: 'chick-abc123', name: null);

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      // chickDisplayName falls back to localization key with id substring
      // In test env without easy_localization, the raw key is rendered
      expect(find.textContaining('chicks.unnamed_chick'), findsOneWidget);
    });

    testWidgets('shows health badge', (tester) async {
      final chick = _createTestChick(
        name: 'Test',
        healthStatus: ChickHealthStatus.healthy,
      );

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      expect(find.byType(ChickHealthBadge), findsOneWidget);
      final badge = tester.widget<ChickHealthBadge>(
        find.byType(ChickHealthBadge),
      );
      expect(badge.status, ChickHealthStatus.healthy);
    });

    testWidgets('shows sick health badge for sick chick', (tester) async {
      final chick = _createTestChick(
        name: 'Hasta',
        healthStatus: ChickHealthStatus.sick,
      );

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      final badge = tester.widget<ChickHealthBadge>(
        find.byType(ChickHealthBadge),
      );
      expect(badge.status, ChickHealthStatus.sick);
    });

    testWidgets('shows development stage badge', (tester) async {
      // Chick with no hatchDate -> newborn stage
      final chick = _createTestChick(name: 'Test', hatchDate: null);

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      expect(find.byType(DevelopmentStageBadge), findsOneWidget);
    });

    testWidgets('shows newborn stage badge for recently hatched chick', (
      tester,
    ) async {
      // Hatched 3 days ago -> newborn stage
      final chick = _createTestChick(
        name: 'Yeni',
        hatchDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      final badge = tester.widget<DevelopmentStageBadge>(
        find.byType(DevelopmentStageBadge),
      );
      expect(badge.stage, DevelopmentStage.newborn);
    });

    testWidgets('shows nestling stage badge for 2-week-old chick', (
      tester,
    ) async {
      // Hatched 14 days ago -> nestling stage (8-21 days)
      final chick = _createTestChick(
        name: 'Orta',
        hatchDate: DateTime.now().subtract(const Duration(days: 14)),
      );

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      final badge = tester.widget<DevelopmentStageBadge>(
        find.byType(DevelopmentStageBadge),
      );
      expect(badge.stage, DevelopmentStage.nestling);
    });

    testWidgets('renders avatar area with CircleAvatar', (tester) async {
      final chick = _createTestChick(name: 'Test', photoUrl: null);

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('contains Hero widget with correct tag', (tester) async {
      final chick = _createTestChick(id: 'chick-42', name: 'Hero');

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'chick_chick-42');
    });

    testWidgets('shows ring number when present', (tester) async {
      final chick = _createTestChick(
        name: 'Ringed',
        ringNumber: 'TR-2024-007',
      );

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      // In test env without easy_localization, .tr() returns the raw key
      expect(find.textContaining('chicks.ring_label'), findsOneWidget);
    });

    testWidgets('does not show ring number when null', (tester) async {
      final chick = _createTestChick(name: 'NoRing', ringNumber: null);

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      expect(find.textContaining('chicks.ring_label'), findsNothing);
    });

    testWidgets('shows age text when hatchDate is set', (tester) async {
      // Hatched 10 days ago -> 1 week 3 days
      final chick = _createTestChick(
        name: 'Aged',
        hatchDate: DateTime.now().subtract(const Duration(days: 10)),
      );

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      // Age is rendered via localization keys; in test env the raw key appears
      expect(find.textContaining('chicks.age_weeks_days'), findsOneWidget);
    });

    testWidgets('does not show age text when hatchDate is null', (
      tester,
    ) async {
      final chick = _createTestChick(name: 'NoAge', hatchDate: null);

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      expect(find.textContaining('chicks.age_weeks_days'), findsNothing);
      expect(find.textContaining('chicks.age_days_only'), findsNothing);
    });

    testWidgets('renders inside Column layout', (tester) async {
      final chick = _createTestChick(name: 'Layout');

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });

    testWidgets('badges row contains both development and health badges', (
      tester,
    ) async {
      final chick = _createTestChick(
        name: 'Both Badges',
        healthStatus: ChickHealthStatus.healthy,
      );

      await pumpWidgetSimple(
        tester,
        SingleChildScrollView(child: ChickDetailHeader(chick: chick)),
      );

      expect(find.byType(DevelopmentStageBadge), findsOneWidget);
      expect(find.byType(ChickHealthBadge), findsOneWidget);
    });
  });
}
