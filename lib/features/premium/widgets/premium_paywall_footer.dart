part of 'premium_paywall_sections.dart';

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
    final linkStyle = Theme.of(context).textTheme.labelMedium?.copyWith(
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.bold,
    );

    return RepaintBoundary(
      child: Column(
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
                  style: linkStyle,
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
                  style: linkStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
