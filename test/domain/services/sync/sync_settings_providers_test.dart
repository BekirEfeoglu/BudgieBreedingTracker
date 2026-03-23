import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_settings_providers.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('autoSyncProvider', () {
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
  });

  group('wifiOnlySyncProvider', () {
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
  });
}
