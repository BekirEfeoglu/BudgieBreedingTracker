part of 'premium_paywall_sections.dart';

class PremiumPricingSection extends ConsumerWidget {
  const PremiumPricingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actionState = ref.watch(purchaseActionProvider);
    final packages = ref.watch(premiumOfferingsProvider).value ?? [];
    final isGuest = ref.watch(currentUserIdProvider) == 'anonymous';
    final purchaseIssue = ref.watch(premiumPurchaseIssueProvider);
    final canPurchase = !actionState.isLoading && purchaseIssue == null;

    String semiAnnualPrice = 'premium.price_semi_annual'.tr();
    String yearlyPrice = 'premium.price_yearly'.tr();

    final semiAnnualPackage =
        matchPackageForPlan(packages, PremiumPlan.semiAnnual);
    final yearlyPackage = matchPackageForPlan(packages, PremiumPlan.yearly);

    semiAnnualPrice =
        semiAnnualPackage?.storeProduct.priceString ?? semiAnnualPrice;
    yearlyPrice = yearlyPackage?.storeProduct.priceString ?? yearlyPrice;

    // When offerings are unavailable, keep localized fallback prices
    // as reference instead of showing "price unavailable" for all plans.
    // Purchase buttons are already disabled via canPurchase flag.

    final savingsPercent = calculateSavingsPercent(
      semiAnnualPrice: semiAnnualPackage?.storeProduct.price,
      yearlyPrice: yearlyPackage?.storeProduct.price,
    );

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          if (isGuest) ...[
            const _PremiumGuestAccessCard(),
            const SizedBox(height: AppSpacing.lg),
          ] else if (purchaseIssue != null) ...[
            _PremiumPurchaseIssueCard(
              issue: purchaseIssue,
              onRetry:
                  purchaseIssue == PremiumPurchaseIssue.offeringsUnavailable
                  ? () {
                      ref
                          .read(purchaseServiceProvider)
                          .clearStoreUnavailableCache();
                      ref.invalidate(purchaseServiceReadyProvider);
                      ref.invalidate(premiumOfferingsProvider);
                      ref.invalidate(subscriptionInfoProvider);
                    }
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          PricingCard(
            planName: 'premium.plan_semi_annual'.tr(),
            price: semiAnnualPrice,
            period: 'premium.period_semi_annual'.tr(),
            isEnabled: canPurchase,
            isLoading:
                actionState.isLoading &&
                actionState.purchasingPlan == PremiumPlan.semiAnnual,
            onSubscribe: () => _handleSubscribe(
              context,
              ref,
              isGuest: isGuest,
              plan: PremiumPlan.semiAnnual,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PricingCard(
            planName: 'premium.plan_yearly'.tr(),
            price: yearlyPrice,
            period: 'premium.period_yearly'.tr(),
            isHighlighted: true,
            badge: 'premium.best_value'.tr(),
            savingsText: 'premium.save_percent'.tr(args: [savingsPercent]),
            isEnabled: canPurchase,
            isLoading:
                actionState.isLoading &&
                actionState.purchasingPlan == PremiumPlan.yearly,
            onSubscribe: () => _handleSubscribe(
              context,
              ref,
              isGuest: isGuest,
              plan: PremiumPlan.yearly,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Auto-renewal disclosure — must be prominent and close to
          // subscribe buttons per App Store Review Guidelines.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              'premium.terms_note'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _PremiumLegalLinksSection(),
        ],
      ),
    );
  }

  void _handleSubscribe(
    BuildContext context,
    WidgetRef ref, {
    required bool isGuest,
    required PremiumPlan plan,
  }) {
    if (isGuest) {
      context.push(AppRoutes.login);
      return;
    }

    ref.read(purchaseActionProvider.notifier).purchasePlan(plan);
  }
}

class _PremiumPurchaseIssueCard extends StatelessWidget {
  final PremiumPurchaseIssue issue;
  final VoidCallback? onRetry;

  const _PremiumPurchaseIssueCard({required this.issue, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _purchaseIssueTitleKey(issue).tr();
    final body = _purchaseIssueBodyKey(issue).tr();
    final color = issue == PremiumPurchaseIssue.missingApiKey
        ? AppColors.error
        : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text('common.retry'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}

String _purchaseIssueTitleKey(PremiumPurchaseIssue issue) {
  return switch (issue) {
    PremiumPurchaseIssue.missingApiKey =>
      'premium.purchase_setup_missing_title',
    PremiumPurchaseIssue.iosDebugStoreKitRequired =>
      'premium.ios_debug_purchase_title',
    PremiumPurchaseIssue.offeringsUnavailable =>
      'premium.offerings_unavailable_title',
  };
}

String _purchaseIssueBodyKey(PremiumPurchaseIssue issue) {
  return switch (issue) {
    PremiumPurchaseIssue.missingApiKey => 'premium.purchase_setup_missing_body',
    PremiumPurchaseIssue.iosDebugStoreKitRequired =>
      'premium.ios_debug_purchase_body',
    PremiumPurchaseIssue.offeringsUnavailable =>
      'premium.offerings_unavailable_body',
  };
}

/// Calculates the savings percentage of yearly vs semi-annual plan.
///
/// Returns a string like '20' (percent). Falls back to '17' when prices
/// are unavailable (based on $15×2=$30 vs $25 default pricing).
@visibleForTesting
String calculateSavingsPercent({
  double? semiAnnualPrice,
  double? yearlyPrice,
}) {
  if (semiAnnualPrice == null ||
      yearlyPrice == null ||
      semiAnnualPrice <= 0 ||
      yearlyPrice <= 0) {
    return '17';
  }
  final annualized = semiAnnualPrice * 2;
  final savings = ((annualized - yearlyPrice) / annualized * 100).round();
  if (savings > 0 && savings < 100) {
    return savings.toString();
  }
  return '17';
}

Future<void> _openLegalUrl(
  BuildContext context, {
  required String url,
  required String fallbackRoute,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    context.push(fallbackRoute);
    return;
  }

  var launched = false;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }

  if (!launched && context.mounted) {
    context.push(fallbackRoute);
  }
}
