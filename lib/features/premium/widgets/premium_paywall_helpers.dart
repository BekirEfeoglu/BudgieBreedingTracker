part of 'premium_paywall_sections.dart';

/// Tablet breakpoint for side-by-side pricing cards layout.
const double _kPricingWideBreakpoint = 600;

/// Responsive layout for pricing cards.
/// On narrow screens (phones): stacked vertically.
/// On wide screens (tablets): 3 cards side by side.
class _PricingCardsLayout extends StatelessWidget {
  final Widget monthlyCard;
  final Widget yearlyCard;
  final Widget lifetimeCard;

  const _PricingCardsLayout({
    required this.monthlyCard,
    required this.yearlyCard,
    required this.lifetimeCard,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= _kPricingWideBreakpoint;

    return Semantics(
      label: 'premium.features_title'.tr(),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: monthlyCard),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: yearlyCard),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: lifetimeCard),
              ],
            )
          : Column(
              children: [
                monthlyCard,
                const SizedBox(height: AppSpacing.lg),
                yearlyCard,
                const SizedBox(height: AppSpacing.lg),
                lifetimeCard,
              ],
            ),
    );
  }
}

class _PremiumPurchaseIssueCard extends StatelessWidget {
  final PremiumPurchaseIssue issue;
  final VoidCallback? onRetry;

  const _PremiumPurchaseIssueCard({required this.issue, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _localizedPurchaseIssue(context, issue);
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
            message.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message.body,
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

({String title, String body}) _localizedPurchaseIssue(
  BuildContext context,
  PremiumPurchaseIssue issue,
) {
  return switch (issue) {
    PremiumPurchaseIssue.missingApiKey => (
      title: 'premium.purchase_setup_missing_title'.tr(),
      body: 'premium.purchase_setup_missing_body'.tr(),
    ),
    PremiumPurchaseIssue.iosDebugStoreKitRequired => (
      title: 'premium.ios_debug_purchase_title'.tr(),
      body: 'premium.ios_debug_purchase_body'.tr(),
    ),
    PremiumPurchaseIssue.offeringsUnavailable => (
      title: 'premium.offerings_unavailable_title'.tr(),
      body: 'premium.offerings_unavailable_body'.tr(),
    ),
  };
}

String _localizedUnavailablePrice(BuildContext context) {
  return 'premium.price_unavailable'.tr();
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

class _PremiumGuestAccessCard extends StatelessWidget {
  const _PremiumGuestAccessCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.info,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'premium.sign_in_for_multi_device'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumLegalLinksSection extends StatelessWidget {
  const _PremiumLegalLinksSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton(
              onPressed: () async => _openLegalUrl(
                context,
                url: AppConstants.termsOfUseUrl,
                fallbackRoute: AppRoutes.termsOfService,
              ),
              child: Text(
                '${'settings.terms'.tr()} (EULA)',
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () async => _openLegalUrl(
                context,
                url: AppConstants.privacyPolicyUrl,
                fallbackRoute: AppRoutes.privacyPolicy,
              ),
              child: Text(
                'settings.privacy_policy'.tr(),
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
