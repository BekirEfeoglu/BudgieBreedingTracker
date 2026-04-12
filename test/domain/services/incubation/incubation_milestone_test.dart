import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_milestone.dart';

void main() {
  group('IncubationMilestone', () {
    test('stores all milestone fields', () {
      final date = DateTime(2026, 3, 1);
      final milestone = IncubationMilestone(
        day: 7,
        title: 'Candling',
        description: 'Check embryo development',
        type: MilestoneType.candling,
        date: date,
        isPassed: false,
      );

      expect(milestone.day, 7);
      expect(milestone.title, 'Candling');
      expect(milestone.description, 'Check embryo development');
      expect(milestone.type, MilestoneType.candling);
      expect(milestone.date, date);
      expect(milestone.isPassed, isFalse);
    });

    test('MilestoneType contains expected values', () {
      expect(
        MilestoneType.values,
        containsAll([
          MilestoneType.candling,
          MilestoneType.check,
          MilestoneType.sensitive,
          MilestoneType.hatch,
          MilestoneType.late,
        ]),
      );
    });
  });
}
