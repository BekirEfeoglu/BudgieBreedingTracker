import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';

class CageLedgerSheet extends StatelessWidget {
  final List<Bird> birds;
  final ValueChanged<Bird> onBirdTap;

  const CageLedgerSheet({
    super.key,
    required this.birds,
    required this.onBirdTap,
  });

  @override
  Widget build(BuildContext context) {
    final summaries = buildCageSummaries(birds);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const AppIcon(AppIcons.nest),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'birds.cage_ledger'.tr(),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                AppIconButton(
                  icon: const Icon(LucideIcons.x),
                  semanticLabel: 'common.close'.tr(),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (summaries.isEmpty)
              EmptyState(
                icon: const AppIcon(AppIcons.nest),
                title: 'birds.no_cages'.tr(),
                subtitle: 'birds.no_cages_hint'.tr(),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: summaries.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final summary = summaries[index];
                    return _CageSummarySection(
                      summary: summary,
                      onBirdTap: onBirdTap,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CageSummarySection extends StatelessWidget {
  final CageSummary summary;
  final ValueChanged<Bird> onBirdTap;

  const _CageSummarySection({required this.summary, required this.onBirdTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = summary.isUnassigned
        ? 'birds.unassigned_cage'.tr()
        : summary.cageNumber!;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                Text(
                  '${summary.aliveCount} ${'birds.cage_occupants'.tr()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (final bird in summary.birds)
            ListTile(
              dense: true,
              leading: const AppIcon(AppIcons.bird),
              title: Text(bird.name, overflow: TextOverflow.ellipsis),
              subtitle: bird.ringNumber == null
                  ? null
                  : Text(bird.ringNumber!, overflow: TextOverflow.ellipsis),
              onTap: () => onBirdTap(bird),
            ),
        ],
      ),
    );
  }
}
