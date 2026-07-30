import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../providers/admin_build_distribution_provider.dart';

class AdminBuildDistributionSection extends ConsumerWidget {
  const AdminBuildDistributionSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionAsync = ref.watch(adminBuildDistributionProvider);

    return distributionAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: LinearProgressIndicator(),
        ),
      ),
      error: (_, __) => _BuildDistributionErrorCard(
        onRetry: () => ref.invalidate(adminBuildDistributionProvider),
      ),
      data: (distribution) =>
          _BuildDistributionContent(distribution: distribution),
    );
  }
}

class _BuildDistributionContent extends StatelessWidget {
  const _BuildDistributionContent({required this.distribution});

  final BuildDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(
              AppIcons.monitoring,
              size: 20,
              semanticsLabel: 'admin.build_distribution'.tr(),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'admin.build_distribution'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'admin.build_distribution_window'.tr(
            args: [distribution.windowDays.toString()],
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (distribution.platforms.isEmpty)
          _BuildDistributionEmptyCard()
        else
          ...distribution.platforms.map(
            (platform) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _PlatformBuildCard(distribution: platform),
            ),
          ),
      ],
    );
  }
}

class _PlatformBuildCard extends StatelessWidget {
  const _PlatformBuildCard({required this.distribution});

  final PlatformBuildDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platformLabel = switch (distribution.platform) {
      'ios' => 'admin.ios'.tr(),
      'android' => 'admin.android'.tr(),
      _ => distribution.platform,
    };

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.smartphone, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    platformLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${distribution.coveragePercent.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'admin.build_telemetry_coverage'.tr(
                args: [
                  distribution.versionedUsers.toString(),
                  distribution.totalUsers.toString(),
                ],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (distribution.builds.isEmpty)
              Text(
                'admin.no_versioned_sessions'.tr(),
                style: theme.textTheme.bodyMedium,
              )
            else
              ...distribution.builds.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _BuildAdoptionRow(entry: entry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BuildAdoptionRow extends StatelessWidget {
  const _BuildAdoptionRow({required this.entry});

  final BuildAdoptionEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = entry.adoptionPercent.clamp(0.0, 100.0);

    return Semantics(
      label: 'admin.build_adoption_semantics'.tr(
        args: [
          entry.appVersion,
          entry.userCount.toString(),
          percentage.toStringAsFixed(1),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final version = Text(
                entry.appVersion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              );
              final share = Text(
                'admin.build_user_share'.tr(
                  args: [
                    entry.userCount.toString(),
                    percentage.toStringAsFixed(1),
                  ],
                ),
                style: theme.textTheme.bodySmall,
              );

              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    version,
                    const SizedBox(height: AppSpacing.xs),
                    share,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: version),
                  const SizedBox(width: AppSpacing.sm),
                  share,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
        ],
      ),
    );
  }
}

class _BuildDistributionEmptyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            const Icon(LucideIcons.clock, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text('admin.build_distribution_no_data'.tr())),
          ],
        ),
      ),
    );
  }
}

class _BuildDistributionErrorCard extends StatelessWidget {
  const _BuildDistributionErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Icon(
              LucideIcons.alertTriangle,
              size: 20,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text('admin.build_distribution_error'.tr())),
            AppIconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              tooltip: 'common.retry'.tr(),
              semanticLabel: 'common.retry'.tr(),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
