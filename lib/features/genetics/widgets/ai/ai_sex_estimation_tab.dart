import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_helpers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_image_picker_zone.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_progress_phases.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_quick_tags.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_result_section.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_section_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_picker_dialog.dart';

class AiSexEstimationTab extends ConsumerStatefulWidget {
  const AiSexEstimationTab({super.key});

  @override
  ConsumerState<AiSexEstimationTab> createState() =>
      _AiSexEstimationTabState();
}

class _AiSexEstimationTabState extends ConsumerState<AiSexEstimationTab>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _observationsController;
  String? _selectedSexImagePath;
  bool _showObservationError = false;
  final Set<String> _selectedTags = {};
  Bird? _selectedBird;

  @override
  bool get wantKeepAlive => true;

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

  Future<void> _selectBird() async {
    final bird = await showBirdPickerDialog(
      context,
      genderFilter: BirdGender.unknown,
    );
    if (bird == null || !mounted) return;
    setState(() => _selectedBird = bird);
  }

  void _clearBird() {
    setState(() => _selectedBird = null);
  }

  void _onTagToggled(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    ref.read(sexAiAnalysisProvider.notifier).clear();
  }

  String _buildFullObservations() {
    final base = _observationsController.text.trim();
    final parts = <String>[base];

    if (_selectedTags.isNotEmpty) {
      final tagLabels = _selectedTags.map((t) => t.tr()).join(', ');
      parts.add('[${'genetics.ai_tags_label'.tr()}: $tagLabels]');
    }

    if (_selectedBird != null) {
      final bird = _selectedBird!;
      final info = <String>[];
      if (bird.mutations != null && bird.mutations!.isNotEmpty) {
        info.add(bird.mutations!.join(', '));
      }
      if (bird.birthDate != null) {
        final age = DateTime.now().difference(bird.birthDate!).inDays;
        info.add('${'birds.age'.tr()}: $age ${'common.days'.tr()}');
      }
      if (info.isNotEmpty) {
        parts.add('[${'genetics.ai_bird_info_label'.tr()}: ${info.join(', ')}]');
      }
    }

    return parts.where((p) => p.isNotEmpty).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final configAsync = ref.watch(localAiConfigProvider);
    final sexAsync = ref.watch(sexAiAnalysisProvider);
    final phase = ref.watch(sexAiPhaseProvider);

    final isLoading = sexAsync is AsyncLoading;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: AiSectionCard(
        title: 'genetics.sex_ai_title'.tr(),
        icon: LucideIcons.search,
        subtitle: 'genetics.sex_ai_subtitle'.tr(),
        infoText: 'genetics.sex_ai_info'.tr(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Optional bird selector
            _buildBirdSelector(theme),
            const SizedBox(height: AppSpacing.md),
            // Quick tags
            AiQuickTags(
              selectedTags: _selectedTags,
              onTagToggled: _onTagToggled,
            ),
            const SizedBox(height: AppSpacing.md),
            // Observations field
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
            // Image picker zone for cere photo
            AiImagePickerZone(
              selectedImagePath: _selectedSexImagePath,
              onImageSelected: (path) {
                setState(() => _selectedSexImagePath = path);
                ref.read(sexAiAnalysisProvider.notifier).clear();
              },
              onImageCleared: () {
                setState(() => _selectedSexImagePath = null);
                ref.read(sexAiAnalysisProvider.notifier).clear();
              },
              tips: ['genetics.ai_sex_photo_tip'.tr()],
              previewHeight: 120,
            ),
            const SizedBox(height: AppSpacing.md),
            // Analyze button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: configAsync.isLoading || isLoading
                    ? null
                    : () async {
                        final observations =
                            _observationsController.text.trim();
                        if (observations.isEmpty && _selectedTags.isEmpty) {
                          setState(() => _showObservationError = true);
                          return;
                        }
                        if (_showObservationError) {
                          setState(() => _showObservationError = false);
                        }
                        final config = ref
                            .read(localAiConfigProvider)
                            .asData
                            ?.value;
                        if (config == null) return;
                        final fullObservations = _buildFullObservations();
                        await ref
                            .read(sexAiAnalysisProvider.notifier)
                            .analyze(
                              config: config,
                              observations: fullObservations,
                              imagePath: _selectedSexImagePath,
                            );
                      },
                icon: isLoading
                    ? const AiButtonSpinner()
                    : const Icon(LucideIcons.search, size: 18),
                label: Text('genetics.run_sex_ai'.tr()),
              ),
            ),
            AiProgressPhases(phase: phase),
            AiAnimatedResultSlot(
              isLoading: isLoading,
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
      ),
    );
  }

  Widget _buildBirdSelector(ThemeData theme) {
    return InkWell(
      onTap: _selectBird,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.bird,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _selectedBird != null
                  ? Text(
                      _selectedBird!.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      'genetics.ai_select_bird_optional'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
            if (_selectedBird != null)
              GestureDetector(
                onTap: _clearBird,
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
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
}
