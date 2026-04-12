import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_models.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_genetics_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_mutation_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_sex_estimation_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_settings_sheet.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Standalone screen for AI predictions, accessible from the More menu.
class AiPredictionsScreen extends ConsumerWidget {
  const AiPredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(localAiConfigProvider);
    final fatherGenotype = ref.watch(fatherGenotypeProvider);
    final motherGenotype = ref.watch(motherGenotypeProvider);
    final selectedFatherName = ref.watch(selectedFatherBirdNameProvider);
    final selectedMotherName = ref.watch(selectedMotherBirdNameProvider);
    final calculatorResults = ref.watch(offspringResultsProvider);
    final hasCompletePair =
        fatherGenotype.isNotEmpty && motherGenotype.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'more.ai_predictions'.tr(),
          iconAsset: AppIcons.dna,
        ),
        actions: [
          IconButton(
            onPressed: () => _openSettings(context),
            icon: const Icon(LucideIcons.settings2, size: 20),
            tooltip: 'genetics.local_ai_model_settings'.tr(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ).copyWith(bottom: AppSpacing.xxxl * 2),
        children: [
          _AiOverviewCard(
            configAsync: configAsync,
            hasCompletePair: hasCompletePair,
            selectedFatherName: selectedFatherName,
            selectedMotherName: selectedMotherName,
            onOpenSettings: () => _openSettings(context),
            onOpenGenetics: () => context.push(AppRoutes.genetics),
          ),
          const SizedBox(height: AppSpacing.md),
          AiGeneticsCard(
            fatherGenotype: hasCompletePair
                ? fatherGenotype
                : const ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype: hasCompletePair
                ? motherGenotype
                : const ParentGenotype.empty(gender: BirdGender.female),
            selectedFatherName: hasCompletePair ? selectedFatherName : null,
            selectedMotherName: hasCompletePair ? selectedMotherName : null,
            calculatorResults: hasCompletePair
                ? (calculatorResults ?? const [])
                : const [],
          ),
          const SizedBox(height: AppSpacing.md),
          const AiMutationCard(),
          const SizedBox(height: AppSpacing.md),
          const AiSexEstimationCard(),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => const AiSettingsSheet(),
    );
  }
}

class _AiOverviewCard extends StatelessWidget {
  const _AiOverviewCard({
    required this.configAsync,
    required this.hasCompletePair,
    required this.selectedFatherName,
    required this.selectedMotherName,
    required this.onOpenSettings,
    required this.onOpenGenetics,
  });

  final AsyncValue<LocalAiConfig> configAsync;
  final bool hasCompletePair;
  final String? selectedFatherName;
  final String? selectedMotherName;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenGenetics;

  String get _pairLabel {
    final father = selectedFatherName?.trim();
    final mother = selectedMotherName?.trim();
    if ((father?.isNotEmpty ?? false) && (mother?.isNotEmpty ?? false)) {
      return '$father x $mother';
    }
    return 'genetics.title'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = configAsync.asData?.value;
    final isConfigReady = config != null;
    final providerLabel = switch (config?.provider.name) {
      'ollama' => 'Ollama',
      'openRouter' => 'OpenRouter',
      _ => 'AI',
    };
    final modelLabel = config?.model.trim();
    final needsOpenRouterKey = config != null &&
        config.provider.name == 'openRouter' &&
        ((config.apiKey as String?)?.trim().isEmpty ?? true);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.75),
            theme.colorScheme.surfaceContainerHigh,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.sparkles,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'more.ai_predictions'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      hasCompletePair
                          ? _pairLabel
                          : 'genetics.local_ai_pair_required'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatusChip(
                icon: LucideIcons.brainCircuit,
                label: providerLabel,
              ),
              _StatusChip(
                icon: LucideIcons.cpu,
                label: modelLabel?.isNotEmpty == true ? modelLabel! : 'AI',
              ),
              _StatusChip(
                icon: hasCompletePair
                    ? LucideIcons.checkCircle2
                    : LucideIcons.dna,
                label: hasCompletePair
                    ? _pairLabel
                    : 'genetics.title'.tr(),
                highlighted: hasCompletePair,
              ),
            ],
          ),
          if (configAsync.isLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(minHeight: 2),
          ] else if (needsOpenRouterKey) ...[
            const SizedBox(height: AppSpacing.md),
            _InlineHint(
              icon: LucideIcons.keyRound,
              message: 'genetics.local_ai_model_settings'.tr(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(LucideIcons.settings2, size: 18),
                  label: Text('genetics.local_ai_model_settings'.tr()),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenGenetics,
                  icon: const Icon(LucideIcons.dna, size: 18),
                  label: Text('genetics.title'.tr()),
                ),
              ),
            ],
          ),
          if (!isConfigReady || !hasCompletePair) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              !isConfigReady
                  ? 'genetics.local_ai_model_settings'.tr()
                  : 'genetics.local_ai_pair_required'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: highlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineHint extends StatelessWidget {
  const _InlineHint({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
