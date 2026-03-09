import 'package:budgie_breeding_tracker/domain/services/incubation/environment_monitor.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/environment_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('environmentMonitorProvider', () {
    test('returns cached EnvironmentMonitor instance within container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final first = container.read(environmentMonitorProvider);
      final second = container.read(environmentMonitorProvider);

      expect(first, isA<EnvironmentMonitor>());
      expect(identical(first, second), isTrue);
    });
  });

  group('latestReadingProvider', () {
    test('defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(latestReadingProvider), isNull);
    });

    test('stores and exposes updated reading', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final reading = EnvironmentReading(
        temperature: 37.5,
        humidity: 60,
        temperatureAlert: IncubationAlertSeverity.normal,
        humidityAlert: IncubationAlertSeverity.normal,
        timestamp: DateTime(2026, 1, 1),
      );

      container.read(latestReadingProvider.notifier).state = reading;

      expect(container.read(latestReadingProvider), same(reading));
    });
  });
}
