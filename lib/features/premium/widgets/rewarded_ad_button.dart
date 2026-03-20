import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';

/// A button that shows a rewarded ad. Calls [onRewarded] when the user
/// finishes watching the ad. Shows loading state while ad is being displayed.
class RewardedAdButton extends ConsumerStatefulWidget {
  final String label;
  final String? subtitle;
  final VoidCallback onRewarded;
  final VoidCallback? onCancelled;

  const RewardedAdButton({
    super.key,
    required this.label,
    this.subtitle,
    required this.onRewarded,
    this.onCancelled,
  });

  @override
  ConsumerState<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends ConsumerState<RewardedAdButton> {
  bool _isLoading = false;

  Future<void> _showAd() async {
    final adService = ref.read(adServiceProvider);
    if (!adService.isRewardedAdReady) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ads.ad_not_available'.tr())));
      }
      return;
    }

    setState(() => _isLoading = true);
    await adService.showRewardedAd(
      onRewarded: widget.onRewarded,
      onAdClosed: () {
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton.icon(
          onPressed: _isLoading ? null : _showAd,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.play, size: 18),
          label: Text(
            _isLoading ? 'ads.ad_loading'.tr() : widget.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, AppSpacing.touchTargetMin),
          ),
        ),
        if (widget.subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.subtitle!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
