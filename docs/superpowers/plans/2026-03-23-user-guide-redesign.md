# User Guide Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the User Guide screen from ExpansionTile cards to an iOS-Settings-style grouped list with a separate detail page and related topics.

**Architecture:** Replace inline expansion with category-grouped list items that navigate to a dedicated detail screen via `context.push`. Data model gets `subtitleKey` and `relatedTopicIndices` fields. `guide_data.dart` splits into two files to stay under 300 lines.

**Tech Stack:** Flutter, GoRouter, easy_localization, flutter_svg (AppIcon), LucideIcons

**Spec:** `docs/superpowers/specs/2026-03-23-user-guide-redesign.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/features/more/widgets/guide_data.dart` | Modify | Models + enums (GuideTopic, GuideBlock, GuideCategory) |
| `lib/features/more/widgets/guide_topics_data.dart` | Create | `part of` guide_data.dart — 15 topic definitions |
| `lib/features/more/widgets/guide_topic_list_item.dart` | Create | List item widget for topic rows |
| `lib/features/more/screens/user_guide_screen.dart` | Rewrite | Grouped list with search |
| `lib/features/more/screens/guide_detail_screen.dart` | Create | Detail page with blocks + related topics |
| `lib/features/more/widgets/guide_topic_card.dart` | Delete | Replaced by list item + detail screen |
| `lib/features/more/widgets/guide_content_widgets.dart` | Keep | No changes |
| `lib/router/route_names.dart` | Modify | Add `userGuideDetail` constant |
| `lib/router/routes/user_routes.dart` | Modify | Nest detail route under user-guide |
| `assets/translations/tr.json` | Modify | +17 keys, -1 key |
| `assets/translations/en.json` | Modify | +17 keys, -1 key |
| `assets/translations/de.json` | Modify | +17 keys, -1 key |
| `test/features/more/widgets/guide_data_test.dart` | Rewrite | Update for new model fields, no `all` |
| `test/features/more/widgets/guide_topic_card_test.dart` | Delete | Widget removed |
| `test/features/more/widgets/guide_topic_list_item_test.dart` | Create | New widget tests |
| `test/features/more/screens/user_guide_screen_test.dart` | Rewrite | Grouped list + navigation tests |
| `test/features/more/screens/user_guide_screen_localized_test.dart` | Update | Keep search tests, remove ExpansionTile tests |
| `test/features/more/screens/guide_detail_screen_test.dart` | Create | Detail page tests |

---

### Task 1: Update Data Model (guide_data.dart)

**Files:**
- Modify: `lib/features/more/widgets/guide_data.dart`
- Test: `test/features/more/widgets/guide_data_test.dart`

- [ ] **Step 1: Update GuideTopic class — add subtitleKey and relatedTopicIndices**

In `lib/features/more/widgets/guide_data.dart`, update the `GuideTopic` class:

```dart
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

  /// Total step count across all step blocks.
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
```

- [ ] **Step 2: Remove GuideCategory.all from the enum**

In the same file, remove the `all` case from `GuideCategory` enum and its `labelKey`/`iconAsset` switch arms:

```dart
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
```

- [ ] **Step 3: Add `part 'guide_topics_data.dart';` directive and move topics**

At end of `guide_data.dart`, add:
```dart
part 'guide_topics_data.dart';
```

Remove the entire `const guideTopics = <GuideTopic>[...]` list from this file.

- [ ] **Step 4: Create guide_topics_data.dart with all 15 topics**

Create `lib/features/more/widgets/guide_topics_data.dart`:

