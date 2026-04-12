import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/utils/phenotype_localizer.dart';

class LocalAiInsightsCard extends ConsumerStatefulWidget {
  const LocalAiInsightsCard({
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

  @override
  ConsumerState<LocalAiInsightsCard> createState() =>
      _LocalAiInsightsCardState();
}

class _LocalAiInsightsCardState extends ConsumerState<LocalAiInsightsCard> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _modelController;
  late final TextEditingController _observationsController;
  String? _selectedImagePath;
  bool _showSexObservationError = false;
  bool _isTestingConnection = false;
  String? _lastFetchedModelBaseUrl;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController();
    _modelController = TextEditingController();
    _observationsController = TextEditingController();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  Future<LocalAiConfig?> _persistConfig() async {
    final notifier = ref.read(localAiConfigProvider.notifier);
    await notifier.save(
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
    );
    return ref.read(localAiConfigProvider).asData?.value;
  }

  Future<void> _fetchModels({
    required String baseUrl,
    required String model,
    bool force = false,
  }) async {
    await ref
        .read(localAiModelListProvider.notifier)
        .fetch(baseUrl: baseUrl, selectedModel: model, force: force);
    _lastFetchedModelBaseUrl = LocalAiConfig(
      baseUrl: baseUrl,
      model: model,
    ).normalizedBaseUrl;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _testConnection() async {
    if (_isTestingConnection) return;

    setState(() => _isTestingConnection = true);
    try {
      final config = await _persistConfig();
      if (config == null) return;
      await ref.read(localAiServiceProvider).testConnection(config: config);
      await _fetchModels(
        baseUrl: config.baseUrl,
        model: config.model,
        force: true,
      );
      _showMessage('genetics.local_ai_connection_ok'.tr());
    } catch (error) {
      _showMessage(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(localAiConfigProvider);
    final geneticsAsync = ref.watch(geneticsAiAnalysisProvider);
    final sexAsync = ref.watch(sexAiAnalysisProvider);
    final mutationAsync = ref.watch(mutationImageAiAnalysisProvider);
    final modelsAsync = ref.watch(localAiModelListProvider);
    final hasPairSelection =
        widget.fatherGenotype.isNotEmpty || widget.motherGenotype.isNotEmpty;
    final hasCompletePair =
        widget.fatherGenotype.isNotEmpty && widget.motherGenotype.isNotEmpty;

    ref.listen<AsyncValue<LocalAiConfig>>(localAiConfigProvider, (_, next) {
      final config = next.asData?.value;
      if (config == null) return;
      if (_baseUrlController.text != config.baseUrl) {
        _baseUrlController.text = config.baseUrl;
      }
      if (_modelController.text != config.model) {
        _modelController.text = config.model;
      }
      if (_lastFetchedModelBaseUrl != config.normalizedBaseUrl) {
        _fetchModels(baseUrl: config.baseUrl, model: config.model);
      }
    });

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'genetics.local_ai_title'.tr(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Text(
                  'genetics.local_ai_desc'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'genetics.local_ai_model_settings'.tr(),
                icon: LucideIcons.settings2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _baseUrlController,
                      decoration: InputDecoration(
                        labelText: 'genetics.local_ai_url'.tr(),
                        hintText: LocalAiConfig.defaults.baseUrl,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (modelsAsync.asData?.value case final models?
                        when models.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: models.contains(_modelController.text)
                            ? _modelController.text
                            : null,
                        decoration: InputDecoration(
                          labelText: 'genetics.local_ai_model_select'.tr(),
                        ),
                        items: models
                            .map(
                              (model) => DropdownMenuItem<String>(
                                value: model,
                                child: Text(
                                  model,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          _modelController.text = value;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    TextField(
                      controller: _modelController,
                      decoration: InputDecoration(
                        labelText: 'genetics.local_ai_model'.tr(),
                        hintText: LocalAiConfig.defaults.model,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _HintStrip(
                      text: 'genetics.local_ai_hint'.tr(),
                      icon: LucideIcons.info,
                    ),
                    if (modelsAsync.isLoading) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const LinearProgressIndicator(minHeight: 2),
                    ] else if (modelsAsync.hasError) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _errorMessage(modelsAsync.error),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ] else if ((modelsAsync.asData?.value ?? const [])
                        .isEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'genetics.local_ai_models_empty'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                configAsync.isLoading || _isTestingConnection
                                ? null
                                : () async {
                                    await _persistConfig();
                                    if (!context.mounted) return;
                                    _showMessage(
                                      'common.saved_successfully'.tr(),
                                    );
                                  },
                            icon: const Icon(LucideIcons.save, size: 18),
                            label: Text('genetics.save_ai_config'.tr()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: configAsync.isLoading || _isTestingConnection
                            ? null
                            : _testConnection,
                        icon: _isTestingConnection
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.wifi, size: 18),
                        label: Text('genetics.test_local_ai_connection'.tr()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            configAsync.isLoading || modelsAsync.isLoading
                            ? null
                            : () async {
                                final config = await _persistConfig();
                                if (config == null) return;
                                try {
                                  await _fetchModels(
                                    baseUrl: config.baseUrl,
                                    model: config.model,
                                    force: true,
                                  );
                                } catch (error) {
                                  _showMessage(_errorMessage(error));
                                }
                              },
                        icon: const Icon(LucideIcons.refreshCw, size: 18),
                        label: Text('genetics.refresh_local_ai_models'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'genetics.local_ai_genetics_comment'.tr(),
                icon: LucideIcons.dna,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: configAsync.isLoading || !hasPairSelection
                            ? null
                            : () async {
                                final config = await _persistConfig();
                                if (config == null || !context.mounted) return;
                                await ref
                                    .read(geneticsAiAnalysisProvider.notifier)
                                    .analyze(
                                      config: config,
                                      father: widget.fatherGenotype,
                                      mother: widget.motherGenotype,
                                      fatherName: widget.selectedFatherName,
                                      motherName: widget.selectedMotherName,
                                      calculatorResults:
                                          widget.calculatorResults ?? const [],
                                    );
                              },
                        icon: const Icon(LucideIcons.sparkles, size: 18),
                        label: Text('genetics.run_genetics_ai'.tr()),
                      ),
                    ),
                    if (!hasPairSelection) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'genetics.local_ai_pair_required'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (geneticsAsync.hasError) ...[
                const SizedBox(height: AppSpacing.lg),
                _ErrorBox(message: _errorMessage(geneticsAsync.error)),
              ] else if (geneticsAsync.asData?.value case final result?) ...[
                const SizedBox(height: AppSpacing.lg),
                _InsightSection(
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
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              _SectionCard(
                title: 'genetics.image_ai_title'.tr(),
                icon: LucideIcons.image,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'genetics.image_ai_desc'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
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
                            ref
                                .read(mutationImageAiAnalysisProvider.notifier)
                                .clear();
                            setState(() => _selectedImagePath = path);
                          },
                          icon: const Icon(LucideIcons.imagePlus, size: 18),
                          label: Text('genetics.select_image'.tr()),
                        ),
                        FilledButton.icon(
                          onPressed:
                              configAsync.isLoading ||
                                  _selectedImagePath == null
                              ? null
                              : () async {
                                  final config = await _persistConfig();
                                  if (config == null ||
                                      _selectedImagePath == null) {
                                    return;
                                  }
                                  await ref
                                      .read(
                                        mutationImageAiAnalysisProvider
                                            .notifier,
                                      )
                                      .analyze(
                                        config: config,
                                        imagePath: _selectedImagePath!,
                                      );
                                },
                          icon: const Icon(LucideIcons.scanLine, size: 18),
                          label: Text('genetics.run_image_ai'.tr()),
                        ),
                      ],
                    ),
                    if (_selectedImagePath != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLg,
                          ),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                              child: Image.file(
                                File(_selectedImagePath!),
                                height: 156,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  height: 120,
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
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
                                        .read(
                                          mutationImageAiAnalysisProvider
                                              .notifier,
                                        )
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
                      ),
                    ],
                  ],
                ),
              ),
              if (!hasCompletePair) ...[
                const SizedBox(height: AppSpacing.md),
                _HintStrip(
                  text: 'genetics.complete_pair_required'.tr(),
                  icon: LucideIcons.info,
                ),
              ],
              if (mutationAsync.hasError) ...[
                const SizedBox(height: AppSpacing.lg),
                _ErrorBox(message: _errorMessage(mutationAsync.error)),
              ] else if (mutationAsync.asData?.value case final result?) ...[
                const SizedBox(height: AppSpacing.lg),
                _InsightSection(
                  title: 'genetics.image_ai_result'.tr(
                    args: [_mutationLabel(result.predictedMutation)],
                  ),
                  confidence: result.confidence,
                  summary: result.rationale,
                  bullets: [
                    'genetics.local_ai_series_label'.tr(args: [_seriesLabel(result.baseSeries)]),
                    'genetics.local_ai_pattern_label'.tr(args: [_patternLabel(result.patternFamily)]),
                    '${'genetics.image_body_color'.tr()}: ${result.bodyColor}',
                    '${'genetics.image_wing_pattern'.tr()}: ${result.wingPattern}',
                    '${'genetics.image_eye_color'.tr()}: ${result.eyeColor}',
                    if (result.secondaryPossibilities.isNotEmpty)
                      'genetics.local_ai_alternatives_label'.tr(args: [result.secondaryPossibilities.map(_mutationLabel).join(', ')]),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              _SectionCard(
                title: 'genetics.sex_ai_title'.tr(),
                icon: LucideIcons.search,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _observationsController,
                      maxLines: 4,
                      onChanged: (value) {
                        ref.read(sexAiAnalysisProvider.notifier).clear();
                        if (_showSexObservationError &&
                            value.trim().isNotEmpty) {
                          setState(() => _showSexObservationError = false);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'genetics.sex_observations'.tr(),
                        hintText: 'genetics.sex_observations_hint'.tr(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (_showSexObservationError) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'genetics.sex_observations_required'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: sexAsync.isLoading
                            ? null
                            : () async {
                                final observations = _observationsController
                                    .text
                                    .trim();
                                if (observations.isEmpty) {
                                  setState(
                                    () => _showSexObservationError = true,
                                  );
                                  return;
                                }
                                if (_showSexObservationError) {
                                  setState(
                                    () => _showSexObservationError = false,
                                  );
                                }
                                final config = await _persistConfig();
                                if (config == null) return;
                                await ref
                                    .read(sexAiAnalysisProvider.notifier)
                                    .analyze(
                                      config: config,
                                      observations: observations,
                                    );
                              },
                        icon: const Icon(LucideIcons.search, size: 18),
                        label: Text('genetics.run_sex_ai'.tr()),
                      ),
                    ),
                  ],
                ),
              ),
              if (sexAsync.hasError) ...[
                const SizedBox(height: AppSpacing.lg),
                _ErrorBox(message: _errorMessage(sexAsync.error)),
              ] else if (sexAsync.asData?.value case final result?) ...[
                const SizedBox(height: AppSpacing.lg),
                _InsightSection(
                  title: 'genetics.sex_ai_result'.tr(
                    args: [_localizedSex(result.predictedSex)],
                  ),
                  confidence: result.confidence,
                  summary: result.rationale,
                  bullets: [...result.indicators, ...result.nextChecks],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _localizedSex(LocalAiSexPrediction sex) => switch (sex) {
    LocalAiSexPrediction.male => 'birds.male'.tr(),
    LocalAiSexPrediction.female => 'birds.female'.tr(),
    LocalAiSexPrediction.uncertain => 'genetics.sex_uncertain'.tr(),
  };

  String _mutationLabel(String key) => switch (key) {
    'normal_light_green' => 'genetics.mutation_normal_light_green'.tr(),
    'normal_dark_green' => 'genetics.mutation_normal_dark_green'.tr(),
    'normal_olive' => 'genetics.mutation_normal_olive'.tr(),
    'spangle_green' => 'genetics.mutation_spangle_green'.tr(),
    'cinnamon_green' => 'genetics.mutation_cinnamon_green'.tr(),
    'opaline_green' => 'genetics.mutation_opaline_green'.tr(),
    'dominant_pied_green' => 'genetics.mutation_dominant_pied_green'.tr(),
    'recessive_pied_green' => 'genetics.mutation_recessive_pied_green'.tr(),
    'clearwing_green' => 'genetics.mutation_clearwing_green'.tr(),
    'greywing_green' => 'genetics.mutation_greywing_green'.tr(),
    'dilute_green' => 'genetics.mutation_dilute_green'.tr(),
    'clearbody_green' => 'genetics.mutation_clearbody_green'.tr(),
    'lutino' => 'genetics.mutation_lutino'.tr(),
    'yellowface_blue' => 'genetics.mutation_yellowface_blue'.tr(),
    'violet_green' => 'genetics.mutation_violet_green'.tr(),
    _ => 'common.unknown'.tr(),
  };

  String _seriesLabel(String key) => switch (key) {
    'green' => 'genetics.series_green'.tr(),
    'blue' => 'genetics.series_blue'.tr(),
    'lutino' => 'genetics.series_lutino'.tr(),
    _ => 'genetics.series_unknown'.tr(),
  };

  String _patternLabel(String key) => switch (key) {
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

  String _errorMessage(Object? error) {
    if (error is AppException) return error.message;
    return error?.toString() ?? 'common.error'.tr();
  }

  String _localizedGeneticId(String id) {
    final record = MutationDatabase.getById(id);
    if (record == null) {
      return PhenotypeLocalizer.localizeMutation(id);
    }
    return record.localizationKey.tr();
  }

  String _shortFileName(String value) {
    if (value.length <= 32) return value;
    return '${value.substring(0, 14)}...${value.substring(value.length - 14)}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.28,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _HintStrip extends StatelessWidget {
  const _HintStrip({required this.text, required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
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

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.title,
    required this.confidence,
    required this.summary,
    required this.bullets,
  });

  final String title;
  final LocalAiConfidence confidence;
  final String summary;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredBullets = bullets
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final badgeColors = _confidenceColors(context, confidence);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: badgeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: badgeColors.background,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: badgeColors.border),
                ),
                child: Text(
                  _confidenceLabel(confidence),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: badgeColors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (summary.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(summary),
          ],
          if (filteredBullets.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...filteredBullets.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _confidenceLabel(LocalAiConfidence confidence) => switch (confidence) {
    LocalAiConfidence.low => 'genetics.ai_confidence_low'.tr(),
    LocalAiConfidence.medium => 'genetics.ai_confidence_medium'.tr(),
    LocalAiConfidence.high => 'genetics.ai_confidence_high'.tr(),
    LocalAiConfidence.unknown => 'common.unknown'.tr(),
  };

  ({Color background, Color foreground, Color border}) _confidenceColors(
    BuildContext context,
    LocalAiConfidence confidence,
  ) {
    final theme = Theme.of(context);
    return switch (confidence) {
      LocalAiConfidence.low => (
        background: theme.colorScheme.errorContainer.withValues(alpha: 0.65),
        foreground: theme.colorScheme.onErrorContainer,
        border: theme.colorScheme.error.withValues(alpha: 0.45),
      ),
      LocalAiConfidence.medium => (
        background: const Color(0xFFFDE7C7),
        foreground: const Color(0xFF9A5B00),
        border: const Color(0xFFF3B454),
      ),
      LocalAiConfidence.high => (
        background: const Color(0xFFDDF6E8),
        foreground: const Color(0xFF166534),
        border: const Color(0xFF6CCB8B),
      ),
      LocalAiConfidence.unknown => (
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
        border: theme.colorScheme.outlineVariant,
      ),
    };
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}
