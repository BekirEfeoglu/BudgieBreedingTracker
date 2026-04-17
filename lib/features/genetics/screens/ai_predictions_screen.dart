import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_mutation_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_sex_estimation_tab.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_settings_sheet.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/ai/ai_welcome_screen.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

class AiPredictionsScreen extends ConsumerStatefulWidget {
  const AiPredictionsScreen({
    super.key,
    this.initialTab = 0,
    this.initialBirdId,
  });

  final int initialTab;
  final String? initialBirdId;

  @override
  ConsumerState<AiPredictionsScreen> createState() =>
      _AiPredictionsScreenState();
}

class _AiPredictionsScreenState extends ConsumerState<AiPredictionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openSettings() {
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

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(localAiConfigProvider);
    final config = configAsync.asData?.value;
    // Show welcome if not ready: openRouter needs an API key, ollama needs a
    // non-empty model.
    final isConfigured = config != null &&
        config.model.trim().isNotEmpty &&
        (!config.isOpenRouter || config.apiKey.trim().isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: Text('more.ai_predictions'.tr()),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(LucideIcons.settings2, size: 20),
            tooltip: 'genetics.local_ai_model_settings'.tr(),
          ),
        ],
        bottom: isConfigured
            ? TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'genetics.ai_tab_mutation'.tr()),
                  Tab(text: 'genetics.ai_tab_sex'.tr()),
                ],
              )
            : null,
      ),
      body: configAsync.isLoading
          ? const LoadingState()
          : isConfigured
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    const AiMutationTab(),
                    const AiSexEstimationTab(),
                  ],
                )
              : AiWelcomeScreen(onSetup: _openSettings),
    );
  }
}