```dart
part of 'guide_data.dart';

const guideTopics = <GuideTopic>[
  // 1. Kayit ve Giris (index 0)
  GuideTopic(
    titleKey: 'user_guide.topics.registration.title',
    subtitleKey: 'user_guide.topics.registration.subtitle',
    iconAsset: AppIcons.profile,
    category: GuideCategory.gettingStarted,
    relatedTopicIndices: [1, 2],
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

  // 2. Dashboard Tanitimi (index 1)
  GuideTopic(
    titleKey: 'user_guide.topics.dashboard.title',
    subtitleKey: 'user_guide.topics.dashboard.subtitle',
    iconAsset: AppIcons.home,
    category: GuideCategory.gettingStarted,
    relatedTopicIndices: [0, 2],
    blocks: [
      GuideBlock.text('user_guide.topics.dashboard.intro'),
      GuideBlock.text('user_guide.topics.dashboard.stats_info'),
      GuideBlock.text('user_guide.topics.dashboard.quick_actions'),
      GuideBlock.tip('user_guide.topics.dashboard.tip_refresh'),
    ],
  ),

  // 3. Navigasyon (index 2)
  GuideTopic(
    titleKey: 'user_guide.topics.navigation.title',
    subtitleKey: 'user_guide.topics.navigation.subtitle',
    iconAsset: AppIcons.more,
    category: GuideCategory.gettingStarted,
    relatedTopicIndices: [1],
    blocks: [
      GuideBlock.text('user_guide.topics.navigation.intro'),
      GuideBlock.text('user_guide.topics.navigation.bottom_nav'),
      GuideBlock.text('user_guide.topics.navigation.more_menu'),
      GuideBlock.tip('user_guide.topics.navigation.tip_back'),
    ],
  ),

  // 4. Kus Ekleme ve Duzenleme (index 3)
  GuideTopic(
    titleKey: 'user_guide.topics.bird_management.title',
    subtitleKey: 'user_guide.topics.bird_management.subtitle',
    iconAsset: AppIcons.bird,
    category: GuideCategory.birdManagement,
    relatedTopicIndices: [4, 5],
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

  // 5. Filtreleme ve Arama (index 4)
  GuideTopic(
    titleKey: 'user_guide.topics.filtering.title',
    subtitleKey: 'user_guide.topics.filtering.subtitle',
    iconAsset: AppIcons.filter,
    category: GuideCategory.birdManagement,
    relatedTopicIndices: [3],
    blocks: [
      GuideBlock.text('user_guide.topics.filtering.intro'),
      GuideBlock.text('user_guide.topics.filtering.filter_types'),
      GuideBlock.text('user_guide.topics.filtering.search_info'),
      GuideBlock.tip('user_guide.topics.filtering.tip_combine'),
    ],
  ),

  // 6. Saglik Kayitlari (index 5)
  GuideTopic(
    titleKey: 'user_guide.topics.health_records.title',
    subtitleKey: 'user_guide.topics.health_records.subtitle',
    iconAsset: AppIcons.health,
    category: GuideCategory.birdManagement,
    relatedTopicIndices: [3],
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

  // 7. Cift Olusturma (index 6)
  GuideTopic(
    titleKey: 'user_guide.topics.breeding_pair.title',
    subtitleKey: 'user_guide.topics.breeding_pair.subtitle',
    iconAsset: AppIcons.pair,
    category: GuideCategory.breedingProcess,
    relatedTopicIndices: [7, 8],
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

  // 8. Yumurta ve Kulucka (index 7)
  GuideTopic(
    titleKey: 'user_guide.topics.eggs_incubation.title',
    subtitleKey: 'user_guide.topics.eggs_incubation.subtitle',
    iconAsset: AppIcons.egg,
    category: GuideCategory.breedingProcess,
    relatedTopicIndices: [6, 8],
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

  // 9. Yavru Takibi (index 8)
  GuideTopic(
    titleKey: 'user_guide.topics.chick_tracking.title',
    subtitleKey: 'user_guide.topics.chick_tracking.subtitle',
    iconAsset: AppIcons.chick,
    category: GuideCategory.breedingProcess,
    relatedTopicIndices: [6, 7],
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

  // 10. Takvim ve Bildirimler (index 9)
  GuideTopic(
    titleKey: 'user_guide.topics.calendar_notifications.title',
    subtitleKey: 'user_guide.topics.calendar_notifications.subtitle',
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

  // 11. Soy Agaci ve Genetik (index 10)
  GuideTopic(
    titleKey: 'user_guide.topics.genealogy_genetics.title',
    subtitleKey: 'user_guide.topics.genealogy_genetics.subtitle',
    iconAsset: AppIcons.dna,
    category: GuideCategory.tools,
    isPremium: true,
    relatedTopicIndices: [6],
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

  // 12. Yedekleme ve Disari Aktarma (index 11)
  GuideTopic(
    titleKey: 'user_guide.topics.backup_export.title',
    subtitleKey: 'user_guide.topics.backup_export.subtitle',
    iconAsset: AppIcons.backup,
    category: GuideCategory.dataManagement,
    relatedTopicIndices: [12],
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

  // 13. Senkronizasyon (index 12)
  GuideTopic(
    titleKey: 'user_guide.topics.sync.title',
    subtitleKey: 'user_guide.topics.sync.subtitle',
    iconAsset: AppIcons.sync,
    category: GuideCategory.dataManagement,
    relatedTopicIndices: [11],
    blocks: [
      GuideBlock.text('user_guide.topics.sync.intro'),
      GuideBlock.text('user_guide.topics.sync.offline_info'),
      GuideBlock.text('user_guide.topics.sync.conflict_info'),
      GuideBlock.tip('user_guide.topics.sync.tip_connection'),
      GuideBlock.warning('user_guide.topics.sync.warning_data_loss'),
    ],
  ),

  // 14. Profil ve Ayarlar (index 13)
  GuideTopic(
    titleKey: 'user_guide.topics.profile_settings.title',
    subtitleKey: 'user_guide.topics.profile_settings.subtitle',
    iconAsset: AppIcons.settings,
    category: GuideCategory.accountSettings,
    relatedTopicIndices: [14],
    blocks: [
      GuideBlock.text('user_guide.topics.profile_settings.intro'),
      GuideBlock.text('user_guide.topics.profile_settings.profile_info'),
      GuideBlock.text('user_guide.topics.profile_settings.settings_info'),
      GuideBlock.tip('user_guide.topics.profile_settings.tip_language'),
    ],
  ),

  // 15. Premium Uyelik (index 14)
  GuideTopic(
    titleKey: 'user_guide.topics.premium.title',
    subtitleKey: 'user_guide.topics.premium.subtitle',
    iconAsset: AppIcons.premium,
    category: GuideCategory.accountSettings,
    relatedTopicIndices: [13],
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
```

