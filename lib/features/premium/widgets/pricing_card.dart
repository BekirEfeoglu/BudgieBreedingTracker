import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Card widget showing a premium plan with name, price, period,
/// and a subscribe button. Supports a highlighted variant for
/// the recommended plan, loading state during purchase, and
/// optional savings badge.
class PricingCard extends StatelessWidget {
  final String planName;
  final String price;
  final String period;
  final bool isHighlighted;
  final String? badge;
  final String? savingsText;
  final String? trialText;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onSubscribe;

  const PricingCard({
    super.key,
    required this.planName,
    required this.price,
    required this.period,
    this.isHighlighted = false,
    this.badge,
    this.savingsText,
    this.trialText,
    this.isLoading = false,
    this.isEnabled = true,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isHighlighted ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: isHighlighted ? AppColors.accent : colorScheme.outline,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              children: [
                if (badge != null) ...[const SizedBox(height: AppSpacing.sm)],
                Text(
                  planName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Billed amount — most prominent element per App Store Guidelines 3.1.2(c)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: price,
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: period,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trialText != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    trialText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (savingsText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusFull,
                      ),
                    ),
                    child: Text(
                      savingsText!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: AppSpacing.touchTargetMin,
                  child: isHighlighted
                      ? FilledButton(
                          onPressed: isLoading || !isEnabled
                              ? null
                              : onSubscribe,
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Text('premium.subscribe'.tr()),
                        )
                      : OutlinedButton(
                          onPressed: isLoading || !isEnabled
                              ? null
                              : onSubscribe,
                          child: isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.primary,
                                  ),
                                )
                              : Text('premium.subscribe'.tr()),
                        ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentLight],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.premiumBadgeText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
