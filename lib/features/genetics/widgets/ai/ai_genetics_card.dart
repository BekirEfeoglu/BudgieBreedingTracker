import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_helpers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_result_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_section_card.dart';

class AiGeneticsCard extends ConsumerWidget {
  const AiGeneticsCard({
    super.key,
    required this.fatherGenotype,
    required this.motherGenotype,
    required this.selectedFatherName,
    required this.selectedMotherName,
    required this.calculatorResults,
  });

  final ParentGenotype fatherGenotype;
  final ParentGenotype motherGenotype;
  final String? selectedFatherName;
  final String? selectedMotherName;
  final List<OffspringResult>? calculatorResults;

  bool get _hasPairSelection =>
      fatherGenotype.isNotEmpty || motherGenotype.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(localAiConfigProvider);
    final geneticsAsync = ref.watch(geneticsAiAnalysisProvider);

    return AiSectionCard(
      title: 'genetics.local_ai_genetics_comment'.tr(),
      icon: LucideIcons.dna,
      subtitle: 'genetics.local_ai_genetics_subtitle'.tr(),
      infoText: 'genetics.local_ai_genetics_info'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: configAsync.isLoading ||
                      geneticsAsync.isLoading ||
                      !_hasPairSelection
                  ? null
                  : () async {
                      final config =
                          ref.read(localAiConfigProvider).asData?.value;
                      if (config == null) return;
                      await ref
                          .read(geneticsAiAnalysisProvider.notifier)
                          .analyze(
                            config: config,
                            father: fatherGenotype,
                            mother: motherGenotype,
                            fatherName: selectedFatherName,
                            motherName: selectedMotherName,
                            calculatorResults:
                                calculatorResults ?? const [],
                          );
                    },
              icon: geneticsAsync.isLoading
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
          AiAnimatedResultSlot(
            isLoading: geneticsAsync.isLoading,
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
