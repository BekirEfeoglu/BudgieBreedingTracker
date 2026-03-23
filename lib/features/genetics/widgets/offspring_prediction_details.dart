import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/z_linked_badge.dart';

/// Phenotype name row with carrier/lethal/z-linked badges.
class PhenotypeBadges extends StatelessWidget {
  final String displayName;
  final OffspringResult result;

  const PhenotypeBadges({
    super.key,
    required this.displayName,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        if (result.isCarrier) ...[
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs + 2,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'genetics.carrier'.tr(),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
        if (hasLinkedSexLinkedMutations(result)) ...[
          const SizedBox(width: AppSpacing.xs),
          ZLinkedBadge(linkedIds: getLinkedIds(result)),
        ],
        if (result.lethalCombinationIds.isNotEmpty) ...[
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs + 2,
              vertical: 1,
            ),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.alertTriangle,
                  size: 8,
                  color: AppColors.error,
                ),
                const SizedBox(width: 2),
                Text(
                  'genetics.lethal_badge'.tr(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Expanded section showing full carrier mutations, masked mutations,
/// and genotype without truncation.
class ExpandedDetails extends StatelessWidget {
  final OffspringResult result;
  final List<String> localizedCarriedMutations;
  final List<String> localizedMaskedMutations;
  final bool showGenotype;

  const ExpandedDetails({
    super.key,
    required this.result,
    required this.localizedCarriedMutations,
    required this.localizedMaskedMutations,
    required this.showGenotype,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.carriedMutations.isNotEmpty)
          _DetailRow(
            icon: LucideIcons.eyeOff,
            iconColor: AppColors.warningTextAdaptive(context),
            child: Text(
              localizedCarriedMutations.join(', '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.warningTextAdaptive(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (result.maskedMutations.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          _DetailRow(
            icon: LucideIcons.eyeOff,
            iconColor: theme.colorScheme.onSurfaceVariant,
            child: Text(
              'genetics.masked_mutations'.tr(
                args: [localizedMaskedMutations.join(', ')],
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
        if (showGenotype && result.genotype != null) ...[
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: result.genotype!));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('genetics.genotype_copied'.tr()),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: _DetailRow(
              icon: LucideIcons.dna,
              iconColor: theme.colorScheme.onSurfaceVariant,
              child: Text(
                result.genotype!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small icon + content row for expanded details.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 12, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: child),
      ],
    );
  }
}

/// Sex indicator icon with optional unisex badge for both-sex results.
class SexIcon extends StatelessWidget {
  final OffspringSex sex;

  const SexIcon({super.key, required this.sex});

  @override
  Widget build(BuildContext context) {
    return switch (sex) {
      OffspringSex.male => const AppIcon(
        AppIcons.male,
        size: 16,
        color: AppColors.genderMale,
      ),
      OffspringSex.female => const AppIcon(
        AppIcons.female,
        size: 16,
        color: AppColors.genderFemale,
      ),
      OffspringSex.both => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            AppIcons.users,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 0.5,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              'genetics.both_sexes_label'.tr(),
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    };
  }
}
