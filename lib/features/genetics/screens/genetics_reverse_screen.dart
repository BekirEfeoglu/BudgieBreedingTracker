import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/reverse_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/parent_combo_card.dart';

List<Map<String, dynamic>> _calculateReverseResultsInIsolate(
  List<String> selectedMutationIds,
) {
  const calculator = ReverseCalculator();
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
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'genetics.reverse_calculator'.tr(),
          iconAsset: AppIcons.mutation,
        ),
      ),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: PrimaryButton(
            label: 'genetics.find_parents'.tr(),
            icon: const Icon(LucideIcons.search),
            onPressed: _selectedModifiers.isNotEmpty
                ? _calculateParents
                : null,
            isLoading: _isLoading,
          ),
        ),
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
      return EmptyState(
        icon: const AppIcon(AppIcons.dna),
        title: 'genetics.reverse_no_selection'.tr(),
        subtitle: 'genetics.reverse_select_mutations'.tr(),
      );
    }

    if (results.isEmpty) {
      return EmptyState(
        icon: const Icon(LucideIcons.alertCircle),
        title: 'genetics.reverse_no_combinations'.tr(),
        subtitle: 'genetics.reverse_no_combinations_desc'.tr(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ParentComboCard(result: result, rank: index + 1);
      },
    );
  }
}
