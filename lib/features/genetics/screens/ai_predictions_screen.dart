import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_genetics_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_mutation_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_sex_estimation_card.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_settings_sheet.dart';

/// Standalone screen for AI predictions, accessible from the More menu.
class AiPredictionsScreen extends ConsumerWidget {
  const AiPredictionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('more.ai_predictions'.tr()),
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
          AiGeneticsCard(
            fatherGenotype:
                const ParentGenotype.empty(gender: BirdGender.male),
            motherGenotype:
                const ParentGenotype.empty(gender: BirdGender.female),
            selectedFatherName: null,
            selectedMotherName: null,
            calculatorResults: const [],
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
