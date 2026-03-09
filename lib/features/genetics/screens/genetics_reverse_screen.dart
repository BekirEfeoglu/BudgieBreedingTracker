import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

List<Map<String, dynamic>> _calculateReverseResultsInIsolate(
  List<String> selectedMutationIds,
) {
  final calculator = const ReverseCalculator();
  final results = calculator.calculateParents(selectedMutationIds.toSet());

  return results
      .map(
        (r) => <String, dynamic>{
          'father': r.father.mutations.map((k, v) => MapEntry(k, v.name)),
          'mother': r.mother.mutations.map((k, v) => MapEntry(k, v.name)),
          'probabilityMale': r.probabilityMale,
          'probabilityFemale': r.probabilityFemale,
        },
      )
      .toList();
}

AlleleState _parseAlleleState(String value) {
  return switch (value) {
    'carrier' => AlleleState.carrier,
    'split' => AlleleState.split,
    _ => AlleleState.visual,
  };
}

Map<String, AlleleState> _parseParentMutations(dynamic raw) {
  if (raw is! Map) return const {};

  final parsed = <String, AlleleState>{};
  for (final entry in raw.entries) {
    if (entry.key is! String || entry.value is! String) continue;
    parsed[entry.key as String] = _parseAlleleState(entry.value as String);
  }
  return parsed;
}

ReverseCalculationResult _deserializeReverseResult(Map<String, dynamic> raw) {
  final fatherMutations = _parseParentMutations(raw['father']);
  final motherMutations = _parseParentMutations(raw['mother']);

  return ReverseCalculationResult(
    father: ParentGenotype(gender: BirdGender.male, mutations: fatherMutations),
    mother: ParentGenotype(
      gender: BirdGender.female,
      mutations: motherMutations,
    ),
    probabilityMale: (raw['probabilityMale'] as num?)?.toDouble() ?? 0,
    probabilityFemale: (raw['probabilityFemale'] as num?)?.toDouble() ?? 0,
  );
}

/// Screen allowing the user to select target offspring mutations and receive parent combinations.
class GeneticsReverseScreen extends ConsumerStatefulWidget {
  const GeneticsReverseScreen({super.key});

  @override
  ConsumerState<GeneticsReverseScreen> createState() =>
      _GeneticsReverseScreenState();
}

class _GeneticsReverseScreenState extends ConsumerState<GeneticsReverseScreen> {
  final Set<String> _selectedModifiers = {};

  List<ReverseCalculationResult>? _results;
  bool _isLoading = false;

  void _onToggleModifier(String mutationId) {
    setState(() {
      if (_selectedModifiers.contains(mutationId)) {
        _selectedModifiers.remove(mutationId);
      } else {
        _selectedModifiers.add(mutationId);
      }
      _results = null; // Clear old results
    });
  }

  Future<void> _calculateParents() async {
    if (_selectedModifiers.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Run slightly delayed to allow UI to show loading indicator if calculating many mutations
      await Future.delayed(const Duration(milliseconds: 50));

      final rawResults = await compute(
        _calculateReverseResultsInIsolate,
        _selectedModifiers.toList(growable: false),
      );
      final results = rawResults
          .map(_deserializeReverseResult)
          .toList(growable: false);

      if (mounted) {
        setState(() {
          _results = results;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter mutations as single combined list for Reverse calculation
    final allMutations =
        MutationDatabase.allMutations
            .where((m) => m.id != 'bluefactor_1' && m.id != 'bluefactor_2')
            .toList()
          ..sort((a, b) => a.category.compareTo(b.category));

    return Scaffold(
      appBar: AppBar(title: Text('genetics.reverse_calculator'.tr())),
      body: Column(
        children: [
          // Upper half: Offspring Target Selection
          Expanded(
            flex: 2,
            child: Container(
              color: theme.colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'genetics.reverse_prompt'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      itemCount: allMutations.length,
                      itemBuilder: (context, index) {
                        final record = allMutations[index];
                        final isSelected = _selectedModifiers.contains(
                          record.id,
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) => _onToggleModifier(record.id),
                          title: Text(record.localizationKey.tr()),
                          subtitle: Text(
                            record.category,
                            style: theme.textTheme.bodySmall,
                          ),
                          secondary: Icon(
                            isSelected
                                ? LucideIcons.checkCircle2
                                : LucideIcons.circle,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: PrimaryButton(
                      label: 'genetics.find_parents'.tr(),
                      icon: const Icon(LucideIcons.search),
                      onPressed: _selectedModifiers.isNotEmpty
                          ? _calculateParents
                          : null,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Lower half: Results
          Expanded(
            flex: 3,
            child: Container(
              color: theme.colorScheme.surfaceContainer,
              child: _buildResultsView(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(
              'common.loading'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final results = _results;
    if (results == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.mousePointer2,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'genetics.reverse_no_selection'.tr(),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'genetics.reverse_no_combinations'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'genetics.reverse_no_combinations_desc'.tr(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _ParentComboCard(result: result, rank: index + 1);
      },
    );
  }
}

class _ParentComboCard extends StatelessWidget {
  final ReverseCalculationResult result;
  final int rank;

  const _ParentComboCard({required this.result, required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final probPercent = (result.maxProbability * 100).toStringAsFixed(1);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${'genetics.option'.tr()} #$rank',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '$probPercent% ${'common.chance'.tr()}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: _ParentSideRender(
                    title: 'genetics.father'.tr(),
                    parent: result.father,
                    iconColor: AppColors.genderMale,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: _ParentSideRender(
                    title: 'genetics.mother'.tr(),
                    parent: result.mother,
                    iconColor: AppColors.genderFemale,
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

class _ParentSideRender extends StatelessWidget {
  final String title;
  final ParentGenotype parent;
  final Color iconColor;

  const _ParentSideRender({
    required this.title,
    required this.parent,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMale = parent.gender == BirdGender.male;

    final mutationChips = parent.mutations.entries.map((e) {
      final mutId = e.key;
      final state = e.value;

      final record = MutationDatabase.getById(mutId);
      final localizedName = record?.localizationKey.tr() ?? mutId;

      String label = localizedName;
      if (state == AlleleState.carrier || state == AlleleState.split) {
        label = '$localizedName (${'genetics.carrier'.tr()})';
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(
              isMale ? AppIcons.male : AppIcons.female,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (mutationChips.isEmpty)
          Text(
            'genetics.mutation_normal'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...mutationChips,
      ],
    );
  }
}
