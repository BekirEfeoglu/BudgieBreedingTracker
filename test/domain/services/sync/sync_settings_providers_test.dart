import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_settings_providers.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('autoSyncProvider', () {
    test('defaults to true when preference is missing', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(autoSyncProvider), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(autoSyncProvider), isTrue);
    });

    test('loads persisted value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyAutoSync: false,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitUntil(
        () => container.read(autoSyncProvider) == false,
        maxAttempts: 120,
        interval: const Duration(milliseconds: 5),
      );

      expect(container.read(autoSyncProvider), isFalse);
    });

    test('toggle updates state and persists it', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyAutoSync: false,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for async preference load (build default is true).
      await waitUntil(
        () => container.read(autoSyncProvider) == false,
        maxAttempts: 120,
        interval: const Duration(milliseconds: 5),
      );
      expect(container.read(autoSyncProvider), isFalse);

      await container.read(autoSyncProvider.notifier).toggle();
      await waitUntil(
        () => container.read(autoSyncProvider) == true,
        maxAttempts: 120,
        interval: const Duration(milliseconds: 5),
      );
      expect(container.read(autoSyncProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppPreferences.keyAutoSync), isTrue);
    });

    test('toggle persists false when starting from default true', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(autoSyncProvider), isTrue);

      await container.read(autoSyncProvider.notifier).toggle();
      expect(container.read(autoSyncProvider), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppPreferences.keyAutoSync), isFalse);
    });
  });

  group('wifiOnlySyncProvider', () {
    test('defaults to false when preference is missing', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(wifiOnlySyncProvider), isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(wifiOnlySyncProvider), isFalse);
    });

    test('loads persisted value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyWifiOnlySync: true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await waitUntil(
        () => container.read(wifiOnlySyncProvider) == true,
        maxAttempts: 120,
        interval: const Duration(milliseconds: 5),
      );

      expect(container.read(wifiOnlySyncProvider), isTrue);
    });

    test('toggle updates state and persists it', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyWifiOnlySync: true,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Wait for async preference load (build default is false).
      await waitUntil(
        () => container.read(wifiOnlySyncProvider) == true,
        maxAttempts: 120,
        interval: const Duration(milliseconds: 5),
      );
      expect(container.read(wifiOnlySyncProvider), isTrue);

      await container.read(wifiOnlySyncProvider.notifier).toggle();
      await waitUntil(
        () => container.read(wifiOnlySyncProvider) == false,
        maxAttempts: 120,
        interval: const Duration(milliseconds: 5),
      );
      expect(container.read(wifiOnlySyncProvider), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppPreferences.keyWifiOnlySync), isFalse);
    });

    test('toggle persists true when starting from default false', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(wifiOnlySyncProvider), isFalse);

      await container.read(wifiOnlySyncProvider.notifier).toggle();
      expect(container.read(wifiOnlySyncProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(AppPreferences.keyWifiOnlySync), isTrue);
    });
  });
}