- [ ] **Step 5: Verify file compiles**

Run: `dart analyze lib/features/more/widgets/guide_data.dart lib/features/more/widgets/guide_topics_data.dart`
Expected: No errors

- [ ] **Step 6: Update guide_data_test.dart**

Rewrite `test/features/more/widgets/guide_data_test.dart` to:
- Change category count from 7 to 6
- Remove all references to `GuideCategory.all`
- Add tests for `subtitleKey` on every topic (non-empty, starts with `user_guide.topics.`)
- Add tests for `relatedTopicIndices` bounds validation (all `>= 0` and `< guideTopics.length`, no self-reference)
- Add test for `stepCount` getter
- Keep existing block type tests, icon asset tests, premium tests

Key test assertions:
```dart
test('GuideCategory has 6 values', () {
  expect(GuideCategory.values.length, 6);
});

test('all relatedTopicIndices are valid', () {
  for (var i = 0; i < guideTopics.length; i++) {
    for (final relIdx in guideTopics[i].relatedTopicIndices) {
      expect(relIdx, greaterThanOrEqualTo(0));
      expect(relIdx, lessThan(guideTopics.length));
      expect(relIdx, isNot(i), reason: 'Topic $i references itself');
    }
  }
});

test('every topic has subtitleKey', () {
  for (final topic in guideTopics) {
    expect(topic.subtitleKey, isNotEmpty);
    expect(topic.subtitleKey, startsWith('user_guide.topics.'));
  }
});
```

- [ ] **Step 7: Run data tests**

Run: `flutter test test/features/more/widgets/guide_data_test.dart`
Expected: All tests PASS

- [ ] **Step 8: Commit**

```bash
git add lib/features/more/widgets/guide_data.dart lib/features/more/widgets/guide_topics_data.dart test/features/more/widgets/guide_data_test.dart
git commit -m "refactor(user-guide): add subtitleKey, relatedTopicIndices, remove GuideCategory.all"
```

