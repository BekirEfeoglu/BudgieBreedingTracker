import 'package:easy_localization/easy_localization.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';

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
  all,
  gettingStarted,
  birdManagement,
  breedingProcess,
  tools,
  dataManagement,
  accountSettings;

  String get labelKey => switch (this) {
    GuideCategory.all => 'user_guide.category_all',
    GuideCategory.gettingStarted => 'user_guide.category_getting_started',
    GuideCategory.birdManagement => 'user_guide.category_bird_management',
    GuideCategory.breedingProcess => 'user_guide.category_breeding_process',
    GuideCategory.tools => 'user_guide.category_tools',
    GuideCategory.dataManagement => 'user_guide.category_data_management',
    GuideCategory.accountSettings => 'user_guide.category_account_settings',
  };

  String get iconAsset => switch (this) {
    GuideCategory.all => AppIcons.guide,
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
  final String iconAsset;
  final GuideCategory category;
  final List<GuideBlock> blocks;
  final bool isPremium;

  const GuideTopic({
    required this.titleKey,
    required this.iconAsset,
    required this.category,
    required this.blocks,
    this.isPremium = false,
  });

  String get title => titleKey.tr();
}

// ---------------------------------------------------------------------------
// 15 guide topics
// ---------------------------------------------------------------------------

