import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Callback that initializes the ad SDK and returns the banner ad unit ID.
typedef AdBannerLoader = Future<String> Function();

/// Displays a banner ad for free-tier users.
/// Renders [SizedBox.shrink] when the user is premium or ad fails to load.
///
/// Premium status is injected via [isPremiumProvider] to avoid
/// core/ -> features/ layer violation.
/// Ad loading is driven by [adBannerLoader] to avoid core/ -> domain/ import.
class AdBannerWidget extends ConsumerStatefulWidget {
  final AdSize adSize;
  final Provider<bool> isPremiumProvider;

  /// Callback that ensures the ad SDK is initialized and returns the banner
  /// ad unit ID. Injected by the caller to keep core/ free of domain/ imports.
  final AdBannerLoader adBannerLoader;

  const AdBannerWidget({
    super.key,
    this.adSize = AdSize.banner,
    required this.isPremiumProvider,
    required this.adBannerLoader,
  });

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final adUnitId = await widget.adBannerLoader();
    if (adUnitId.isEmpty) return;

    if (!mounted) return;

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isAdLoaded = false;
            });
          }
        },
      ),
    );
    await _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(widget.isPremiumProvider);
    if (isPremium || !_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
