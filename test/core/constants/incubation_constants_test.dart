import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/constants/incubation_constants.dart';

void main() {
  group('IncubationConstants — incubation period', () {
    test('incubationPeriodDays is 18', () {
      expect(IncubationConstants.incubationPeriodDays, 18);
    });

    test('latePeriodDays is 21', () {
      expect(IncubationConstants.latePeriodDays, 21);
    });

    test('latePeriodDays is greater than incubationPeriodDays', () {
      expect(
        IncubationConstants.latePeriodDays,
        greaterThan(IncubationConstants.incubationPeriodDays),
      );
    });

    test('incubationPeriodDays matches budgie biology (17-19 days typical)', () {
      expect(IncubationConstants.incubationPeriodDays, greaterThanOrEqualTo(17));
      expect(IncubationConstants.incubationPeriodDays, lessThanOrEqualTo(19));
    });

    test('latePeriodDays is within reasonable range (20-23)', () {
      expect(IncubationConstants.latePeriodDays, greaterThanOrEqualTo(20));
      expect(IncubationConstants.latePeriodDays, lessThanOrEqualTo(23));
    });
  });

  group('IncubationConstants — egg turning schedule', () {
    test('eggTurningHours has 3 entries', () {
      expect(IncubationConstants.eggTurningHours.length, 3);
    });

    test('eggTurningHours contains expected times', () {
      expect(IncubationConstants.eggTurningHours, ['08:00', '14:00', '20:00']);
    });

    test('all turning times are non-empty', () {
      for (final time in IncubationConstants.eggTurningHours) {
        expect(time, isNotEmpty);
      }
    });

    test('all turning times follow HH:mm format', () {
      final timePattern = RegExp(r'^\d{2}:\d{2}$');
      for (final time in IncubationConstants.eggTurningHours) {
        expect(
          timePattern.hasMatch(time),
          isTrue,
          reason: '"$time" should match HH:mm format',
        );
      }
    });

    test('turning hours are in chronological order', () {
      final hours = IncubationConstants.eggTurningHours
          .map((t) => int.parse(t.split(':')[0]))
          .toList();
      for (var i = 0; i < hours.length - 1; i++) {
        expect(
          hours[i],
          lessThan(hours[i + 1]),
          reason: 'Turning hours should be in ascending order',
        );
      }
    });

    test('turning intervals are roughly evenly spaced (every ~6 hours)', () {
      final hours = IncubationConstants.eggTurningHours
          .map((t) => int.parse(t.split(':')[0]))
          .toList();
      // 08->14 = 6h, 14->20 = 6h
      for (var i = 0; i < hours.length - 1; i++) {
        final diff = hours[i + 1] - hours[i];
        expect(diff, greaterThanOrEqualTo(5));
        expect(diff, lessThanOrEqualTo(8));
      }
    });
  });

  group('IncubationConstants — temperature', () {
    test('temperatureMin is 37.0', () {
      expect(IncubationConstants.temperatureMin, 37.0);
    });

    test('temperatureMax is 38.0', () {
      expect(IncubationConstants.temperatureMax, 38.0);
    });

    test('temperatureOptimal is 37.5', () {
      expect(IncubationConstants.temperatureOptimal, 37.5);
    });

    test('temperatureMin < temperatureOptimal < temperatureMax', () {
      expect(
        IncubationConstants.temperatureMin,
        lessThan(IncubationConstants.temperatureOptimal),
      );
      expect(
        IncubationConstants.temperatureOptimal,
        lessThan(IncubationConstants.temperatureMax),
      );
    });

    test('optimal temperature is within min-max range', () {
      expect(
        IncubationConstants.temperatureOptimal,
        greaterThanOrEqualTo(IncubationConstants.temperatureMin),
      );
      expect(
        IncubationConstants.temperatureOptimal,
        lessThanOrEqualTo(IncubationConstants.temperatureMax),
      );
    });

    test('temperature range is reasonable for avian incubation (36-39C)', () {
      expect(IncubationConstants.temperatureMin, greaterThanOrEqualTo(36.0));
      expect(IncubationConstants.temperatureMax, lessThanOrEqualTo(39.0));
    });
  });

  group('IncubationConstants — humidity', () {
    test('humidityMin is 55.0', () {
      expect(IncubationConstants.humidityMin, 55.0);
    });

    test('humidityMax is 65.0', () {
      expect(IncubationConstants.humidityMax, 65.0);
    });

    test('humidityOptimal is 60.0', () {
      expect(IncubationConstants.humidityOptimal, 60.0);
    });

    test('humidityMin < humidityOptimal < humidityMax', () {
      expect(
        IncubationConstants.humidityMin,
        lessThan(IncubationConstants.humidityOptimal),
      );
      expect(
        IncubationConstants.humidityOptimal,
        lessThan(IncubationConstants.humidityMax),
      );
    });

    test('optimal humidity is within min-max range', () {
      expect(
        IncubationConstants.humidityOptimal,
        greaterThanOrEqualTo(IncubationConstants.humidityMin),
      );
      expect(
        IncubationConstants.humidityOptimal,
        lessThanOrEqualTo(IncubationConstants.humidityMax),
      );
    });

    test('humidity values are percentages (0-100)', () {
      expect(IncubationConstants.humidityMin, greaterThanOrEqualTo(0));
      expect(IncubationConstants.humidityMax, lessThanOrEqualTo(100));
    });
  });

  group('IncubationConstants — milestones', () {
    test('candlingDay is 7', () {
      expect(IncubationConstants.candlingDay, 7);
    });

    test('secondCheckDay is 14', () {
      expect(IncubationConstants.secondCheckDay, 14);
    });

    test('sensitivePeriodDay is 16', () {
      expect(IncubationConstants.sensitivePeriodDay, 16);
    });

    test('expectedHatchDay is 18', () {
      expect(IncubationConstants.expectedHatchDay, 18);
    });

    test('lateHatchDay is 21', () {
      expect(IncubationConstants.lateHatchDay, 21);
    });

    test('milestones are in chronological order', () {
      final milestones = [
        IncubationConstants.candlingDay,
        IncubationConstants.secondCheckDay,
        IncubationConstants.sensitivePeriodDay,
        IncubationConstants.expectedHatchDay,
        IncubationConstants.lateHatchDay,
      ];
      for (var i = 0; i < milestones.length - 1; i++) {
        expect(
          milestones[i],
          lessThan(milestones[i + 1]),
          reason: 'Milestone at index $i should be before milestone at ${i + 1}',
        );
      }
    });

    test('all milestones are positive', () {
      expect(IncubationConstants.candlingDay, greaterThan(0));
      expect(IncubationConstants.secondCheckDay, greaterThan(0));
      expect(IncubationConstants.sensitivePeriodDay, greaterThan(0));
      expect(IncubationConstants.expectedHatchDay, greaterThan(0));
      expect(IncubationConstants.lateHatchDay, greaterThan(0));
    });

    test('expectedHatchDay matches incubationPeriodDays', () {
      expect(
        IncubationConstants.expectedHatchDay,
        IncubationConstants.incubationPeriodDays,
      );
    });

    test('lateHatchDay matches latePeriodDays', () {
      expect(
        IncubationConstants.lateHatchDay,
        IncubationConstants.latePeriodDays,
      );
    });

    test('all milestones are within incubation period', () {
      expect(
        IncubationConstants.candlingDay,
        lessThanOrEqualTo(IncubationConstants.lateHatchDay),
      );
      expect(
        IncubationConstants.secondCheckDay,
        lessThanOrEqualTo(IncubationConstants.lateHatchDay),
      );
    });
  });
}
