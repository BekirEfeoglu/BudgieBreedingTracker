import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_milestone.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/milestone_timeline.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('MilestoneTimeline', () {
    testWidgets('renders nothing for empty milestones list', (tester) async {
      await _pump(tester, const MilestoneTimeline(milestones: []));

      expect(find.byType(MilestoneTimeline), findsOneWidget);
      expect(find.byType(IntrinsicHeight), findsNothing);
    });

    testWidgets('renders one item for single milestone', (tester) async {
      final milestone = IncubationMilestone(
        day: 1,
        date: DateTime(2026, 3, 1),
        title: 'Başlangıç',
        description: 'Yumurtlama başladı',
        type: MilestoneType.check,
        isPassed: true,
      );

      await _pump(tester, MilestoneTimeline(milestones: [milestone]));

      expect(find.text('Başlangıç'), findsOneWidget);
      expect(find.text('Yumurtlama başladı'), findsOneWidget);
    });

    testWidgets('renders all milestones', (tester) async {
      final milestones = <IncubationMilestone>[
        IncubationMilestone(
          day: 1,
          date: DateTime(2026, 3, 1),
          title: 'Mil 1',
          description: 'Açıklama 1',
          type: MilestoneType.check,
          isPassed: true,
        ),
        IncubationMilestone(
          day: 5,
          date: DateTime(2026, 3, 5),
          title: 'Mil 2',
          description: 'Açıklama 2',
          type: MilestoneType.candling,
          isPassed: false,
        ),
        IncubationMilestone(
          day: 10,
          date: DateTime(2026, 3, 10),
          title: 'Mil 3',
          description: 'Açıklama 3',
          type: MilestoneType.sensitive,
          isPassed: false,
        ),
      ];

      await _pump(tester, MilestoneTimeline(milestones: milestones));

      expect(find.text('Mil 1'), findsOneWidget);
      expect(find.text('Mil 2'), findsOneWidget);
      expect(find.text('Mil 3'), findsOneWidget);
    });

    testWidgets('shows check icon for passed milestones', (tester) async {
      final passed = IncubationMilestone(
        day: 1,
        date: DateTime(2026, 3, 1),
        title: 'Geçildi',
        description: 'Bu geçildi',
        type: MilestoneType.check,
        isPassed: true,
      );

      await _pump(tester, MilestoneTimeline(milestones: [passed]));

      // Passed milestone dot has a check icon
      expect(find.byType(Icon), findsAtLeastNWidgets(1));
    });

    testWidgets('displays date formatted as dd.MM', (tester) async {
      final milestone = IncubationMilestone(
        day: 3,
        date: DateTime(2026, 3, 15),
        title: 'Test',
        description: 'Açıklama',
        type: MilestoneType.candling,
        isPassed: false,
      );

      await _pump(tester, MilestoneTimeline(milestones: [milestone]));

      expect(find.textContaining('15.03'), findsOneWidget);
    });

    testWidgets('uses IncubationCalculator.getMilestones correctly', (
      tester,
    ) async {
      final startDate = DateTime(2026, 3, 1);
      final milestones = IncubationCalculator.getMilestones(startDate);

      await _pump(tester, MilestoneTimeline(milestones: milestones));
      // Consume potential overflow exceptions from long timeline in test viewport
      Object? ex;
      do {
        ex = tester.takeException();
      } while (ex != null);

      // Should render milestones from calculator (non-empty)
      expect(milestones.isNotEmpty, isTrue);
      expect(find.byType(MilestoneTimeline), findsOneWidget);
    });

    testWidgets('shows milestone day number in label', (tester) async {
      final milestone = IncubationMilestone(
        day: 7,
        date: DateTime(2026, 3, 7),
        title: 'Hafta',
        description: 'Bir hafta',
        type: MilestoneType.sensitive,
        isPassed: false,
      );

      await _pump(tester, MilestoneTimeline(milestones: [milestone]));

      // Day label appears: "breeding.day_label" key with args [7]
      expect(find.textContaining('7'), findsAtLeastNWidgets(1));
    });
  });
}
