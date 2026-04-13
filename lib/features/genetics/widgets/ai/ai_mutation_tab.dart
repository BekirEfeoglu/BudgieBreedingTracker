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

class _AiMutationTabState extends ConsumerState<AiMutationTab>
    with AutomaticKeepAliveClientMixin {
  String? _selectedImagePath;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
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
          '\u26A0\uFE0F ${result.inoWarning.tr()}',
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

  static const _mutationL10nKeys = <String, String>{
    'normal_light_green': 'genetics.mutation_normal_light_green',
    'normal_dark_green': 'genetics.mutation_normal_dark_green',
    'normal_olive': 'genetics.mutation_normal_olive',
    'spangle_green': 'genetics.mutation_spangle_green',
    'cinnamon_green': 'genetics.mutation_cinnamon_green',
    'opaline_green': 'genetics.mutation_opaline_green',
    'dominant_pied_green': 'genetics.mutation_dominant_pied_green',
    'recessive_pied_green': 'genetics.mutation_recessive_pied_green',
    'clearwing_green': 'genetics.mutation_clearwing_green',
    'greywing_green': 'genetics.mutation_greywing_green',
    'dilute_green': 'genetics.mutation_dilute_green',
    'clearbody_green': 'genetics.mutation_clearbody_green',
    'lutino': 'genetics.mutation_lutino',
    'yellowface_blue': 'genetics.mutation_yellowface_blue',
    'violet_green': 'genetics.mutation_violet_green',
    'normal_skyblue': 'genetics.mutation_normal_skyblue',
    'normal_cobalt': 'genetics.mutation_normal_cobalt',
    'normal_mauve': 'genetics.mutation_normal_mauve',
    'spangle_blue': 'genetics.mutation_spangle_blue',
    'cinnamon_blue': 'genetics.mutation_cinnamon_blue',
    'opaline_blue': 'genetics.mutation_opaline_blue',
    'dominant_pied_blue': 'genetics.mutation_dominant_pied_blue',
    'recessive_pied_blue': 'genetics.mutation_recessive_pied_blue',
    'clearwing_blue': 'genetics.mutation_clearwing_blue',
    'greywing_blue': 'genetics.mutation_greywing_blue',
    'dilute_blue': 'genetics.mutation_dilute_blue',
    'clearbody_blue': 'genetics.mutation_clearbody_blue',
    'albino': 'genetics.mutation_albino',
    'grey_green': 'genetics.mutation_grey_green',
    'grey_blue': 'genetics.mutation_grey_blue',
    'fallow_green': 'genetics.mutation_fallow_green',
    'fallow_blue': 'genetics.mutation_fallow_blue',
    'lacewing_green': 'genetics.mutation_lacewing_green',
    'lacewing_blue': 'genetics.mutation_lacewing_blue',
    'opaline_cinnamon_green': 'genetics.mutation_opaline_cinnamon_green',
    'opaline_cinnamon_blue': 'genetics.mutation_opaline_cinnamon_blue',
    'violet_blue': 'genetics.mutation_violet_blue',
    'slate_blue': 'genetics.mutation_slate_blue',
    'dark_eyed_clear_green': 'genetics.mutation_dark_eyed_clear_green',
    'dark_eyed_clear_blue': 'genetics.mutation_dark_eyed_clear_blue',
    'texas_clearbody_green': 'genetics.mutation_texas_clearbody_green',
    'texas_clearbody_blue': 'genetics.mutation_texas_clearbody_blue',
    'creamino': 'genetics.mutation_creamino',
  };

  static String _mutationLabel(String key) =>
      (_mutationL10nKeys[key] ?? 'common.unknown').tr();

  static const _seriesL10nKeys = <String, String>{
    'green': 'genetics.series_green',
    'blue': 'genetics.series_blue',
    'lutino': 'genetics.series_lutino',
    'albino': 'genetics.series_albino',
    'grey': 'genetics.series_grey',
  };

  static String _seriesLabel(String key) =>
      (_seriesL10nKeys[key] ?? 'genetics.series_unknown').tr();

  static const _patternL10nKeys = <String, String>{
    'normal': 'genetics.pattern_normal',
    'spangle': 'genetics.pattern_spangle',
    'pied': 'genetics.pattern_pied',
    'opaline': 'genetics.pattern_opaline',
    'cinnamon': 'genetics.pattern_cinnamon',
    'clearwing': 'genetics.pattern_clearwing',
    'greywing': 'genetics.pattern_greywing',
    'dilute': 'genetics.pattern_dilute',
    'clearbody': 'genetics.pattern_clearbody',
    'yellowface': 'genetics.pattern_yellowface',
    'violet': 'genetics.pattern_violet',
    'ino': 'genetics.pattern_ino',
    'grey': 'genetics.pattern_grey',
    'fallow': 'genetics.pattern_fallow',
    'lacewing': 'genetics.pattern_lacewing',
    'slate': 'genetics.pattern_slate',
  };

  static String _patternLabel(String key) =>
      (_patternL10nKeys[key] ?? 'genetics.pattern_unknown').tr();

  static const _aiTokenL10nKeys = <String, String>{
    'unknown': 'common.unknown',
    'none': 'common.none',
    // Eye colors
    'red/pink': 'genetics.ai_color_red_pink',
    'red': 'genetics.ai_color_red_pink',
    'pink': 'genetics.ai_color_red_pink',
    'black': 'genetics.ai_color_black_dark',
    'dark': 'genetics.ai_color_black_dark',
    'dark/black': 'genetics.ai_color_black_dark',
    'plum': 'genetics.ai_color_plum',
    'dark red': 'genetics.ai_color_plum',
    // Body/wing colors
    'blue': 'genetics.ai_color_blue',
    'light_blue': 'genetics.ai_color_light_blue',
    'light blue': 'genetics.ai_color_light_blue',
    'sky blue': 'genetics.ai_color_light_blue',
    'cobalt': 'genetics.ai_color_cobalt',
    'mauve': 'genetics.ai_color_mauve',
    'brown': 'genetics.ai_color_brown',
    'cinnamon': 'genetics.ai_color_brown',
    'white': 'genetics.ai_color_white',
    'yellow': 'genetics.ai_color_yellow',
    'green': 'genetics.ai_color_green',
    'bright green': 'genetics.ai_color_green',
    'dark green': 'genetics.ai_color_dark_green',
    'olive': 'genetics.ai_color_olive',
    'grey': 'genetics.ai_color_grey',
    'gray': 'genetics.ai_color_grey',
    'violet': 'genetics.ai_color_violet',
    'purple': 'genetics.ai_color_violet',
    // Wing patterns
    'normal': 'genetics.ai_pattern_normal',
    'classic black barring': 'genetics.ai_pattern_black_barring',
    'black barring': 'genetics.ai_pattern_black_barring',
    'faint': 'genetics.ai_pattern_very_faint',
    'very faint': 'genetics.ai_pattern_very_faint',
    'minimal': 'genetics.ai_pattern_very_faint',
    'reduced': 'genetics.ai_pattern_reduced',
    'reversed': 'genetics.ai_pattern_reversed',
    'grey barring': 'genetics.ai_pattern_grey_barring',
    'brown barring': 'genetics.ai_pattern_brown_barring',
  };

  /// Translates common English tokens that AI models may return
  /// despite the Turkish-only system prompt.
  static String _translateUnknown(String value) {
    final lower = value.trim().toLowerCase();
    final key = _aiTokenL10nKeys[lower];
    return key != null ? key.tr() : value;
  }
}
