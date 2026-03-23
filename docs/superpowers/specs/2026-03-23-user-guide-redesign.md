# User Guide Screen Redesign

**Date:** 2026-03-23
**Status:** Approved
**Scope:** `lib/features/more/` (screens, widgets) + router + L10n

## Summary

Redesign the User Guide (Kullanim Kilavuzu) screen from an ExpansionTile-based
inline layout to a clean, minimal iOS-Settings-style grouped list with a
separate detail page. Topics are grouped by category with section headers,
and tapping a topic navigates to a dedicated scroll page. A "Related Topics"
section at the bottom of each detail page improves discoverability.

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Visual style | Clean & Minimal (iOS Settings) | Matches app's Material 3 aesthetic, simple |
| Detail page | Separate screen via `context.push` | Better UX than inline ExpansionTile |
| Detail layout | Single scroll page | All content visible, simple implementation |
| List grouping | Category section headers | Replaces horizontal chip bar, better scannability |
| Extra feature | Related Topics links | Improves discoverability between topics |

## Architecture

### Current State (Before)

```
UserGuideScreen (StatefulWidget)
  ├── SearchBar (TextField)
  ├── _CategoryChipBar (horizontal ChoiceChip list)
  └── ListView<GuideTopicCard>
        └── Card > ExpansionTile > GuideBlockRenderer
```

**Files:**
- `lib/features/more/screens/user_guide_screen.dart` (219 lines)
- `lib/features/more/widgets/guide_data.dart` (367 lines)
- `lib/features/more/widgets/guide_topic_card.dart` (67 lines)
- `lib/features/more/widgets/guide_content_widgets.dart` (274 lines)

### Target State (After)

```
UserGuideScreen (StatefulWidget) — MODIFIED
  ├── SearchBar (TextField) — KEPT
  └── ListView (grouped by category)
        ├── _CategoryHeader ("BASLANGIC", "KUS YONETIMI", ...)
        └── _GuideTopicListItem (icon + title + subtitle + chevron)
              └── onTap → context.push('/user-guide/$topicIndex')

GuideDetailScreen (StatelessWidget) — NEW
  ├── AppBar (topic title)
  ├── _DetailHeader (icon + category label + step count)
  ├── GuideBlockRenderer — KEPT (no changes)
  └── _RelatedTopicsSection (list of related topic links)
```

**Files:**
- `lib/features/more/screens/user_guide_screen.dart` — REWRITE (grouped list)
- `lib/features/more/screens/guide_detail_screen.dart` — NEW
- `lib/features/more/widgets/guide_topic_list_item.dart` — NEW (replaces guide_topic_card.dart)
- `lib/features/more/widgets/guide_data.dart` — MODIFIED (add subtitleKey, relatedTopicIndices, split topics into part file)
- `lib/features/more/widgets/guide_topics_data.dart` — NEW (part of guide_data.dart, contains 15 topic definitions)
- `lib/features/more/widgets/guide_content_widgets.dart` — KEPT (no changes)
- `lib/features/more/widgets/guide_topic_card.dart` — DELETED (replaced by list item + detail screen)

### Route Changes

**route_names.dart** — add:
```dart
static const userGuideDetail = '/user-guide/:topicIndex';
```

**user_routes.dart** — change from flat route to nested:
```dart
GoRoute(
  path: AppRoutes.userGuide,
  builder: (context, state) => const UserGuideScreen(),
  routes: [
    GoRoute(
      path: ':topicIndex',
      builder: (context, state) {
        final index = int.tryParse(state.pathParameters['topicIndex'] ?? '');
        if (index == null || index < 0 || index >= guideTopics.length) {
          return const NotFoundScreen();
        }
        return GuideDetailScreen(topicIndex: index);
      },
    ),
  ],
),
```

## Data Model Changes

### GuideTopic — add fields

```dart
class GuideTopic {
  final String titleKey;
  final String subtitleKey;           // NEW — short description for list preview
  final String iconAsset;
  final GuideCategory category;
  final List<GuideBlock> blocks;
  final bool isPremium;
  final List<int> relatedTopicIndices; // NEW — indices into guideTopics list

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
}
```

### GuideCategory — remove `all`

