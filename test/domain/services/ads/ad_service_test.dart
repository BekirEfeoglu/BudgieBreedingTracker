import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';

void main() {
  group('AdService - Interstitial', () {
    test(
      'showInterstitialAd calls onAdClosed immediately when no ad loaded',
      () async {
        final service = AdService();
        var called = false;

        await service.showInterstitialAd(onAdClosed: () => called = true);

        expect(called, isTrue);
      },
    );

    test(
      'showInterstitialAd calls onAdClosed immediately after dispose',
      () async {
        final service = AdService();
        service.dispose();

        var called = false;
        await service.showInterstitialAd(onAdClosed: () => called = true);

        expect(called, isTrue);
      },
    );

    test('dispose can be called multiple times without error', () {
      final service = AdService();
      expect(() {
        service.dispose();
        service.dispose();
      }, returnsNormally);
    });

    test('repeated fallback calls still invoke onAdClosed each time', () async {
      final service = AdService();
      var callCount = 0;
      void onClosed() => callCount++;

      await service.showInterstitialAd(onAdClosed: onClosed);
      await service.showInterstitialAd(onAdClosed: onClosed);
      expect(callCount, 2);
    });

    test(
      'new AdService has no ad loaded — onAdClosed called without showing',
      () async {
        final service = AdService();
        final results = <String>[];

        await service.showInterstitialAd(
          onAdClosed: () => results.add('closed'),
        );

        expect(results, contains('closed'));
        service.dispose();
      },
    );
  });

  group('AdService - Rewarded', () {
    test(
      'showRewardedAd calls onAdClosed when no rewarded ad loaded',
      () async {
        final service = AdService();
        var closedCalled = false;
        var rewardedCalled = false;

        await service.showRewardedAd(
          onRewarded: () => rewardedCalled = true,
          onAdClosed: () => closedCalled = true,
        );

        expect(closedCalled, isTrue);
        expect(rewardedCalled, isFalse);
      },
    );

    test('isRewardedAdReady returns false when no ad loaded', () {
      final service = AdService();
      expect(service.isRewardedAdReady, isFalse);
    });

    test(
      'showRewardedAd with no callback does not throw when no ad loaded',
      () async {
        final service = AdService();
        await service.showRewardedAd(onRewarded: () {});
        expect(service.isRewardedAdReady, isFalse);
      },
    );
  });

  group('AdService - Banner', () {
    test('bannerAdUnitId returns a non-empty string', () {
      expect(AdService.bannerAdUnitId, isNotEmpty);
    });
  });
}
