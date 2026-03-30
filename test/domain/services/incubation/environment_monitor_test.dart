import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/domain/services/incubation/environment_monitor.dart';

void main() {
  late EnvironmentMonitor monitor;

  setUp(() {
    monitor = EnvironmentMonitor();
  });

  group('EnvironmentMonitor.evaluate', () {
    test('marks optimal values as normal alerts', () {
      final reading = monitor.evaluate(temperature: 37.5, humidity: 60.0);

      expect(reading.temperatureAlert, IncubationAlertSeverity.normal);
      expect(reading.humidityAlert, IncubationAlertSeverity.normal);
      expect(reading.hasAlert, isFalse);
      expect(reading.hasCriticalAlert, isFalse);
    });

    test('marks slightly out-of-range values as warning', () {
      final reading = monitor.evaluate(temperature: 36.8, humidity: 54.0);

      expect(reading.temperatureAlert, IncubationAlertSeverity.warning);
      expect(reading.humidityAlert, IncubationAlertSeverity.warning);
      expect(reading.hasAlert, isTrue);
      expect(reading.hasCriticalAlert, isFalse);
    });

    test('marks extreme out-of-range values as critical', () {
      final reading = monitor.evaluate(temperature: 36.0, humidity: 49.0);

      expect(reading.temperatureAlert, IncubationAlertSeverity.critical);
      expect(reading.humidityAlert, IncubationAlertSeverity.critical);
      expect(reading.hasAlert, isTrue);
      expect(reading.hasCriticalAlert, isTrue);
    });
  });

  group('EnvironmentMonitor.getRecommendation', () {
    test('returns ideal key when conditions are optimal', () {
      final reading = monitor.evaluate(temperature: 37.5, humidity: 60.0);
      expect(
        monitor.getRecommendation(reading),
        'environment.conditions_ideal',
      );
    });

    test('includes low temperature recommendation key', () {
      final reading = monitor.evaluate(temperature: 36.5, humidity: 60.0);
      final recommendation = monitor.getRecommendation(reading);
      expect(recommendation, contains(l10n('environment.temp_too_low')));
    });

    test('includes high humidity recommendation key', () {
      final reading = monitor.evaluate(temperature: 37.5, humidity: 70.0);
      final recommendation = monitor.getRecommendation(reading);
      expect(recommendation, contains(l10n('environment.humidity_too_high')));
    });
  });
}