---

### Task 2: Add Localization Keys

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add new keys to tr.json**

In the `user_guide` section, add these keys (at the top level alongside existing keys):
```json
"related_topics": "İlgili Konular",
"step_count": "{} adım"
```

Remove:
```json
"category_all": "Tümü"
```

Add `subtitle` key to each of the 15 topics inside `user_guide.topics.*`:
```
registration.subtitle: "Uygulamayı kullanmaya başlamak için kayıt olun"
dashboard.subtitle: "Ana ekranda istatistikler ve hızlı erişim"
navigation.subtitle: "Sekmeler ve menüler arasında gezinme"
bird_management.subtitle: "Kuşlarınızı kayıt altına alın ve düzenleyin"
filtering.subtitle: "Kuşlarınızı hızla bulmak için filtre ve arama"
health_records.subtitle: "Kuşlarınızın sağlık geçmişini takip edin"
breeding_pair.subtitle: "Üreme çifti oluşturun ve yönetin"
eggs_incubation.subtitle: "Yumurta kaydı ve kuluçka süreci takibi"
chick_tracking.subtitle: "Yavru gelişimini ve büyümesini izleyin"
calendar_notifications.subtitle: "Takvim etkinlikleri ve hatırlatıcılar"
genealogy_genetics.subtitle: "Soy ağacı ve genetik hesaplamalar"
backup_export.subtitle: "Verilerinizi yedekleyin ve dışa aktarın"
sync.subtitle: "Cihazlar arası veri senkronizasyonu"
profile_settings.subtitle: "Profil bilgileri ve uygulama ayarları"
premium.subtitle: "Premium özelliklere erişim ve abonelik"
```

- [ ] **Step 2: Add same keys to en.json (English translations)**

```
related_topics: "Related Topics"
step_count: "{} steps"
```
Remove `category_all`. Add 15 subtitle keys with English translations.

- [ ] **Step 3: Add same keys to de.json (German translations)**

```
related_topics: "Verwandte Themen"
step_count: "{} Schritte"
```
Remove `category_all`. Add 15 subtitle keys with German translations.

- [ ] **Step 4: Verify L10n sync**

Run: `python scripts/check_l10n_sync.py`
Expected: All 3 files in sync, no missing keys

- [ ] **Step 5: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(l10n): add user guide subtitle and related topics keys"
```

---

### Task 3: Add Route Constant (route name only)

**Files:**
- Modify: `lib/router/route_names.dart`

- [ ] **Step 1: Add route constant**

In `lib/router/route_names.dart`, add after `userGuide`:
```dart
static const userGuideDetail = '/user-guide/:topicIndex';
```

- [ ] **Step 2: Commit**

```bash
git add lib/router/route_names.dart
git commit -m "feat(router): add userGuideDetail route constant"
```

> **Note:** The nested route in `user_routes.dart` will be updated in Task 5 alongside
> the `GuideDetailScreen` creation to avoid import errors from a non-existent file.

---

### Task 4: Create GuideTopicListItem Widget

**Files:**
- Create: `lib/features/more/widgets/guide_topic_list_item.dart`
- Create: `test/features/more/widgets/guide_topic_list_item_test.dart`
- Delete: `lib/features/more/widgets/guide_topic_card.dart`
- Delete: `test/features/more/widgets/guide_topic_card_test.dart`

- [ ] **Step 1: Write failing test for GuideTopicListItem**

Create `test/features/more/widgets/guide_topic_list_item_test.dart`:

Test cases:
- Renders topic title text (use `find.text` with the titleKey since no L10n in basic test)
- Renders subtitle text
- Renders chevron icon (`LucideIcons.chevronRight`)
- Renders SVG icon via `AppIcon`
- Shows premium badge when `isPremium: true`
- Hides premium badge when `isPremium: false`
- Calls `onTap` callback when tapped
- Shows divider when `showDivider: true`, hides when `false`

Use the first `guideTopics[0]` entry for test data. Wrap in `MaterialApp` for theme.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/more/widgets/guide_topic_list_item_test.dart`
Expected: FAIL — class not found

