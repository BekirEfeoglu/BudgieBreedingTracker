import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';

enum LegalDocumentType { privacyPolicy, termsOfService, communityGuidelines }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.type});

  final LegalDocumentType type;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    final isCommunityGuidelines = type == LegalDocumentType.communityGuidelines;

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (type) {
          LegalDocumentType.privacyPolicy => 'settings.privacy_policy'.tr(),
          LegalDocumentType.termsOfService => 'settings.terms'.tr(),
          LegalDocumentType.communityGuidelines =>
            'legal.community_guidelines_title'.tr(),
        }, key: const ValueKey('legalDocumentAppBarTitle')),
      ),
      body: isCommunityGuidelines
          ? _CommunityGuidelinesView(sections: sections)
          : ListView(
              padding: AppSpacing.screenPadding,
              children: [
                Text(
                  'legal.last_updated'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final section in sections) ...[
                  _LegalSectionCard(title: section.$1, body: section.$2),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
    );
  }

  List<(String, String)> _buildSections() {
    if (type == LegalDocumentType.privacyPolicy) {
      return [
        (
          'legal.privacy_collected_title'.tr(),
          'legal.privacy_collected_body'.tr(),
        ),
        ('legal.privacy_usage_title'.tr(), 'legal.privacy_usage_body'.tr()),
        ('legal.privacy_ads_title'.tr(), 'legal.privacy_ads_body'.tr()),
        (
          'legal.privacy_security_title'.tr(),
          'legal.privacy_security_body'.tr(),
        ),
        ('legal.privacy_contact_title'.tr(), 'legal.privacy_contact_body'.tr()),
      ];
    }

    if (type == LegalDocumentType.communityGuidelines) {
      return [
        ('legal.cg_conduct_title'.tr(), 'legal.cg_conduct_body'.tr()),
        ('legal.cg_content_title'.tr(), 'legal.cg_content_body'.tr()),
        ('legal.cg_enforcement_title'.tr(), 'legal.cg_enforcement_body'.tr()),
        ('legal.cg_reporting_title'.tr(), 'legal.cg_reporting_body'.tr()),
      ];
    }

    return [
      ('legal.terms_acceptance_title'.tr(), 'legal.terms_acceptance_body'.tr()),
      ('legal.terms_account_title'.tr(), 'legal.terms_account_body'.tr()),
      (
        'legal.terms_subscription_title'.tr(),
        'legal.terms_subscription_body'.tr(),
      ),
      ('legal.terms_contact_title'.tr(), 'legal.terms_contact_body'.tr()),
    ];
  }
}

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

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _CommunityHeroCard extends StatelessWidget {
  const _CommunityHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A62), Color(0xFF1E40AF), Color(0xFF60A5FA)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'legal.cg_kicker'.tr().toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: const Center(
              child: IconTheme(
                data: IconThemeData(color: Colors.white, size: 26),
                child: AppIcon(AppIcons.community),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'legal.cg_hero_body'.tr(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroChip(
                icon: LucideIcons.heartHandshake,
                text: 'legal.cg_chip_respect'.tr(),
              ),
              _HeroChip(
                icon: LucideIcons.shieldCheck,
                text: 'legal.cg_chip_safety'.tr(),
              ),
              _HeroChip(
                icon: LucideIcons.messagesSquare,
                text: 'legal.cg_chip_participation'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidelineVisual {
  const _GuidelineVisual({
    required this.title,
    required this.body,
    required this.iconAsset,
    required this.tint,
  });

  final String title;
  final String body;
  final String iconAsset;
  final Color tint;
}

class _CommunityManifestCard extends StatelessWidget {
  const _CommunityManifestCard({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialDivider extends StatelessWidget {
  const _EditorialDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: theme.colorScheme.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: theme.colorScheme.outlineVariant),
        ),
      ],
    );
  }
}

class _GuidelineGuideCard extends StatelessWidget {
  const _GuidelineGuideCard({
    super.key,
    required this.index,
    required this.visual,
    this.alignRight = false,
  });

  final int index;
  final _GuidelineVisual visual;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stripeAlignment = alignRight
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Container(
      key: key,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Stack(
          children: [
            Align(
              alignment: stripeAlignment,
              child: Container(
                width: 84,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: alignRight ? Alignment.topRight : Alignment.topLeft,
                    end: alignRight
                        ? Alignment.bottomLeft
                        : Alignment.bottomRight,
                    colors: [
                      visual.tint.withValues(alpha: 0.18),
                      visual.tint.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '0$index',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: visual.tint,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              visual.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: visual.tint.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                        ),
                        child: Center(
                          child: IconTheme(
                            data: IconThemeData(color: visual.tint, size: 22),
                            child: AppIcon(visual.iconAsset),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    visual.body,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityFooterNote extends StatelessWidget {
  const _CommunityFooterNote({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.sparkles,
                size: 18,
                color: AppColors.info,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
