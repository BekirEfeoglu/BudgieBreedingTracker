import 'package:easy_localization/easy_localization.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';

part 'guide_topics_data.dart';

// ---------------------------------------------------------------------------
// Guide content block types
// ---------------------------------------------------------------------------

enum GuideBlockType { text, tip, warning, steps, premiumNote }

class GuideBlock {
  final GuideBlockType type;
  final String? textKey;
  final String? stepsTitle;
  final List<String>? stepKeys;

  const GuideBlock.text(this.textKey)
    : type = GuideBlockType.text,
      stepsTitle = null,
      stepKeys = null;

  const GuideBlock.tip(this.textKey)
    : type = GuideBlockType.tip,
      stepsTitle = null,
      stepKeys = null;

  const GuideBlock.warning(this.textKey)
    : type = GuideBlockType.warning,
      stepsTitle = null,
      stepKeys = null;

  const GuideBlock.premiumNote(this.textKey)
    : type = GuideBlockType.premiumNote,
      stepsTitle = null,
      stepKeys = null;

  const GuideBlock.steps({required this.stepsTitle, required this.stepKeys})
    : type = GuideBlockType.steps,
      textKey = null;
}

// ---------------------------------------------------------------------------
// Guide categories
// ---------------------------------------------------------------------------

enum GuideCategory {
  gettingStarted,
  birdManagement,
  breedingProcess,
  tools,
  dataManagement,
  accountSettings;

  String get labelKey => switch (this) {
    GuideCategory.gettingStarted => 'user_guide.category_getting_started',
    GuideCategory.birdManagement => 'user_guide.category_bird_management',
    GuideCategory.breedingProcess => 'user_guide.category_breeding_process',
    GuideCategory.tools => 'user_guide.category_tools',
    GuideCategory.dataManagement => 'user_guide.category_data_management',
    GuideCategory.accountSettings => 'user_guide.category_account_settings',
  };

  String get iconAsset => switch (this) {
    GuideCategory.gettingStarted => AppIcons.onboarding,
    GuideCategory.birdManagement => AppIcons.bird,
    GuideCategory.breedingProcess => AppIcons.breeding,
    GuideCategory.tools => AppIcons.calendar,
    GuideCategory.dataManagement => AppIcons.backup,
    GuideCategory.accountSettings => AppIcons.settings,
  };

  String get label => labelKey.tr();
}

// ---------------------------------------------------------------------------
// Guide topic model
// ---------------------------------------------------------------------------

class GuideTopic {
  final String titleKey;
  final String subtitleKey;
  final String iconAsset;
  final GuideCategory category;
  final List<GuideBlock> blocks;
  final bool isPremium;
  final List<int> relatedTopicIndices;

  const GuideTopic({
    required this.titleKey,
    required this.subtitleKey,
    required this.iconAsset,
    required this.category,
    required this.blocks,
    this.isPremium = false,
    this.relatedTopicIndices = const [],
  });

  String get title => titleKey.tr();

  String get subtitle => subtitleKey.tr();

  int get stepCount {
    var count = 0;
    for (final block in blocks) {
      if (block.type == GuideBlockType.steps && block.stepKeys != null) {
        count += block.stepKeys!.length;
      }
    }
    return count;
  }
}