The `all` category was only needed for chip bar filtering. With grouped list,
it is no longer needed. The search still filters across all categories.
Remove `GuideCategory.all` and its `labelKey`/`iconAsset`.
Also remove the `user_guide.category_all` key from all 3 L10n files.

**Breaking test changes from removing `all`:**
- `guide_data_test.dart` line 31: `containsAll` assertion includes `all` — remove it
- `guide_data_test.dart` line 43: `values.length` is 7, becomes 6
- `guide_data_test.dart` line 48-49: Filter test references `all` — remove/rewrite
- `guide_data_test.dart` line 58: `all.iconAsset` assertion — delete
- `guide_data_test.dart` line 68: `labelKey` prefix assertion for `all` — remove

## UI Specifications

### List Screen (UserGuideScreen)

**Layout:**
```
Scaffold
  AppBar: "Kullanim Kilavuzu"
  Body: Column
    SearchBar (unchanged except border style)
    SizedBox(height: sm)
    Expanded > ListView
      For each category (excluding `all`):
        _CategoryHeader (uppercase label, primary color, letterSpacing)
        Card (rounded, grouped items inside)
          For each topic in category:
            _GuideTopicListItem
              Row: [icon(38x38, f3f4f6 bg, rounded) | Column[title, subtitle] | chevron]
              Divider (inset from left, skip last item)
            onTap: context.push('/user-guide/$index')
        SizedBox(height: lg)
```

**Search behavior:**
- When search query is non-empty, flatten the grouped list — show only matching
  topics in a flat list (no section headers)
- Empty state unchanged: EmptyState widget with search icon

**Search normalization:**
- The existing `_searchFoldMap` and `_normalizeSearchText` logic for Turkish/German
  diacritic folding (i̇→i, ş→s, ç→c, ğ→g, ü→u, ö→o, etc.) MUST be preserved
  in the rewritten screen. This is critical for Turkish language search.

**Dimensions:**
- Icon container: 38x38, borderRadius `AppSpacing.radiusLg` (12), background `theme.colorScheme.surfaceContainerHighest`
- Title: `titleSmall`, color `onSurface`
- Subtitle: `bodySmall`, color `onSurfaceVariant`, maxLines 1, ellipsis
- Chevron: `LucideIcons.chevronRight`, size 18, color `onSurfaceVariant`
- Divider: inset left 66px (icon width 38 + gap 12 + padding 16)
- Card margin: horizontal `AppSpacing.lg`

### Detail Screen (GuideDetailScreen)

**Layout:**
```
Scaffold
  AppBar: topic.title
  Body: SingleChildScrollView
    Padding(screenPadding)
      _DetailHeader
        Row: [icon(48x48) | Column[category label (uppercase, primary), step count]]
      SizedBox(height: lg)
      GuideBlockRenderer(blocks: topic.blocks)  // REUSED, no changes
      SizedBox(height: xl)
      if (relatedTopicIndices.isNotEmpty)
        _RelatedTopicsSection
          Text "ILGILI KONULAR" (uppercase, onSurfaceVariant, letterSpacing)
          SizedBox(height: sm)
          Card (grouped list)
            For each related index:
              ListTile-like row: [icon(32x32) | title | chevron]
              Divider (inset, skip last)
              onTap: context.push('/user-guide/$relatedIndex')
```

**Step count calculation:**
- Count blocks where `type == GuideBlockType.steps`, sum their `stepKeys.length`
- Display as: "{n} adim" using L10n key
- If step count is 0 (topic has no steps blocks), hide the step count line entirely

## Localization Changes

### New keys (add to tr.json, en.json, de.json)