- [ ] **Step 3: Implement GuideTopicListItem**

Create `lib/features/more/widgets/guide_topic_list_item.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';

class GuideTopicListItem extends StatelessWidget {
  final GuideTopic topic;
  final VoidCallback onTap;
  final bool showDivider;

  const GuideTopicListItem({
    super.key,
    required this.topic,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                      child: AppIcon(topic.iconAsset),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              topic.title,
                              style: theme.textTheme.titleSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (topic.isPremium) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const _PremiumBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        topic.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Chevron
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(
              height: 1,
              indent: AppSpacing.lg + 38 + AppSpacing.md, // icon offset
              endIndent: 0,
            ),
        ],
      ),
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.warning, width: 1),
      ),
      child: Text(
        'user_guide.premium_feature'.tr(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/more/widgets/guide_topic_list_item_test.dart`
Expected: All PASS

- [ ] **Step 5: Delete old GuideTopicCard files**

```bash
rm lib/features/more/widgets/guide_topic_card.dart
rm test/features/more/widgets/guide_topic_card_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat(user-guide): add GuideTopicListItem, delete GuideTopicCard"
```

---

### Task 5: Create GuideDetailScreen + Wire Route

**Files:**
- Create: `lib/features/more/screens/guide_detail_screen.dart`
- Modify: `lib/router/routes/user_routes.dart`
- Create: `test/features/more/screens/guide_detail_screen_test.dart`

- [ ] **Step 1: Write failing test for GuideDetailScreen**

Create `test/features/more/screens/guide_detail_screen_test.dart`:

Test cases:
- Renders topic title in AppBar
- Renders category label (uppercase) in header
- Renders step count when topic has steps
- Hides step count when topic has no steps (e.g., topic index 1 — Dashboard has 0 steps)
- Renders GuideBlockRenderer with topic blocks
- Renders related topics section when relatedTopicIndices is non-empty
- Hides related topics section when relatedTopicIndices is empty (topic index 9 — Calendar)
- Related topic items are tappable (verify InkWell/onTap exists)

Wrap in `MaterialApp.router` with GoRouter for navigation testing, or use `MaterialApp(home: GuideDetailScreen(topicIndex: 0))` for simpler tests.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/more/screens/guide_detail_screen_test.dart`
Expected: FAIL — class not found

- [ ] **Step 3: Implement GuideDetailScreen**

Create `lib/features/more/screens/guide_detail_screen.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_content_widgets.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';

class GuideDetailScreen extends StatelessWidget {
  final int topicIndex;
  const GuideDetailScreen({super.key, required this.topicIndex});

