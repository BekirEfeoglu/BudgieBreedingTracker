import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_helpers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_result_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_section_card.dart';

class AiMutationCard extends ConsumerStatefulWidget {
  const AiMutationCard({super.key});

  @override
  ConsumerState<AiMutationCard> createState() => _AiMutationCardState();
}

class _AiMutationCardState extends ConsumerState<AiMutationCard> {
  String? _selectedImagePath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(localAiConfigProvider);
    final mutationState = ref.watch(mutationImageAiAnalysisProvider);

    final isLoading = mutationState is AsyncLoading;
    final hasError = mutationState is AsyncError;
    final result = mutationState.asData?.value;

    return AiSectionCard(
      title: 'genetics.image_ai_title'.tr(),
      icon: LucideIcons.image,
      subtitle: 'genetics.image_ai_subtitle'.tr(),
      infoText: 'genetics.image_ai_desc'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );
                  final path = result?.files.single.path;
                  if (path == null || !mounted) return;
                  setState(() => _selectedImagePath = path);
                  ref
                      .read(mutationImageAiAnalysisProvider.notifier)
                      .clear();
                },
                icon: const Icon(LucideIcons.imagePlus, size: 18),
                label: Text('genetics.select_image'.tr()),
              ),
              FilledButton.icon(
                onPressed: configAsync.isLoading ||
                        isLoading ||
                        _selectedImagePath == null
                    ? null
                    : () async {
                        final config = ref
                            .read(localAiConfigProvider)
                            .asData
                            ?.value;
                        if (config == null ||
                            _selectedImagePath == null) {
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
            ],
          ),
          if (_selectedImagePath != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildImagePreview(theme),
          ],
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
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusMd),
            child: Image.file(
              File(_selectedImagePath!),
              height: 156,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Text('common.error'.tr()),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Chip(
                  label: Text(
                    _shortFileName(
                      _selectedImagePath!
                          .split(Platform.pathSeparator)
                          .last,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ActionChip(
                onPressed: () {
                  ref
                      .read(mutationImageAiAnalysisProvider.notifier)
                      .clear();
                  setState(() => _selectedImagePath = null);
                },
                avatar: const Icon(LucideIcons.x, size: 16),
                label: Text('common.clear'.tr()),
              ),
            ],
          ),
        ],
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
        'genetics.local_ai_series_label'
            .tr(args: [_seriesLabel(result.baseSeries)]),
        'genetics.local_ai_pattern_label'
            .tr(args: [_patternLabel(result.patternFamily)]),
        if (result.bodyColor.isNotEmpty)
          '${'genetics.image_body_color'.tr()}: ${result.bodyColor}',
        if (result.wingPattern.isNotEmpty)
          '${'genetics.image_wing_pattern'.tr()}: ${result.wingPattern}',
        if (result.eyeColor.isNotEmpty)
          '${'genetics.image_eye_color'.tr()}: ${result.eyeColor}',
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
        _ => 'common.unknown'.tr(),
      };

  static String _seriesLabel(String key) => switch (key) {
        'green' => 'genetics.series_green'.tr(),
        'blue' => 'genetics.series_blue'.tr(),
        'lutino' => 'genetics.series_lutino'.tr(),
        'albino' => 'genetics.series_albino'.tr(),
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
        _ => 'genetics.pattern_unknown'.tr(),
      };

  static String _shortFileName(String value) {
    if (value.length <= 32) return value;
    return '${value.substring(0, 14)}...${value.substring(value.length - 14)}';
  }
}
