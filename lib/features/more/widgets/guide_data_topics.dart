part of 'guide_data.dart';

/// Guide topics for tools, data management, and account settings categories.
const _guideTopicsToolsAndMore = <GuideTopic>[
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
