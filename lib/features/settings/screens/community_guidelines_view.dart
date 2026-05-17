part of 'legal_document_screen.dart';

class _CommunityGuidelinesView extends StatelessWidget {
  const _CommunityGuidelinesView({required this.sections});

  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _GuidelineVisual(
        title: sections[0].$1,
        body: sections[0].$2,
        iconAsset: AppIcons.community,
        tint: AppColors.primary,
      ),
      _GuidelineVisual(
        title: sections[1].$1,
        body: sections[1].$2,
        iconAsset: AppIcons.warning,
        tint: AppColors.error,
      ),
      _GuidelineVisual(
        title: sections[2].$1,
        body: sections[2].$2,
        iconAsset: AppIcons.security,
        tint: AppColors.accent,
      ),
      _GuidelineVisual(
        title: sections[3].$1,
        body: sections[3].$2,
        iconAsset: AppIcons.comment,
        tint: AppColors.info,
      ),
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.06),
                  theme.colorScheme.surface,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -60,
          right: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.10),
            ),
          ),
        ),
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            _CommunityHeroCard(
              key: const ValueKey('communityGuidelinesHero'),
              title: 'legal.community_guidelines_title'.tr(),
              subtitle: 'legal.last_updated'.tr(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _CommunityManifestCard(
              eyebrow: 'legal.cg_manifesto_eyebrow'.tr(),
              title: 'legal.cg_manifesto_title'.tr(),
              body: 'legal.cg_manifesto_body'.tr(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'legal.last_updated'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _EditorialDivider(label: 'legal.cg_editorial_divider'.tr()),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < items.length; i++) ...[
              _GuidelineGuideCard(
                key: ValueKey('communityGuidelineCard-${i + 1}'),
                index: i + 1,
                visual: items[i],
                alignRight: i.isOdd,
              ),
              if (i < items.length - 1) const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.lg),
            _CommunityFooterNote(
              title: 'legal.cg_footer_title'.tr(),
              body: 'legal.cg_footer_body'.tr(),
            ),
          ],
        ),
      ],
    );
  }
}
