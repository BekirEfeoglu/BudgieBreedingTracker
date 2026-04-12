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

class AiSexEstimationCard extends ConsumerStatefulWidget {
  const AiSexEstimationCard({super.key});

  @override
  ConsumerState<AiSexEstimationCard> createState() =>
      _AiSexEstimationCardState();
}

class _AiSexEstimationCardState
    extends ConsumerState<AiSexEstimationCard> {
  late final TextEditingController _observationsController;
  String? _selectedSexImagePath;
  bool _showObservationError = false;

  @override
  void initState() {
    super.initState();
    _observationsController = TextEditingController();
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sexAsync = ref.watch(sexAiAnalysisProvider);

    return AiSectionCard(
      title: 'genetics.sex_ai_title'.tr(),
      icon: LucideIcons.search,
      subtitle: 'genetics.sex_ai_subtitle'.tr(),
      infoText: 'genetics.sex_ai_info'.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _observationsController,
            maxLines: 4,
            onChanged: (value) {
              ref.read(sexAiAnalysisProvider.notifier).clear();
              if (_showObservationError && value.trim().isNotEmpty) {
                setState(() => _showObservationError = false);
              }
            },
            decoration: InputDecoration(
              labelText: 'genetics.sex_observations'.tr(),
              hintText: 'genetics.sex_observations_hint'.tr(),
              alignLabelWithHint: true,
            ),
          ),
          if (_showObservationError) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'genetics.sex_observations_required'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
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
                  setState(() => _selectedSexImagePath = path);
                  ref.read(sexAiAnalysisProvider.notifier).clear();
                },
                icon: const Icon(LucideIcons.camera, size: 18),
                label: Text('genetics.sex_select_cere_photo'.tr()),
              ),
              if (_selectedSexImagePath != null)
                ActionChip(
                  onPressed: () {
                    setState(() => _selectedSexImagePath = null);
                    ref.read(sexAiAnalysisProvider.notifier).clear();
                  },
                  avatar: const Icon(LucideIcons.x, size: 16),
                  label: Text('common.clear'.tr()),
                ),
            ],
          ),
          if (_selectedSexImagePath != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppSpacing.radiusMd),
              child: Image.file(
                File(_selectedSexImagePath!),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 80,
                  color: theme.colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Text('common.error'.tr()),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.xs),
            _buildHintStrip(theme),
          ],
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: sexAsync.isLoading
                  ? null
                  : () async {
                      final observations =
                          _observationsController.text.trim();
                      if (observations.isEmpty) {
                        setState(
                          () => _showObservationError = true,
                        );
                        return;
                      }
                      if (_showObservationError) {
                        setState(
                          () => _showObservationError = false,
                        );
                      }
                      final config = ref
                          .read(localAiConfigProvider)
                          .asData
                          ?.value;
                      if (config == null) return;
                      await ref
                          .read(sexAiAnalysisProvider.notifier)
                          .analyze(
                            config: config,
                            observations: observations,
                            imagePath: _selectedSexImagePath,
                          );
                    },
              icon: sexAsync.isLoading
                  ? const AiButtonSpinner()
                  : const Icon(LucideIcons.search, size: 18),
              label: Text('genetics.run_sex_ai'.tr()),
            ),
          ),
          AiAnimatedResultSlot(
            isLoading: sexAsync.isLoading,
            hasError: sexAsync.hasError,
            errorMessage: sexAsync.hasError
                ? formatAiError(sexAsync.error)
                : null,
            child: sexAsync.asData?.value != null
                ? _buildResult(sexAsync.asData!.value!)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildResult(LocalAiSexInsight result) {
    return AiResultSection(
      title: 'genetics.sex_ai_result'.tr(
        args: [_localizedSex(result.predictedSex)],
      ),
      confidence: result.confidence,
      summary: result.rationale,
      bullets: [...result.indicators, ...result.nextChecks],
    );
  }

  static String _localizedSex(LocalAiSexPrediction sex) => switch (sex) {
        LocalAiSexPrediction.male => 'birds.male'.tr(),
        LocalAiSexPrediction.female => 'birds.female'.tr(),
        LocalAiSexPrediction.uncertain =>
          'genetics.sex_uncertain'.tr(),
      };

  Widget _buildHintStrip(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color:
              theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.camera,
            size: 14,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'genetics.sex_photo_hint'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