```json
{
  "user_guide": {
    "related_topics": "Ilgili Konular",
    "step_count": "{} adim",
    "topics": {
      "registration": {
        "subtitle": "Uygulamayi kullanmaya baslamak icin kayit olun"
      },
      "dashboard": {
        "subtitle": "Ana ekranda istatistikler ve hizli erisim"
      },
      "navigation": {
        "subtitle": "Sekmeler ve menuler arasinda gezinme"
      },
      "bird_management": {
        "subtitle": "Kuslarinizi kayit altina alin ve duzenleyin"
      },
      "filtering": {
        "subtitle": "Kuslarinizi hizla bulmak icin filtre ve arama"
      },
      "health_records": {
        "subtitle": "Kuslarinizin saglik gecmisini takip edin"
      },
      "breeding_pair": {
        "subtitle": "Ureme cifti olusturun ve yonetin"
      },
      "eggs_incubation": {
        "subtitle": "Yumurta kaydi ve kulucka sureci takibi"
      },
      "chick_tracking": {
        "subtitle": "Yavru gelisimini ve buyumesini izleyin"
      },
      "calendar_notifications": {
        "subtitle": "Takvim etkinlikleri ve hatirlaticilar"
      },
      "genealogy_genetics": {
        "subtitle": "Soy agaci ve genetik hesaplamalar"
      },
      "backup_export": {
        "subtitle": "Verilerinizi yedekleyin ve disa aktarin"
      },
      "sync": {
        "subtitle": "Cihazlar arasi veri senkronizasyonu"
      },
      "profile_settings": {
        "subtitle": "Profil bilgileri ve uygulama ayarlari"
      },
      "premium": {
        "subtitle": "Premium ozelliklere erisim ve abonelik"
      }
    }
  }
}
```

### Related Topic Mapping

Each topic's `relatedTopicIndices` (0-indexed into `guideTopics`):

| # | Topic | Related Indices |
|---|-------|----------------|
| 0 | Registration | [1, 2] (Dashboard, Navigation) |
| 1 | Dashboard | [0, 2] (Registration, Navigation) |
| 2 | Navigation | [1] (Dashboard) |
| 3 | Bird Management | [4, 5] (Filtering, Health Records) |
| 4 | Filtering | [3] (Bird Management) |
| 5 | Health Records | [3] (Bird Management) |
| 6 | Breeding Pair | [7, 8] (Eggs, Chicks) |
| 7 | Eggs & Incubation | [6, 8] (Breeding Pair, Chicks) |
| 8 | Chick Tracking | [6, 7] (Breeding Pair, Eggs) |
| 9 | Calendar | [] |
| 10 | Genealogy & Genetics | [6] (Breeding Pair) |
| 11 | Backup & Export | [12] (Sync) |
| 12 | Sync | [11] (Backup) |
| 13 | Profile & Settings | [14] (Premium) |
| 14 | Premium | [13] (Profile & Settings) |

## Files Changed Summary

| File | Action | Lines (est.) |
|------|--------|-------------|
| `user_guide_screen.dart` | Rewrite | ~180 |
| `guide_detail_screen.dart` | New | ~160 |
| `guide_topic_list_item.dart` | New | ~90 |
| `guide_data.dart` | Split | Models + enums only (~100 lines) |
| `guide_topics_data.dart` | New (part of guide_data) | 15 topic definitions (~300 lines) |
| `guide_content_widgets.dart` | Keep | 0 changes |
| `guide_topic_card.dart` | Delete | -67 |
| `route_names.dart` | Modify | +1 line |
| `user_routes.dart` | Modify | +10 lines (nested route) |
| `tr.json` | Modify | +17 keys, -1 key (`category_all`) |
| `en.json` | Modify | +17 keys, -1 key (`category_all`) |
| `de.json` | Modify | +17 keys, -1 key (`category_all`) |
| Tests | Update | Rewrite existing 4 test files + 1 localized test |

## Testing Strategy

- **guide_data_test.dart** — Update: verify subtitleKey, relatedTopicIndices, no `all` category, add relatedTopicIndices bounds validation test (all indices >= 0 and < guideTopics.length, no self-reference)
- **user_guide_screen_test.dart** — Rewrite: test grouped list rendering, search filtering (incl. Turkish diacritic normalization), navigation to detail
- **user_guide_screen_localized_test.dart** — Update: preserve Turkish diacritic search tests, remove ExpansionTile interaction tests (replaced by navigation tests)
- **guide_detail_screen_test.dart** — New: test header, block rendering, related topics navigation
- **guide_topic_list_item_test.dart** — New: test title/subtitle/icon/chevron rendering, premium badge
- **guide_topic_card_test.dart** — Delete (widget removed)

## Out of Scope

- FAQ block type (decided against in brainstorming)
- Search result highlighting (decided against)
- Reading time / meta info display (decided against)
- Tabbed detail page (decided against — single scroll chosen)
- Bookmark / reading progress tracking
- Contextual help from other screens
