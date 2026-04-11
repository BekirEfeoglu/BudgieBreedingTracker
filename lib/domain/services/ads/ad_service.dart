import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:budgie_breeding_tracker/bootstrap.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';

bool get _shouldDeferAdsOnDebugIosSimulator =>
    !kReleaseMode &&
    Platform.isIOS &&
    isIosSimulatorRuntime;

/// Manages interstitial, banner, and rewarded ads for free-tier users.
///
/// - Shows interstitial ads with a [_cooldownDuration] between each display
///   so consecutive taps do not stack ads.
/// - Always calls [onAdClosed] regardless of whether an ad was shown,
///   so navigation is never blocked.
/// - [MobileAds.instance.initialize()] is called lazily on the first
///   [ensureSdkInitialized] call so it never runs during the auth flow on iOS.
class AdService {
  static const _tag = 'AdService';
  static const _cooldownDuration = Duration(minutes: 3);

  // ── Ad Unit IDs ──

  static String get _interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-4121152941965334/5757607876'
        : 'ca-app-pub-4121152941965334/1459270216';
  }

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-4121152941965334/3996472054'
        : 'ca-app-pub-4121152941965334/3473727877';
  }

  static String get _rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid
        ? 'ca-app-pub-4121152941965334/1880756245'
        : 'ca-app-pub-4121152941965334/4060197027';
  }

  // ── State ──

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _sdkInitialized = false;
  Future<void>? _sdkInitializationFuture;
  DateTime? _lastShownAt;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  bool get _canShow {
    if (!_isAdLoaded || _interstitialAd == null) return false;
    if (_lastShownAt == null) return true;
    return DateTime.now().difference(_lastShownAt!) >= _cooldownDuration;
  }

  // ── SDK Initialization ──

  /// Lazily initializes the Google Mobile Ads SDK.
  /// Safe to call multiple times — only initializes once.
  Future<void> ensureSdkInitialized() async {
    if (_shouldDeferAdsOnDebugIosSimulator) {
      AppLogger.info('$_tag: skipping SDK init on iOS simulator debug build');
      return;
    }
    if (_sdkInitialized) return;
    if (_sdkInitializationFuture != null) {
      await _sdkInitializationFuture;
      return;
    }

    final initFuture = _initializeSdk();
    _sdkInitializationFuture = initFuture;
    await initFuture;
  }

  Future<void> _initializeSdk() async {
    try {
      // Request ATT permission on iOS 14+ before initializing ads SDK.
      // This is required by Apple App Store guidelines for IDFA access.
      if (Platform.isIOS) await _requestIOSTrackingPermission();

      await MobileAds.instance.initialize();
      _sdkInitialized = true;
      AppLogger.info('$_tag: SDK initialized');
    } catch (e) {
      AppLogger.warning('$_tag: SDK initialization failed - $e');
    } finally {
      _sdkInitializationFuture = null;
    }
  }

  /// Requests App Tracking Transparency authorization on iOS 14+.
  ///
  /// Uses the native ATTrackingManager API via MethodChannel.
  /// If denied, AdMob automatically serves non-personalized ads.
  static Future<void> _requestIOSTrackingPermission() async {
    try {
      const channel = MethodChannel('com.budgiebreeding.tracker/att');
      await channel.invokeMethod<void>('requestTracking');
    } catch (e) {
      // ATT API not available (iOS < 14.5) or channel not set up — continue
      AppLogger.info('$_tag: ATT request skipped - $e');
    }
  }

  // ── Interstitial Ads ──

  /// Preloads the next interstitial ad.
  Future<void> loadAd() async {
    await ensureSdkInitialized();
    if (!_sdkInitialized) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          AppLogger.info('$_tag: interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
          AppLogger.warning('$_tag: interstitial failed - ${error.message}');
        },
      ),
    );
  }

  /// Shows the interstitial ad if available and cooldown has passed.
  /// Always calls [onAdClosed] so the caller is never left waiting.
  Future<void> showInterstitialAd({required VoidCallback onAdClosed}) async {
    if (!_canShow) {
      onAdClosed();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _lastShownAt = DateTime.now();
        ad.dispose();
        _isAdLoaded = false;
        _interstitialAd = null;
        loadAd();
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.warning('$_tag: interstitial show failed - ${error.message}');
        ad.dispose();
        _isAdLoaded = false;
        _interstitialAd = null;
        loadAd();
        onAdClosed();
      },
    );

    await _interstitialAd!.show();
    _interstitialAd = null;
  }

  // ── Rewarded Ads ──

  /// Preloads a rewarded ad.
  Future<void> loadRewardedAd() async {
    await ensureSdkInitialized();
    if (!_sdkInitialized) return;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          AppLogger.info('$_tag: rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          AppLogger.warning('$_tag: rewarded failed - ${error.message}');
        },
      ),
    );
  }

  /// Whether a rewarded ad is ready to show.
  bool get isRewardedAdReady => _isRewardedAdLoaded && _rewardedAd != null;

  /// Shows a rewarded ad. Calls [onRewarded] when user earns the reward,
  /// and [onAdClosed] when the ad is dismissed (whether rewarded or not).
  Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onAdClosed,
  }) async {
    if (!isRewardedAdReady) {
      onAdClosed?.call();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        loadRewardedAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.warning('$_tag: rewarded show failed - ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        loadRewardedAd();
        onAdClosed?.call();
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (_, __) => onRewarded());
    _rewardedAd = null;
  }

  // ── Cleanup ──

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}

/// Provides a singleton [AdService] that preloads ads on creation.
final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  var disposed = false;

  if (_shouldDeferAdsOnDebugIosSimulator) {
    AppLogger.info('AdService: skipping preload on iOS simulator debug build');
    ref.onDispose(service.dispose);
    return service;
  }

  Future<void> preloadAds() async {
    if (disposed) return;
    await service.loadAd();
    if (disposed) return;
    await service.loadRewardedAd();
  }

  // Delay ad SDK initialization to avoid startup jank.
  // On iOS the delay also gives ATT dialog time to display after the first
  // frame so the prompt is not shown during the auth flow.
  // ignore: discarded_futures
  Future<void>.delayed(const Duration(seconds: 2)).then((_) {
    if (disposed) return;
    // ignore: discarded_futures
    preloadAds();
  });

  ref.onDispose(() {
    disposed = true;
    service.dispose();
  });
  return service;
});

/// Reusable [AdBannerLoader] callback that initializes the ad SDK
/// and returns the banner ad unit ID. Use with [AdBannerWidget] to
/// avoid repeating the same closure in every screen.
Future<String> defaultAdBannerLoader(WidgetRef ref) async {
  if (_shouldDeferAdsOnDebugIosSimulator) return '';
  final adService = ref.read(adServiceProvider);
  await adService.ensureSdkInitialized();
  return AdService.bannerAdUnitId;
}
