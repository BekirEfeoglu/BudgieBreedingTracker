import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_bird_picker.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_helpers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_progress_phases.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_result_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_section_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_picker_dialog.dart';

class AiGeneticsTab extends ConsumerStatefulWidget {
  const AiGeneticsTab({super.key, this.initialBirdId});

  final String? initialBirdId;

  @override
  ConsumerState<AiGeneticsTab> createState() => _AiGeneticsTabState();
}

class _AiGeneticsTabState extends ConsumerState<AiGeneticsTab> {
  Bird? _selectedFather;
  Bird? _selectedMother;

  bool get _hasPairSelection =>
      _selectedFather != null && _selectedMother != null;

  Future<void> _selectFather() async {
    final bird = await showBirdPickerDialog(
      context,
      genderFilter: BirdGender.male,
    );
    if (bird == null || !mounted) return;
    setState(() => _selectedFather = bird);
    final genotype = birdToGenotype(bird);
    ref.read(fatherGenotypeProvider.notifier).state = genotype;
    ref.read(selectedFatherBirdNameProvider.notifier).state = bird.name;
  }

  Future<void> _selectMother() async {
    final bird = await showBirdPickerDialog(
      context,
      genderFilter: BirdGender.female,
    );
    if (bird == null || !mounted) return;
    setState(() => _selectedMother = bird);
    final genotype = birdToGenotype(bird);
    ref.read(motherGenotypeProvider.notifier).state = genotype;
    ref.read(selectedMotherBirdNameProvider.notifier).state = bird.name;
  }

  void _clearFather() {
    setState(() => _selectedFather = null);
    ref.read(fatherGenotypeProvider.notifier).state =
        const ParentGenotype.empty(gender: BirdGender.male);
    ref.read(selectedFatherBirdNameProvider.notifier).state = null;
  }

  void _clearMother() {
    setState(() => _selectedMother = null);
    ref.read(motherGenotypeProvider.notifier).state =
        const ParentGenotype.empty(gender: BirdGender.female);
    ref.read(selectedMotherBirdNameProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(localAiConfigProvider);
    final geneticsAsync = ref.watch(geneticsAiAnalysisProvider);
    final phase = ref.watch(geneticsAiPhaseProvider);
    final calculatorResults = ref.watch(offspringResultsProvider);

    final isLoading = geneticsAsync is AsyncLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AiSectionCard(
        title: 'genetics.local_ai_genetics_comment'.tr(),
        icon: LucideIcons.dna,
        subtitle: 'genetics.local_ai_genetics_subtitle'.tr(),
        infoText: 'genetics.local_ai_genetics_info'.tr(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AiBirdPicker(
              selectedFather: _selectedFather,
              selectedMother: _selectedMother,
              onSelectFather: _selectFather,
              onSelectMother: _selectMother,
              onClearFather: _clearFather,
              onClearMother: _clearMother,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: configAsync.isLoading ||
                        isLoading ||
                        !_hasPairSelection
                    ? null
                    : () async {
                        final config =
                            ref.read(localAiConfigProvider).asData?.value;
                        if (config == null) return;
                        final father = ref.read(fatherGenotypeProvider);
                        final mother = ref.read(motherGenotypeProvider);
                        await ref
                            .read(geneticsAiAnalysisProvider.notifier)
                            .analyze(
                              config: config,
                              father: father,
                              mother: mother,
                              fatherName: _selectedFather?.name,
                              motherName: _selectedMother?.name,
                              calculatorResults:
                                  calculatorResults ?? const [],
                            );
                      },
                icon: isLoading
                    ? const AiButtonSpinner()
                    : const Icon(LucideIcons.sparkles, size: 18),
                label: Text('genetics.run_genetics_ai'.tr()),
              ),
            ),
            if (!_hasPairSelection) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'genetics.local_ai_pair_required'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            AiProgressPhases(phase: phase),
            AiAnimatedResultSlot(
              isLoading: isLoading,
              hasError: geneticsAsync.hasError,
              errorMessage: geneticsAsync.hasError
                  ? formatAiError(geneticsAsync.error)
                  : null,
              child: geneticsAsync.asData?.value != null
                  ? _buildResult(geneticsAsync.asData!.value!)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(LocalAiGeneticsInsight result) {
    return AiResultSection(
      title: 'genetics.genetics_ai_result'.tr(),
      confidence: result.confidence,
      summary: result.summary,
      bullets: [
        if (result.matchedGenetics.isNotEmpty)
          '${'genetics.local_ai_matched_genetics'.tr()}: ${result.matchedGenetics.map(_localizedGeneticId).join(', ')}',
        ...result.likelyMutations,
        if (result.sexLinkedNote.isNotEmpty) result.sexLinkedNote,
        ...result.warnings,
        ...result.nextChecks,
      ],
    );
  }

  static String _localizedGeneticId(String id) {
    final record = MutationDatabase.getById(id);
    if (record == null) {
      return PhenotypeLocalizer.localizeMutation(id);
    }
    return record.localizationKey.tr();
  }
}
