import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/linkage_phase.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/linkage_display.dart';

/// Localized label for a [LinkagePhase] segment.
String _phaseLabelKey(LinkagePhase phase) => switch (phase) {
  LinkagePhase.auto => 'genetics.linkage_phase_auto',
  LinkagePhase.coupling => 'genetics.linkage_phase_coupling',
  LinkagePhase.repulsion => 'genetics.linkage_phase_repulsion',
};

/// Lets the user explicitly set the Z-linkage recombination phase
/// (coupling/repulsion) for the father's tightest linked mutation pair,
/// overriding the engine's implicit inference (`LinkagePhase.auto`).
///
/// Renders nothing when the father genotype has no eligible linked pair
/// (female parent, fewer than two heterozygous participants at a known
/// [LinkageCatalog] pair, or both alleles visual/homozygous).
class LinkagePhaseControl extends ConsumerWidget {
  const LinkagePhaseControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final father = ref.watch(fatherGenotypeProvider);
    final pair = activeLinkagePairForFather(father);
    if (pair == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final selectedPhase = father.phaseFor(pair.id1, pair.id2);
    final distanceLabel =
        '~${pair.info.displayCentiMorgansLabel} cM'
        '${linkageEvidenceSuffix(pair.info.evidence)}';
    final pairLabel =
        '${linkageMutationName(pair.id1)} ↔ ${linkageMutationName(pair.id2)}';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Semantics(
        label: 'genetics.linkage_phase_title'.tr(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'genetics.linkage_phase_title'.tr(),
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '$pairLabel ($distanceLabel)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<LinkagePhase>(
              segments: LinkagePhase.values
                  .map(
                    (phase) => ButtonSegment(
                      value: phase,
                      label: Text(_phaseLabelKey(phase).tr()),
                    ),
                  )
                  .toList(),
              selected: {selectedPhase},
              onSelectionChanged: (selected) {
                ref
                    .read(fatherGenotypeProvider.notifier)
                    .setPhaseOverride(pair.id1, pair.id2, selected.first);
              },
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'genetics.linkage_phase_explain'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