  @override
  Widget build(BuildContext context) {
    final topic = guideTopics[topicIndex];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailHeader(topic: topic),
            const SizedBox(height: AppSpacing.lg),
            GuideBlockRenderer(blocks: topic.blocks),
            if (topic.relatedTopicIndices.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              _RelatedTopicsSection(
                indices: topic.relatedTopicIndices,
                currentIndex: topicIndex,
              ),
            ],
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  final GuideTopic topic;
  const _DetailHeader({required this.topic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepCount = topic.stepCount;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Center(
            child: IconTheme(
              data: IconThemeData(
                color: theme.colorScheme.primary,
                size: 24,
              ),
              child: AppIcon(topic.iconAsset),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.category.label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (stepCount > 0)
              Text(
                'user_guide.step_count'.tr(args: [stepCount.toString()]),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RelatedTopicsSection extends StatelessWidget {
  final List<int> indices;
  final int currentIndex;
  const _RelatedTopicsSection({
    required this.indices,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'user_guide.related_topics'.tr().toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < indices.length; i++) ...[
                _RelatedTopicItem(
                  topic: guideTopics[indices[i]],
                  onTap: () => context.push('/user-guide/${indices[i]}'),
                ),
                if (i < indices.length - 1)
                  Divider(
                    height: 1,
                    indent: AppSpacing.lg + 32 + AppSpacing.sm,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RelatedTopicItem extends StatelessWidget {
  final GuideTopic topic;
  final VoidCallback onTap;
  const _RelatedTopicItem({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: IconTheme(
                  data: IconThemeData(
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                  child: AppIcon(topic.iconAsset),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                topic.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/more/screens/guide_detail_screen_test.dart`
Expected: All PASS

- [ ] **Step 5: Wire nested route in user_routes.dart**

In `lib/router/routes/user_routes.dart`, replace the flat `userGuide` GoRoute:

```dart
// Before:
GoRoute(
  path: AppRoutes.userGuide,
  builder: (context, state) => const UserGuideScreen(),
),

// After:
GoRoute(
  path: AppRoutes.userGuide,
  builder: (context, state) => const UserGuideScreen(),
  routes: [
    GoRoute(
      path: ':topicIndex',
      builder: (context, state) {
        final index = int.tryParse(
          state.pathParameters['topicIndex'] ?? '',
        );
        if (index == null || index < 0 || index >= guideTopics.length) {
          return const NotFoundScreen();
        }
        return GuideDetailScreen(topicIndex: index);
      },
    ),
  ],
),
```

Add imports at top of file:
```dart
import '../../features/more/screens/guide_detail_screen.dart';
import '../../features/more/widgets/guide_data.dart';
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/more/screens/guide_detail_screen.dart lib/router/routes/user_routes.dart test/features/more/screens/guide_detail_screen_test.dart
git commit -m "feat(user-guide): add GuideDetailScreen with related topics and route"
```

---

### Task 6: Rewrite UserGuideScreen (Grouped List)

**Files:**
- Rewrite: `lib/features/more/screens/user_guide_screen.dart`
- Rewrite: `test/features/more/screens/user_guide_screen_test.dart`
- Update: `test/features/more/screens/user_guide_screen_localized_test.dart`

- [ ] **Step 1: Write failing tests for new UserGuideScreen**

Rewrite `test/features/more/screens/user_guide_screen_test.dart`:

Test cases:
- Renders AppBar with localized title
- Renders search bar with hint text
- Renders category section headers (find text for each category label)
- Renders topic list items within grouped cards
- Search filters topics and flattens list (no section headers when searching)
- Empty state shown when search has no results
- Tapping a topic item triggers navigation (use `GoRouter` mock or verify `find.byType(InkWell)`)

- [ ] **Step 2: Rewrite user_guide_screen.dart**

Replace entire content of `lib/features/more/screens/user_guide_screen.dart`.

Key structural changes:
- Remove `_CategoryChipBar` widget entirely
- Remove `_selectedCategory` state field
- Keep `_searchController`, `_searchQuery`, `_searchFoldMap`, `_normalizeSearchText`, `_matchesQuery` (preserve Turkish search normalization)
- New `_filteredTopics` getter: only applies search filter (no category filter since chip bar is removed)
- Build method: if search is active → flat list of matching topics; if not → grouped by category with section headers

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_data.dart';
import 'package:budgie_breeding_tracker/features/more/widgets/guide_topic_list_item.dart';

class UserGuideScreen extends StatefulWidget {
  const UserGuideScreen({super.key});

  @override
  State<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends State<UserGuideScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Turkish/German diacritic fold map — PRESERVED from original
  static const Map<String, String> _searchFoldMap = {
    'i̇': 'i', 'ı': 'i', 'ş': 's', 'ç': 'c', 'ğ': 'g',
    'ü': 'u', 'ö': 'o', 'ä': 'a', 'â': 'a', 'à': 'a',
    'á': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'î': 'i',
    'í': 'i', 'ì': 'i', 'ô': 'o', 'ó': 'o', 'ò': 'o',
    'û': 'u', 'ú': 'u', 'ù': 'u', 'ñ': 'n', 'ß': 'ss',
  };

  static String _normalizeSearchText(String value) {
    var normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    _searchFoldMap.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });
    return normalized;
  }

  static bool _matchesQuery(String candidate, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return true;
    return _normalizeSearchText(candidate).contains(normalizedQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns (index, topic) pairs matching the search query.
  List<(int, GuideTopic)> get _filteredTopics {
    final indexed = <(int, GuideTopic)>[];
    for (var i = 0; i < guideTopics.length; i++) {
      indexed.add((i, guideTopics[i]));
    }

    if (_searchQuery.isEmpty) return indexed;

    final query = _normalizeSearchText(_searchQuery);
    return indexed.where((entry) {
      final t = entry.$2;
      if (_matchesQuery(t.title, query)) return true;
      for (final block in t.blocks) {
        if (block.textKey != null && _matchesQuery(block.textKey!.tr(), query)) return true;
        if (block.stepsTitle != null && _matchesQuery(block.stepsTitle!.tr(), query)) return true;
        if (block.stepKeys != null) {
          for (final key in block.stepKeys!) {
            if (_matchesQuery(key.tr(), query)) return true;
          }
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final topics = _filteredTopics;
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text('user_guide.title'.tr())),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'user_guide.search_hint'.tr(),
                prefixIcon: const AppIcon(AppIcons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Content
          Expanded(
            child: topics.isEmpty
                ? EmptyState(
                    icon: const AppIcon(AppIcons.search),
                    title: 'common.no_results'.tr(),
                    subtitle: 'common.no_results_hint'.tr(),
                  )
                : isSearching
                    ? _buildFlatList(topics)
                    : _buildGroupedList(topics),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatList(List<(int, GuideTopic)> topics) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs, bottom: AppSpacing.xxxl * 2,
      ),
      itemCount: topics.length,
      itemBuilder: (context, i) {
        final (index, topic) = topics[i];
        return GuideTopicListItem(
          topic: topic,
          showDivider: i < topics.length - 1,
          onTap: () => context.push('/user-guide/$index'),
        );
      },
    );
  }

  Widget _buildGroupedList(List<(int, GuideTopic)> topics) {
    final theme = Theme.of(context);
    final categories = GuideCategory.values;
    final widgets = <Widget>[];

    for (final category in categories) {
      final categoryTopics = topics
          .where((e) => e.$2.category == category)
          .toList();
      if (categoryTopics.isEmpty) continue;

      // Section header
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg + AppSpacing.xs, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
          ),
          child: Text(
            category.label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );

      // Grouped card
      widgets.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < categoryTopics.length; i++)
                GuideTopicListItem(
                  topic: categoryTopics[i].$2,
                  showDivider: i < categoryTopics.length - 1,
                  onTap: () => context.push(
                    '/user-guide/${categoryTopics[i].$1}',
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.xs, bottom: AppSpacing.xxxl * 2,
      ),
      children: widgets,
    );
  }
}
```

- [ ] **Step 3: Update localized test file**

In `test/features/more/screens/user_guide_screen_localized_test.dart`:
- Keep the Turkish diacritic search normalization tests
- Remove ExpansionTile interaction tests (the widget no longer uses ExpansionTile)
- Update any assertions that reference `ChoiceChip` or `_CategoryChipBar` (removed)

- [ ] **Step 4: Run all user guide tests**

Run: `flutter test test/features/more/`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/more/screens/user_guide_screen.dart test/features/more/screens/user_guide_screen_test.dart test/features/more/screens/user_guide_screen_localized_test.dart
git commit -m "feat(user-guide): rewrite list screen with grouped categories"
```

---

### Task 7: Final Verification

**Files:** All modified files

- [ ] **Step 1: Run full test suite**

Run: `flutter test test/features/more/`
Expected: All PASS

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 3: Run L10n sync check**

Run: `python scripts/check_l10n_sync.py`
Expected: All files in sync

- [ ] **Step 4: Run code quality check**

Run: `python scripts/verify_code_quality.py`
Expected: No anti-pattern violations

- [ ] **Step 5: Run dart format**

Run: `dart format lib/features/more/ test/features/more/`
Expected: No formatting changes needed (or apply them)

- [ ] **Step 6: Final commit (if any formatting changes)**

```bash
git add -A
git commit -m "style(user-guide): apply dart format"
```
