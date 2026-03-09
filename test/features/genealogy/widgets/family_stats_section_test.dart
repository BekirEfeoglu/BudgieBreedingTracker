import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/inbreeding_calculator.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_calculation_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/family_stats_section.dart';

// Yardımcı test veri üretici
AncestorStats _makeStats({
  int found = 4,
  int possible = 62,
  int deepestGeneration = 3,
  double completeness = 6.45,
}) => (
  found: found,
  possible: possible,
  deepestGeneration: deepestGeneration,
  completeness: completeness,
);

InbreedingData _makeInbreeding({
  double coefficient = 0.0,
  InbreedingRisk risk = InbreedingRisk.none,
  Set<String> commonAncestorIds = const {},
}) => (
  coefficient: coefficient,
  risk: risk,
  commonAncestorIds: commonAncestorIds,
);

Bird _makeBird({
  required String id,
  required String name,
  BirdGender gender = BirdGender.male,
  BirdStatus status = BirdStatus.alive,
}) =>
    Bird(id: id, userId: 'user-1', name: name, gender: gender, status: status);

void main() {
  group('FamilyStatsSection', () {
    testWidgets('renders without crashing with default empty data', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FamilyStatsSection(
                ancestorStats: _makeStats(),
                inbreedingData: _makeInbreeding(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(FamilyStatsSection), findsOneWidget);
    });

    testWidgets('shows no inbreeding text when risk is none', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FamilyStatsSection(
                ancestorStats: _makeStats(),
                inbreedingData: _makeInbreeding(risk: InbreedingRisk.none),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Risk none → 'genealogy.no_inbreeding' key gösterilmeli
      expect(find.text('genealogy.no_inbreeding'), findsOneWidget);
    });

    testWidgets('shows LinearProgressIndicator for completeness', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FamilyStatsSection(
                ancestorStats: _makeStats(completeness: 50.0),
                inbreedingData: _makeInbreeding(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows offspring count when birds and chicks provided', (
      tester,
    ) async {
      final birds = [
        _makeBird(id: 'b1', name: 'Erkek 1', gender: BirdGender.male),
        _makeBird(id: 'b2', name: 'Dişi 1', gender: BirdGender.female),
      ];
      final chicks = [
        const Chick(id: 'c1', userId: 'user-1', gender: BirdGender.male),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FamilyStatsSection(
                ancestorStats: _makeStats(),
                inbreedingData: _makeInbreeding(),
                offspringBirds: birds,
                offspringChicks: chicks,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Toplam offspring = 3 gösterilmeli
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows male/female ratio when there are offspring', (
      tester,
    ) async {
      final birds = [
        _makeBird(id: 'b1', name: 'Erkek 1', gender: BirdGender.male),
        _makeBird(id: 'b2', name: 'Dişi 1', gender: BirdGender.female),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FamilyStatsSection(
                ancestorStats: _makeStats(),
                inbreedingData: _makeInbreeding(),
                offspringBirds: birds,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 1 erkek / 1 dişi oranı
      expect(find.text('1 / 1'), findsOneWidget);
    });

    testWidgets('shows inbreeding warning when risk is high', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FamilyStatsSection(
                ancestorStats: _makeStats(),
                inbreedingData: _makeInbreeding(
                  coefficient: 0.25,
                  risk: InbreedingRisk.high,
                  commonAncestorIds: {'common-1'},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // InbreedingWarning widget render edilmeli
      // 'genealogy.no_inbreeding' görünmemeli
      expect(find.text('genealogy.no_inbreeding'), findsNothing);
    });

    testWidgets('renders Card widget for stats display', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FamilyStatsSection(
                ancestorStats: _makeStats(),
                inbreedingData: _makeInbreeding(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders deepest generation stat row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FamilyStatsSection(
                ancestorStats: _makeStats(deepestGeneration: 4),
                inbreedingData: _makeInbreeding(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 'genealogy.deepest_generation' label key görünmeli
      expect(find.text('genealogy.deepest_generation'), findsOneWidget);
    });
  });
}
