import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/bird_genotype_mapper.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/bird_stream_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

/// Dialog for selecting a bird from the user's collection to populate
/// genotype information in the genetics calculator.
class BirdPickerDialog extends ConsumerStatefulWidget {
  final BirdGender genderFilter;
  final Species speciesFilter;

  const BirdPickerDialog({
    super.key,
    required this.genderFilter,
    this.speciesFilter = Species.budgie,
  });

  @override
  ConsumerState<BirdPickerDialog> createState() => _BirdPickerDialogState();
}

class _BirdPickerDialogState extends ConsumerState<BirdPickerDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'genetics.select_bird'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AppIconButton(
                    icon: const Icon(LucideIcons.x),
                    semanticLabel: 'common.close'.tr(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'common.search'.tr(),
                  prefixIcon: const AppIcon(AppIcons.search, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Bird list
            Expanded(
              child: birdsAsync.when(
                loading: () => const LoadingState(),
                error: (e, _) =>
                    Center(child: Text('common.data_load_error'.tr())),
                data: (birds) {
                  // Filter by gender (skip filter if unknown) and alive status
                  var filtered = birds
                      .where(
                        (b) =>
                            (widget.genderFilter == BirdGender.unknown ||
                                b.gender == widget.genderFilter) &&
                            b.species == widget.speciesFilter &&
                            b.status == BirdStatus.alive,
                      )
                      .toList();

                  // Apply search
                  if (_searchQuery.isNotEmpty) {
                    filtered = filtered.where((b) {
                      return b.name.toLowerCase().contains(_searchQuery) ||
                          (b.ringNumber?.toLowerCase().contains(_searchQuery) ??
                              false);
                    }).toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'common.no_results'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final bird = filtered[index];
                      return _BirdTile(
                        bird: bird,
                        onTap: () => Navigator.of(context).pop(bird),
                      );
                    },
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

class _BirdTile extends StatelessWidget {
  final Bird bird;
  final VoidCallback onTap;

  const _BirdTile({required this.bird, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMutations = bird.mutations != null && bird.mutations!.isNotEmpty;
    final hasColor =
        bird.colorMutation != null && bird.colorMutation != BirdColor.other;
    final hasGeneticData = hasMutations || hasColor;

    return Semantics(
      label: '${bird.name}${bird.ringNumber != null ? ', ${bird.ringNumber}' : ''}, ${bird.gender.name}',
      child: ListTile(
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: bird.gender == BirdGender.male
            ? AppColors.genderMale.withValues(alpha: 0.15)
            : AppColors.genderFemale.withValues(alpha: 0.15),
        child: AppIcon(
          bird.gender == BirdGender.male ? AppIcons.male : AppIcons.female,
          size: 20,
          color: bird.gender == BirdGender.male
              ? AppColors.genderMale
              : AppColors.genderFemale,
        ),
      ),
      title: Text(
        bird.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        [
          if (bird.ringNumber != null) bird.ringNumber!,
          if (hasMutations)
            'genetics.mutation_count'.tr(args: ['${bird.mutations!.length}']),
          if (!hasMutations && hasColor) bird.colorMutation!.name,
        ].join(' - '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: hasGeneticData
          ? AppIcon(AppIcons.dna, size: 18, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    ),
    );
  }
}

/// Shows the bird picker dialog and returns the selected bird.
Future<Bird?> showBirdPickerDialog(
  BuildContext context, {
  required BirdGender genderFilter,
  Species speciesFilter = Species.budgie,
}) {
  return showDialog<Bird>(
    context: context,
    builder: (context) => BirdPickerDialog(
      genderFilter: genderFilter,
      speciesFilter: speciesFilter,
    ),
  );
}

/// Converts a [Bird] with mutation data to a [ParentGenotype].
ParentGenotype birdToGenotype(Bird bird) =>
    BirdGenotypeMapper.birdToGenotype(bird);
