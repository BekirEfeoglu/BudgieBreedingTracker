import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/pricing_card.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

const premiumFeatures = [
  'premium.feature_genealogy',
  'premium.feature_genetics',
  'premium.feature_export',
  'premium.feature_cloud_backup',
  'premium.feature_unlimited_birds',
  'premium.feature_advanced_stats',
  'premium.feature_no_ads',
];

class PremiumHeaderSection extends StatelessWidget {
  const PremiumHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.premiumGradientDiagonal,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.premiumGold.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AppIcon(
              AppIcons.premium,
              size: 40,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'premium.headline'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'premium.subtitle'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class PremiumTrialBannerSection extends StatelessWidget {
  const PremiumTrialBannerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.gift,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'premium.trial_badge'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'premium.trial_subtitle'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'premium.value_proposition'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumFeatureListSection extends StatelessWidget {
  const PremiumFeatureListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'premium.features_title'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...premiumFeatures.map((key) => PremiumFeatureItem(featureKey: key)),
        ],
      ),
    );
  }
}

class PremiumFeatureItem extends StatelessWidget {
  final String featureKey;

  const PremiumFeatureItem({super.key, required this.featureKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.check,
              size: 16,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(featureKey.tr(), style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class PremiumPricingSection extends ConsumerWidget {
  const PremiumPricingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            _PremiumPurchaseIssueCard(issue: purchaseIssue),
            const SizedBox(height: AppSpacing.lg),
          ],
          PricingCard(
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
          const SizedBox(height: AppSpacing.lg),
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

  const _PremiumPurchaseIssueCard({required this.issue});

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
        ],
      ),
    );
  }
}

({String title, String body}) _localizedPurchaseIssue(
  BuildContext context,
  PremiumPurchaseIssue issue,
) {
  final languageCode =
      Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';

  return switch ((languageCode, issue)) {
    ('tr', PremiumPurchaseIssue.missingApiKey) => (
      title: 'Satın alma yapılandırması eksik',
      body:
          'Bu build için RevenueCat satın alma anahtarı tanımlı değil. Uygun mağaza anahtarını ekleyip tekrar deneyin.',
    ),
    ('tr', PremiumPurchaseIssue.iosDebugStoreKitRequired) => (
      title: 'iOS Simulator testinde kısıt var',
      body:
          'iOS Simulator üzerinde veya flutter run ile test ediyorsanız App Store ürünleri yüklenmeyebilir. Sandbox hesapla gerçek cihaz kullanın ya da Xcode içinden StoreKit yapılandırması ile çalıştırın.',
    ),
    ('tr', PremiumPurchaseIssue.offeringsUnavailable) => (
      title: 'Planlar şu anda yüklenemiyor',
      body:
          'Premium planları şu anda mağazadan alamadık. Lütfen kısa süre sonra tekrar deneyin.',
    ),
    ('de', PremiumPurchaseIssue.missingApiKey) => (
      title: 'Kaufkonfiguration fehlt',
      body:
          'Für diesen Build fehlt der RevenueCat-Kaufschlüssel. Hinterlege den passenden Store-Schlüssel und versuche es erneut.',
    ),
    ('de', PremiumPurchaseIssue.iosDebugStoreKitRequired) => (
      title: 'iOS-Simulator ist eingeschränkt',
      body:
          'Wenn du im iOS-Simulator oder mit flutter run testest, laden App-Store-Produkte möglicherweise nicht. Verwende ein physisches Gerät mit Sandbox-Konto oder starte aus Xcode mit einer StoreKit-Konfiguration.',
    ),
    ('de', PremiumPurchaseIssue.offeringsUnavailable) => (
      title: 'Pläne sind derzeit nicht verfügbar',
      body:
          'Die Premium-Pläne konnten gerade nicht aus dem Store geladen werden. Bitte versuche es in Kürze erneut.',
    ),
    (_, PremiumPurchaseIssue.missingApiKey) => (
      title: 'Purchase setup is missing',
      body:
          'RevenueCat is not configured for this build. Add the appropriate store purchase key before testing purchases.',
    ),
    (_, PremiumPurchaseIssue.iosDebugStoreKitRequired) => (
      title: 'iOS simulator testing is limited',
      body:
          'If you are testing on iOS Simulator or launching with flutter run, App Store products may not load. Use a physical device with a sandbox account, or run from Xcode with a StoreKit configuration.',
    ),
    (_, PremiumPurchaseIssue.offeringsUnavailable) => (
      title: 'Plans are temporarily unavailable',
      body:
          'Premium plans could not be loaded from the store right now. Please try again in a moment.',
    ),
  };
}

String _localizedUnavailablePrice(BuildContext context) {
  final languageCode =
      Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
  return switch (languageCode) {
    'tr' => 'Mağaza fiyatı alınamadı',
    'de' => 'Store-Preis nicht verfügbar',
    _ => 'Store price unavailable',
  };
}

class PremiumRestoreSection extends ConsumerWidget {
  const PremiumRestoreSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actionState = ref.watch(purchaseActionProvider);
    final isGuest = ref.watch(currentUserIdProvider) == 'anonymous';

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Text(
            isGuest
                ? 'premium.sign_in_to_purchase'.tr()
                : 'premium.restore_info'.tr(),
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
                    if (isGuest) {
                      context.push(AppRoutes.login);
                      return;
                    }

                    ref
                        .read(purchaseActionProvider.notifier)
                        .restorePurchases();
                  },
            icon:
                actionState.isLoading &&
                    actionState.purchasingPlan == null &&
                    !isGuest
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isGuest ? LucideIcons.logIn : LucideIcons.rotateCcw,
                    size: 16,
                  ),
            label: Text(
              isGuest ? 'auth.login'.tr() : 'premium.restore_purchases'.tr(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'premium.terms_note'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'premium.account_required_title'.tr(),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'premium.sign_in_to_purchase'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'premium.legal_links_note'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          children: [
            TextButton(
              onPressed: () => _openExternal(
                'https://budgiebreedingtracker.online/privacy-policy.html',
              ),
              child: Text('settings.privacy_policy'.tr()),
            ),
            TextButton(
              onPressed: () => _openExternal(
                'https://budgiebreedingtracker.online/terms-of-service.html',
              ),
              child: Text('settings.terms'.tr()),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
