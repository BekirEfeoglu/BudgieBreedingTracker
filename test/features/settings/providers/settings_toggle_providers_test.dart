import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_toggle_providers.dart';

// Build() içinde fire-and-forget _loadFromPrefs() çağrısı yapıldığından,
// provider'ın ilk değerini okumadan önce async yüklemenin tamamlanmasını
// beklemek gerekir. Helpers addTearDown ile otomatik dispose eder.

/// Empty prefs ile container oluşturur. Caller must be inside a test.
// ignore: unused_element
Future<ProviderContainer> _makeContainer() async {
  SharedPreferences.setMockInitialValues({});
  await SharedPreferences.getInstance();
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

/// Container'ı oluşturur, provider'ı tetikler ve _loadFromPrefs() bitmesini bekler.
Future<ProviderContainer> _makeContainerAndWarm(
  NotifierProvider provider, {
  Map<String, Object> values = const {},
}) async {
  SharedPreferences.setMockInitialValues(values);
  await SharedPreferences.getInstance();
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(provider);
  await Future<void>.delayed(const Duration(milliseconds: 150));
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('notificationsMasterProvider', () {
    test('initial state is true (notifications enabled)', () async {
      final container = await _makeContainerAndWarm(
        notificationsMasterProvider,
      );

      expect(container.read(notificationsMasterProvider), isTrue);
    });

    test('toggle() flips state to false', () async {
      final container = await _makeContainerAndWarm(
        notificationsMasterProvider,
      );

      await container.read(notificationsMasterProvider.notifier).toggle();

      expect(container.read(notificationsMasterProvider), isFalse);
    });

    test('toggle() twice returns to true', () async {
      final container = await _makeContainerAndWarm(
        notificationsMasterProvider,
      );

      await container.read(notificationsMasterProvider.notifier).toggle();
      await container.read(notificationsMasterProvider.notifier).toggle();

      expect(container.read(notificationsMasterProvider), isTrue);
    });

    test('toggle() persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(notificationsMasterProvider);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await container.read(notificationsMasterProvider.notifier).toggle();

      expect(prefs.getBool(AppPreferences.keyNotificationsEnabled), isFalse);
    });

    test('loads persisted false from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        notificationsMasterProvider,
        values: {AppPreferences.keyNotificationsEnabled: false},
      );

      expect(container.read(notificationsMasterProvider), isFalse);
    });
  });

  group('compactViewProvider', () {
    test('initial state is false', () async {
      final container = await _makeContainerAndWarm(compactViewProvider);

      expect(container.read(compactViewProvider), isFalse);
    });

    test('toggle() enables compact view', () async {
      final container = await _makeContainerAndWarm(compactViewProvider);

      await container.read(compactViewProvider.notifier).toggle();

      expect(container.read(compactViewProvider), isTrue);
    });

    test('toggle() twice returns to false', () async {
      final container = await _makeContainerAndWarm(compactViewProvider);

      await container.read(compactViewProvider.notifier).toggle();
      await container.read(compactViewProvider.notifier).toggle();

      expect(container.read(compactViewProvider), isFalse);
    });

    test('loads persisted true from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        compactViewProvider,
        values: {AppPreferences.keyCompactView: true},
      );

      expect(container.read(compactViewProvider), isTrue);
    });
  });

  group('hapticFeedbackProvider', () {
    test('initial state is true', () async {
      final container = await _makeContainerAndWarm(hapticFeedbackProvider);

      expect(container.read(hapticFeedbackProvider), isTrue);
    });

    test('toggle() disables haptic feedback', () async {
      final container = await _makeContainerAndWarm(hapticFeedbackProvider);

      await container.read(hapticFeedbackProvider.notifier).toggle();

      expect(container.read(hapticFeedbackProvider), isFalse);
    });

    test('persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(hapticFeedbackProvider);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await container.read(hapticFeedbackProvider.notifier).toggle();

      expect(prefs.getBool(AppPreferences.keyHapticFeedback), isFalse);
    });

    test('loads persisted false from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        hapticFeedbackProvider,
        values: {AppPreferences.keyHapticFeedback: false},
      );

      expect(container.read(hapticFeedbackProvider), isFalse);
    });
  });

  group('reduceAnimationsProvider', () {
    test('initial state is false', () async {
      final container = await _makeContainerAndWarm(reduceAnimationsProvider);

      expect(container.read(reduceAnimationsProvider), isFalse);
    });

    test('toggle() enables reduce animations', () async {
      final container = await _makeContainerAndWarm(reduceAnimationsProvider);

      await container.read(reduceAnimationsProvider.notifier).toggle();

      expect(container.read(reduceAnimationsProvider), isTrue);
    });

    test('toggle() twice returns to false', () async {
      final container = await _makeContainerAndWarm(reduceAnimationsProvider);

      await container.read(reduceAnimationsProvider.notifier).toggle();
      await container.read(reduceAnimationsProvider.notifier).toggle();

      expect(container.read(reduceAnimationsProvider), isFalse);
    });

    test('loads persisted true from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        reduceAnimationsProvider,
        values: {AppPreferences.keyReduceAnimations: true},
      );

      expect(container.read(reduceAnimationsProvider), isTrue);
    });
  });

  group('eggTurningReminderProvider', () {
    test('initial state is true', () async {
      final container = await _makeContainerAndWarm(eggTurningReminderProvider);

      expect(container.read(eggTurningReminderProvider), isTrue);
    });

    test('toggle() disables egg turning reminder', () async {
      final container = await _makeContainerAndWarm(eggTurningReminderProvider);

      await container.read(eggTurningReminderProvider.notifier).toggle();

      expect(container.read(eggTurningReminderProvider), isFalse);
    });

    test('persists disabled state to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(eggTurningReminderProvider);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await container.read(eggTurningReminderProvider.notifier).toggle();

      expect(prefs.getBool(AppPreferences.keyEggTurningReminder), isFalse);
    });

    test('loads persisted false from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        eggTurningReminderProvider,
        values: {AppPreferences.keyEggTurningReminder: false},
      );

      expect(container.read(eggTurningReminderProvider), isFalse);
    });
  });

  group('temperatureAlertProvider', () {
    test('initial state is true', () async {
      final container = await _makeContainerAndWarm(temperatureAlertProvider);

      expect(container.read(temperatureAlertProvider), isTrue);
    });

    test('toggle() disables temperature alerts', () async {
      final container = await _makeContainerAndWarm(temperatureAlertProvider);

      await container.read(temperatureAlertProvider.notifier).toggle();

      expect(container.read(temperatureAlertProvider), isFalse);
    });

    test('persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(temperatureAlertProvider);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await container.read(temperatureAlertProvider.notifier).toggle();

      expect(prefs.getBool(AppPreferences.keyTemperatureAlert), isFalse);
    });

    test('loads persisted false from SharedPreferences', () async {
      final container = await _makeContainerAndWarm(
        temperatureAlertProvider,
        values: {AppPreferences.keyTemperatureAlert: false},
      );

      expect(container.read(temperatureAlertProvider), isFalse);
    });
  });
}
