import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_helpers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_image_picker_zone.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_progress_phases.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_result_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_section_card.dart';

class AiMutationTab extends ConsumerStatefulWidget {
  const AiMutationTab({super.key});

  @override
  ConsumerState<AiMutationTab> createState() => _AiMutationTabState();
}

class _AiMutationTabState extends ConsumerState<AiMutationTab> {
  String? _selectedImagePath;

  void _onImageSelected(String path) {
    setState(() => _selectedImagePath = path);
    ref.read(mutationImageAiAnalysisProvider.notifier).clear();
  }

  void _onImageCleared() {
    setState(() => _selectedImagePath = null);
    ref.read(mutationImageAiAnalysisProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(localAiConfigProvider);
    final mutationState = ref.watch(mutationImageAiAnalysisProvider);
    final phase = ref.watch(mutationAiPhaseProvider);

    final isLoading = mutationState is AsyncLoading;
    final hasError = mutationState is AsyncError;
    final result = mutationState.asData?.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AiSectionCard(
        title: 'genetics.image_ai_title'.tr(),
        icon: LucideIcons.image,
        subtitle: 'genetics.image_ai_subtitle'.tr(),
        infoText: 'genetics.image_ai_desc'.tr(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AiImagePickerZone(
              selectedImagePath: _selectedImagePath,
              onImageSelected: _onImageSelected,
              onImageCleared: _onImageCleared,
              tips: [
                'genetics.ai_mutation_photo_tip_1'.tr(),
                'genetics.ai_mutation_photo_tip_2'.tr(),
                'genetics.ai_mutation_photo_tip_3'.tr(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: configAsync.isLoading ||
                        isLoading ||
                        _selectedImagePath == null
                    ? null
                    : () async {
                        final config = ref
                            .read(localAiConfigProvider)
                            .asData
                            ?.value;
                        if (config == null || _selectedImagePath == null) {
                          return;
                        }
                        await ref
                            .read(
                              mutationImageAiAnalysisProvider.notifier,
                            )
                            .analyze(
                              config: config,
                              imagePath: _selectedImagePath!,
                            );
                      },
                icon: isLoading
                    ? const AiButtonSpinner()
                    : const Icon(LucideIcons.scanLine, size: 18),
                label: Text('genetics.run_image_ai'.tr()),
              ),
            ),
            AiProgressPhases(phase: phase),
            AiAnimatedResultSlot(
              isLoading: isLoading,
              hasError: hasError,
              errorMessage: hasError
                  ? formatAiError((mutationState as AsyncError).error)
                  : null,
              child: result != null ? _buildResult(result) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(LocalAiMutationInsight result) {
    return AiResultSection(
      title: 'genetics.image_ai_result'.tr(
        args: [_mutationLabel(result.predictedMutation)],
      ),
      confidence: result.confidence,
      summary: result.rationale,
      bullets: [
        if (result.inoWarning.isNotEmpty)
          '\u26A0\uFE0F ${result.inoWarning}',
        'genetics.local_ai_series_label'
            .tr(args: [_seriesLabel(result.baseSeries)]),
        'genetics.local_ai_pattern_label'
            .tr(args: [_patternLabel(result.patternFamily)]),
        if (result.bodyColor.isNotEmpty)
          '${'genetics.image_body_color'.tr()}: ${_translateUnknown(result.bodyColor)}',
        if (result.wingPattern.isNotEmpty)
          '${'genetics.image_wing_pattern'.tr()}: ${_translateUnknown(result.wingPattern)}',
        if (result.eyeColor.isNotEmpty)
          '${'genetics.image_eye_color'.tr()}: ${_translateUnknown(result.eyeColor)}',
        if (result.secondaryPossibilities.isNotEmpty)
          'genetics.local_ai_alternatives_label'.tr(
            args: [
              result.secondaryPossibilities
                  .map(_mutationLabel)
                  .join(', '),
            ],
          ),
      ],
    );
  }

  static String _mutationLabel(String key) => switch (key) {
        'normal_light_green' =>
          'genetics.mutation_normal_light_green'.tr(),
        'normal_dark_green' =>
          'genetics.mutation_normal_dark_green'.tr(),
        'normal_olive' => 'genetics.mutation_normal_olive'.tr(),
        'spangle_green' => 'genetics.mutation_spangle_green'.tr(),
        'cinnamon_green' => 'genetics.mutation_cinnamon_green'.tr(),
        'opaline_green' => 'genetics.mutation_opaline_green'.tr(),
        'dominant_pied_green' =>
          'genetics.mutation_dominant_pied_green'.tr(),
        'recessive_pied_green' =>
          'genetics.mutation_recessive_pied_green'.tr(),
        'clearwing_green' => 'genetics.mutation_clearwing_green'.tr(),
        'greywing_green' => 'genetics.mutation_greywing_green'.tr(),
        'dilute_green' => 'genetics.mutation_dilute_green'.tr(),
        'clearbody_green' => 'genetics.mutation_clearbody_green'.tr(),
        'lutino' => 'genetics.mutation_lutino'.tr(),
        'yellowface_blue' => 'genetics.mutation_yellowface_blue'.tr(),
        'violet_green' => 'genetics.mutation_violet_green'.tr(),
        'normal_skyblue' => 'genetics.mutation_normal_skyblue'.tr(),
        'normal_cobalt' => 'genetics.mutation_normal_cobalt'.tr(),
        'normal_mauve' => 'genetics.mutation_normal_mauve'.tr(),
        'spangle_blue' => 'genetics.mutation_spangle_blue'.tr(),
        'cinnamon_blue' => 'genetics.mutation_cinnamon_blue'.tr(),
        'opaline_blue' => 'genetics.mutation_opaline_blue'.tr(),
        'dominant_pied_blue' =>
          'genetics.mutation_dominant_pied_blue'.tr(),
        'recessive_pied_blue' =>
          'genetics.mutation_recessive_pied_blue'.tr(),
        'clearwing_blue' => 'genetics.mutation_clearwing_blue'.tr(),
        'greywing_blue' => 'genetics.mutation_greywing_blue'.tr(),
        'dilute_blue' => 'genetics.mutation_dilute_blue'.tr(),
        'clearbody_blue' => 'genetics.mutation_clearbody_blue'.tr(),
        'albino' => 'genetics.mutation_albino'.tr(),
        'grey_green' => 'genetics.mutation_grey_green'.tr(),
        'grey_blue' => 'genetics.mutation_grey_blue'.tr(),
        'fallow_green' => 'genetics.mutation_fallow_green'.tr(),
        'fallow_blue' => 'genetics.mutation_fallow_blue'.tr(),
        'lacewing_green' => 'genetics.mutation_lacewing_green'.tr(),
        'lacewing_blue' => 'genetics.mutation_lacewing_blue'.tr(),
        'opaline_cinnamon_green' =>
          'genetics.mutation_opaline_cinnamon_green'.tr(),
        'opaline_cinnamon_blue' =>
          'genetics.mutation_opaline_cinnamon_blue'.tr(),
        'violet_blue' => 'genetics.mutation_violet_blue'.tr(),
        'slate_blue' => 'genetics.mutation_slate_blue'.tr(),
        'dark_eyed_clear_green' =>
          'genetics.mutation_dark_eyed_clear_green'.tr(),
        'dark_eyed_clear_blue' =>
          'genetics.mutation_dark_eyed_clear_blue'.tr(),
        'texas_clearbody_green' =>
          'genetics.mutation_texas_clearbody_green'.tr(),
        'texas_clearbody_blue' =>
          'genetics.mutation_texas_clearbody_blue'.tr(),
        'creamino' => 'genetics.mutation_creamino'.tr(),
        _ => 'common.unknown'.tr(),
      };

  static String _seriesLabel(String key) => switch (key) {
        'green' => 'genetics.series_green'.tr(),
        'blue' => 'genetics.series_blue'.tr(),
        'lutino' => 'genetics.series_lutino'.tr(),
        'albino' => 'genetics.series_albino'.tr(),
        'grey' => 'genetics.series_grey'.tr(),
        _ => 'genetics.series_unknown'.tr(),
      };

  static String _patternLabel(String key) => switch (key) {
        'normal' => 'genetics.pattern_normal'.tr(),
        'spangle' => 'genetics.pattern_spangle'.tr(),
        'pied' => 'genetics.pattern_pied'.tr(),
        'opaline' => 'genetics.pattern_opaline'.tr(),
        'cinnamon' => 'genetics.pattern_cinnamon'.tr(),
        'clearwing' => 'genetics.pattern_clearwing'.tr(),
        'greywing' => 'genetics.pattern_greywing'.tr(),
        'dilute' => 'genetics.pattern_dilute'.tr(),
        'clearbody' => 'genetics.pattern_clearbody'.tr(),
        'yellowface' => 'genetics.pattern_yellowface'.tr(),
        'violet' => 'genetics.pattern_violet'.tr(),
        'ino' => 'genetics.pattern_ino'.tr(),
        'grey' => 'genetics.pattern_grey'.tr(),
        'fallow' => 'genetics.pattern_fallow'.tr(),
        'lacewing' => 'genetics.pattern_lacewing'.tr(),
        'slate' => 'genetics.pattern_slate'.tr(),
        _ => 'genetics.pattern_unknown'.tr(),
      };

  /// Translates common English tokens that AI models may return
  /// despite the Turkish-only system prompt.
  static String _translateUnknown(String value) {
    final lower = value.trim().toLowerCase();
    return switch (lower) {
      'unknown' => 'common.unknown'.tr(),
      'none' => 'common.none'.tr(),
      // Eye colors
      'red/pink' || 'red' || 'pink' => 'Kırmızı/Pembe',
      'black' || 'dark' || 'dark/black' => 'Siyah/Koyu',
      'plum' || 'dark red' => 'Erik rengi',
      // Body/wing colors
      'blue' => 'Mavi',
      'light_blue' || 'light blue' || 'sky blue' => 'Açık mavi',
      'cobalt' => 'Kobalt mavi',
      'mauve' => 'Leylak',
      'brown' || 'cinnamon' => 'Kahverengi',
      'white' => 'Beyaz',
      'yellow' => 'Sarı',
      'green' || 'bright green' => 'Yeşil',
      'dark green' => 'Koyu yeşil',
      'olive' => 'Zeytin yeşili',
      'grey' || 'gray' => 'Gri',
      'violet' || 'purple' => 'Mor/Violet',
      // Wing patterns
      'normal' => 'Normal',
      'classic black barring' || 'black barring' => 'Siyah çizgili (normal)',
      'faint' || 'very faint' || 'minimal' => 'Çok silik',
      'reduced' => 'Azaltılmış',
      'reversed' => 'Ters desen',
      'grey barring' => 'Gri çizgili',
      'brown barring' => 'Kahverengi çizgili',
      _ => value,
    };
  }
}
