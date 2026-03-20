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

    String monthlyPrice = 'premium.price_monthly'.tr();
    String yearlyPrice = 'premium.price_yearly'.tr();
    String lifetimePrice = 'premium.price_lifetime'.tr();

    final monthlyPackage = matchPackageForPlan(packages, PremiumPlan.monthly);
    final yearlyPackage = matchPackageForPlan(packages, PremiumPlan.yearly);
    final lifetimePackage = matchPackageForPlan(packages, PremiumPlan.lifetime);

    monthlyPrice = monthlyPackage?.storeProduct.priceString ?? monthlyPrice;
    yearlyPrice = yearlyPackage?.storeProduct.priceString ?? yearlyPrice;
    lifetimePrice = lifetimePackage?.storeProduct.priceString ?? lifetimePrice;

    // Trial info displayed subordinate to price per App Store Guidelines 3.1.2(c)
    final monthlyTrialText = 'premium.trial_after_price'.tr();

    // When offerings are unavailable, keep localized fallback prices
    // as reference instead of showing "price unavailable" for all plans.
    // Purchase buttons are already disabled via canPurchase flag.

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
            planName: 'premium.plan_monthly'.tr(),
            price: monthlyPrice,
            period: 'premium.period_monthly'.tr(),
            trialText: monthlyTrialText,
            isEnabled: purchaseIssue == null,
            isLoading:
                actionState.isLoading &&
                actionState.purchasingPlan == PremiumPlan.monthly,
            onSubscribe: !canPurchase
                ? () {}
                : () => _handleSubscribe(
                    context,
                    ref,
                    isGuest: isGuest,
                    plan: PremiumPlan.monthly,
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PricingCard(
            planName: 'premium.plan_yearly'.tr(),
            price: yearlyPrice,
            period: 'premium.period_yearly'.tr(),
            isHighlighted: true,
            badge: 'premium.best_value'.tr(),
            savingsText: 'premium.save_percent'.tr(args: ['50']),
            isEnabled: purchaseIssue == null,
            isLoading:
                actionState.isLoading &&
                actionState.purchasingPlan == PremiumPlan.yearly,
            onSubscribe: !canPurchase
                ? () {}
                : () => _handleSubscribe(
                    context,
                    ref,
                    isGuest: isGuest,
                    plan: PremiumPlan.yearly,
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PricingCard(
            planName: 'premium.plan_lifetime'.tr(),
            price: lifetimePrice,
            period: 'premium.period_lifetime'.tr(),
            savingsText: 'premium.lifetime_deal'.tr(),
            isEnabled: purchaseIssue == null,
            isLoading:
                actionState.isLoading &&
                actionState.purchasingPlan == PremiumPlan.lifetime,
            onSubscribe: !canPurchase
                ? () {}
                : () => _handleSubscribe(
                    context,
                    ref,
                    isGuest: isGuest,
                    plan: PremiumPlan.lifetime,
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
