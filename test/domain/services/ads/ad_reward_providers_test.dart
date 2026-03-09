import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_reward_providers.dart';

Future<void> _flushAsync() async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

void main() {
  group('Ad reward providers', () {
    test('statistics reward is active inside 24h window', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyRewardStatisticsUnlockedAt:
            DateTime.now().subtract(const Duration(hours: 23)).toIso8601String(),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isStatisticsRewardActiveProvider), isFalse);
      await _flushAsync();
      expect(container.read(isStatisticsRewardActiveProvider), isTrue);
    });

    test('statistics reward expires after 24h', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyRewardStatisticsUnlockedAt:
            DateTime.now().subtract(const Duration(hours: 25)).toIso8601String(),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await _flushAsync();
      expect(container.read(isStatisticsRewardActiveProvider), isFalse);
    });

    test('genetics reward unlock and consume updates remaining uses', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyRewardGeneticsUses: 0,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _flushAsync();

      expect(container.read(isGeneticsRewardActiveProvider), isFalse);

      await container.read(isGeneticsRewardActiveProvider.notifier).unlock();
      expect(container.read(isGeneticsRewardActiveProvider), isTrue);

      await container.read(isGeneticsRewardActiveProvider.notifier).consume();
      expect(container.read(isGeneticsRewardActiveProvider), isFalse);
    });

    test('export reward unlock and consume updates remaining uses', () async {
      SharedPreferences.setMockInitialValues({
        AppPreferences.keyRewardExportUses: 0,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _flushAsync();

      expect(container.read(isExportRewardActiveProvider), isFalse);

      await container.read(isExportRewardActiveProvider.notifier).unlock();
      expect(container.read(isExportRewardActiveProvider), isTrue);

      await container.read(isExportRewardActiveProvider.notifier).consume();
      expect(container.read(isExportRewardActiveProvider), isFalse);
    });
  });
}
