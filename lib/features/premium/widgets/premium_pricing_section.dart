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

    if (purchaseIssue != null && packages.isEmpty) {
      final unavailablePrice = _localizedUnavailablePrice(context);
      monthlyPrice = unavailablePrice;
      yearlyPrice = unavailablePrice;
      lifetimePrice = unavailablePrice;
    }

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
          _PricingCardsLayout(
            monthlyCard: PricingCard(
              planName: 'premium.plan_monthly'.tr(),
              price: monthlyPrice,
              period: 'premium.period_monthly'.tr(),
              isEnabled: purchaseIssue == null,
              isLoading:
                  actionState.isLoading &&
                  actionState.purchasingPlan == PremiumPlan.monthly,
              onSubscribe: !canPurchase
                  ? () {}
                  : () => _handleSubscribe(
                      context,
                      ref,
                      plan: PremiumPlan.monthly,
                    ),
            ),
            yearlyCard: PricingCard(
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
                      plan: PremiumPlan.yearly,
                    ),
            ),
            lifetimeCard: PricingCard(
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
                      plan: PremiumPlan.lifetime,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Auto-renewal disclosure — must be prominent and close to
          // subscribe buttons per App Store Review Guidelines.
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
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
    required PremiumPlan plan,
  }) {
    // Apple Guideline 5.1.1(v): users can purchase without signing in.
    // RevenueCat handles anonymous users with $RCAnonymousID.
    ref.read(purchaseActionProvider.notifier).purchasePlan(plan);
  }
}

class PremiumRestoreSection extends ConsumerWidget {
  const PremiumRestoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actionState = ref.watch(purchaseActionProvider);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'premium.restore_info'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: actionState.isLoading
                ? null
                : () {
                    ref
                        .read(purchaseActionProvider.notifier)
                        .restorePurchases();
                  },
            icon:
                actionState.isLoading && actionState.purchasingPlan == null
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.rotateCcw, size: 16),
            label: Text('premium.restore_purchases'.tr()),
          ),
        ],
      ),
    );
  }
}