const guideTopics = <GuideTopic>[
  // ── 1. Kayit ve Giris ──
  GuideTopic(
    titleKey: 'user_guide.topics.registration.title',
    iconAsset: AppIcons.profile,
    category: GuideCategory.gettingStarted,
    blocks: [
      GuideBlock.text('user_guide.topics.registration.intro'),
      GuideBlock.steps(
        stepsTitle: 'user_guide.topics.registration.steps_title',
        stepKeys: [
          'user_guide.topics.registration.step1',
          'user_guide.topics.registration.step2',
          'user_guide.topics.registration.step3',
          'user_guide.topics.registration.step4',
        ],
      ),
      GuideBlock.tip('user_guide.topics.registration.tip_password'),
      GuideBlock.tip('user_guide.topics.registration.tip_2fa'),
    ],
  ),

  // ── 2. Dashboard Tanitimi ──
  GuideTopic(
    titleKey: 'user_guide.topics.dashboard.title',
    iconAsset: AppIcons.home,
    category: GuideCategory.gettingStarted,
    blocks: [
      GuideBlock.text('user_guide.topics.dashboard.intro'),
      GuideBlock.text('user_guide.topics.dashboard.stats_info'),
      GuideBlock.text('user_guide.topics.dashboard.quick_actions'),
      GuideBlock.tip('user_guide.topics.dashboard.tip_refresh'),
    ],
  ),

  // ── 3. Navigasyon ──
  GuideTopic(
    titleKey: 'user_guide.topics.navigation.title',
    iconAsset: AppIcons.more,
    category: GuideCategory.gettingStarted,
    blocks: [
      GuideBlock.text('user_guide.topics.navigation.intro'),
      GuideBlock.text('user_guide.topics.navigation.bottom_nav'),
      GuideBlock.text('user_guide.topics.navigation.more_menu'),
      GuideBlock.tip('user_guide.topics.navigation.tip_back'),
    ],
  ),

  // ── 4. Kus Ekleme ve Duzenleme ──
  GuideTopic(
    titleKey: 'user_guide.topics.bird_management.title',
    iconAsset: AppIcons.bird,
    category: GuideCategory.birdManagement,
    blocks: [
      GuideBlock.text('user_guide.topics.bird_management.intro'),
      GuideBlock.steps(
        stepsTitle: 'user_guide.topics.bird_management.add_steps_title',
        stepKeys: [
          'user_guide.topics.bird_management.add_step1',
          'user_guide.topics.bird_management.add_step2',
          'user_guide.topics.bird_management.add_step3',
          'user_guide.topics.bird_management.add_step4',
        ],
      ),
      GuideBlock.tip('user_guide.topics.bird_management.tip_ring'),
      GuideBlock.warning('user_guide.topics.bird_management.warning_delete'),
    ],
  ),

  // ── 5. Filtreleme ve Arama ──
  GuideTopic(
    titleKey: 'user_guide.topics.filtering.title',
    iconAsset: AppIcons.filter,
    category: GuideCategory.birdManagement,
    blocks: [
      GuideBlock.text('user_guide.topics.filtering.intro'),
      GuideBlock.text('user_guide.topics.filtering.filter_types'),
      GuideBlock.text('user_guide.topics.filtering.search_info'),
      GuideBlock.tip('user_guide.topics.filtering.tip_combine'),
    ],
  ),

  // ── 6. Saglik Kayitlari ──
  GuideTopic(
    titleKey: 'user_guide.topics.health_records.title',
    iconAsset: AppIcons.health,
    category: GuideCategory.birdManagement,
    blocks: [
      GuideBlock.text('user_guide.topics.health_records.intro'),
      GuideBlock.steps(
        stepsTitle: 'user_guide.topics.health_records.add_steps_title',
        stepKeys: [
          'user_guide.topics.health_records.add_step1',
          'user_guide.topics.health_records.add_step2',
          'user_guide.topics.health_records.add_step3',
        ],
      ),
      GuideBlock.warning('user_guide.topics.health_records.warning_vet'),
    ],
  ),

  // ── 7. Cift Olusturma ──
  GuideTopic(
    titleKey: 'user_guide.topics.breeding_pair.title',
    iconAsset: AppIcons.pair,
    category: GuideCategory.breedingProcess,
    blocks: [
      GuideBlock.text('user_guide.topics.breeding_pair.intro'),
      GuideBlock.steps(
        stepsTitle: 'user_guide.topics.breeding_pair.steps_title',
        stepKeys: [
          'user_guide.topics.breeding_pair.step1',
          'user_guide.topics.breeding_pair.step2',
          'user_guide.topics.breeding_pair.step3',
          'user_guide.topics.breeding_pair.step4',
        ],
      ),
      GuideBlock.warning('user_guide.topics.breeding_pair.warning_inbreeding'),
      GuideBlock.tip('user_guide.topics.breeding_pair.tip_nest'),
    ],
  ),

  // ── 8. Yumurta ve Kulucka ──
  GuideTopic(
    titleKey: 'user_guide.topics.eggs_incubation.title',
    iconAsset: AppIcons.egg,
    category: GuideCategory.breedingProcess,
    blocks: [
      GuideBlock.text('user_guide.topics.eggs_incubation.intro'),
      GuideBlock.steps(
        stepsTitle: 'user_guide.topics.eggs_incubation.steps_title',
        stepKeys: [
          'user_guide.topics.eggs_incubation.step1',
          'user_guide.topics.eggs_incubation.step2',
          'user_guide.topics.eggs_incubation.step3',
          'user_guide.topics.eggs_incubation.step4',
        ],
      ),
      GuideBlock.tip('user_guide.topics.eggs_incubation.tip_candling'),
      GuideBlock.tip('user_guide.topics.eggs_incubation.tip_period'),
    ],
  ),

  // ── 9. Yavru Takibi ──
  GuideTopic(
    titleKey: 'user_guide.topics.chick_tracking.title',
    iconAsset: AppIcons.chick,
    category: GuideCategory.breedingProcess,
    blocks: [
      GuideBlock.text('user_guide.topics.chick_tracking.intro'),
      GuideBlock.steps(
        stepsTitle: 'user_guide.topics.chick_tracking.steps_title',
        stepKeys: [
          'user_guide.topics.chick_tracking.step1',
          'user_guide.topics.chick_tracking.step2',
          'user_guide.topics.chick_tracking.step3',
        ],
      ),
      GuideBlock.text('user_guide.topics.chick_tracking.promote_info'),
      GuideBlock.tip('user_guide.topics.chick_tracking.tip_weight'),
    ],
  ),

  // ── 10. Takvim ve Bildirimler ──
  GuideTopic(
    titleKey: 'user_guide.topics.calendar_notifications.title',
    iconAsset: AppIcons.calendar,
    category: GuideCategory.tools,
    blocks: [
      GuideBlock.text('user_guide.topics.calendar_notifications.intro'),
      GuideBlock.text('user_guide.topics.calendar_notifications.calendar_info'),
      GuideBlock.text(
        'user_guide.topics.calendar_notifications.notification_info',
      ),
      GuideBlock.tip('user_guide.topics.calendar_notifications.tip_reminder'),
    ],
  ),

  // ── 11. Soy Agaci ve Genetik ──
  GuideTopic(
    titleKey: 'user_guide.topics.genealogy_genetics.title',
    iconAsset: AppIcons.dna,
    category: GuideCategory.tools,
    isPremium: true,
    blocks: [
      GuideBlock.text('user_guide.topics.genealogy_genetics.intro'),
      GuideBlock.text('user_guide.topics.genealogy_genetics.family_tree'),
      GuideBlock.text('user_guide.topics.genealogy_genetics.punnett_info'),
      GuideBlock.premiumNote(
        'user_guide.topics.genealogy_genetics.premium_note',
      ),
      GuideBlock.warning(
        'user_guide.topics.genealogy_genetics.warning_inbreeding',
      ),
    ],
  ),

  // ── 12. Yedekleme ve Disari Aktarma ──
  GuideTopic(
    titleKey: 'user_guide.topics.backup_export.title',
    iconAsset: AppIcons.backup,
    category: GuideCategory.dataManagement,
    blocks: [
      GuideBlock.text('user_guide.topics.backup_export.intro'),
      GuideBlock.steps(
        stepsTitle: 'user_guide.topics.backup_export.backup_steps_title',
        stepKeys: [
          'user_guide.topics.backup_export.backup_step1',
          'user_guide.topics.backup_export.backup_step2',
          'user_guide.topics.backup_export.backup_step3',
        ],
      ),
      GuideBlock.text('user_guide.topics.backup_export.export_info'),
      GuideBlock.warning('user_guide.topics.backup_export.warning_restore'),
    ],
  ),

  // ── 13. Senkronizasyon ──
  GuideTopic(
    titleKey: 'user_guide.topics.sync.title',
    iconAsset: AppIcons.sync,
    category: GuideCategory.dataManagement,
    blocks: [
      GuideBlock.text('user_guide.topics.sync.intro'),
      GuideBlock.text('user_guide.topics.sync.offline_info'),
      GuideBlock.text('user_guide.topics.sync.conflict_info'),
      GuideBlock.tip('user_guide.topics.sync.tip_connection'),
      GuideBlock.warning('user_guide.topics.sync.warning_data_loss'),
    ],
  ),

  // ── 14. Profil ve Ayarlar ──
  GuideTopic(
    titleKey: 'user_guide.topics.profile_settings.title',
    iconAsset: AppIcons.settings,
    category: GuideCategory.accountSettings,
    blocks: [
      GuideBlock.text('user_guide.topics.profile_settings.intro'),
      GuideBlock.text('user_guide.topics.profile_settings.profile_info'),
      GuideBlock.text('user_guide.topics.profile_settings.settings_info'),
      GuideBlock.tip('user_guide.topics.profile_settings.tip_language'),
    ],
  ),

  // ── 15. Premium Uyelik ──
  GuideTopic(
    titleKey: 'user_guide.topics.premium.title',
    iconAsset: AppIcons.premium,
    category: GuideCategory.accountSettings,
    blocks: [
      GuideBlock.text('user_guide.topics.premium.intro'),
      GuideBlock.text('user_guide.topics.premium.features_list'),
      GuideBlock.steps(
        stepsTitle: 'user_guide.topics.premium.subscribe_steps_title',
        stepKeys: [
          'user_guide.topics.premium.subscribe_step1',
          'user_guide.topics.premium.subscribe_step2',
          'user_guide.topics.premium.subscribe_step3',
        ],
      ),
      GuideBlock.premiumNote('user_guide.topics.premium.premium_note'),
    ],
  ),
];
