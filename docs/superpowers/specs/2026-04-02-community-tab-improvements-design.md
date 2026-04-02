# Community Tab Improvements Design

**Date:** 2026-04-02
**Status:** Approved
**Scope:** 7 issues fixed in a single PR (~12 files)

---

## Problem Statement

The community tab has accumulated several UX and code quality issues:

1. Hardcoded colors break dark mode
2. Emoji usage in post type labels (anti-pattern)
3. Missing `CachedNetworkImageProvider` in avatar widgets
4. Duplicate text in Quick Composer
5. Feed skeleton lacks shimmer animation
6. Excessive visual chrome before actual post content
7. Touch target compliance needs verification

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Approach | All 7 at once in single PR | User preference, coherent change set |
| Layout strategy | Balanced — remove Hero + Creator Strip, compact Composer | Posts visible ~35% sooner, community feel preserved |
| Dark mode strategy | Use `theme.colorScheme.*` semantic tokens | Automatic dark mode support, less maintenance |
| Skeleton approach | Reuse existing `SkeletonLoader` widget | Consistency with rest of app, already has shimmer |

## Design

### 1. Layout Changes

**Remove entirely:**
- `CommunityFeedHero` widget and file (`community_feed_hero.dart`)
- `CommunityCreatorStrip` widget and file (`community_creator_strip.dart`)

**Compact Quick Composer:**
- Current: Multi-line card with avatar, title, subtitle, inner text field placeholder, 3 action buttons
- New: Single-row bar — `[Avatar] [Placeholder text] [Type action icons]`
- Remove duplicate `'community.quick_hint'.tr()` (appears at line 94 and 124)
- Remove the inner `DecoratedBox` text field placeholder (lines 99-137)
- Keep the 3 quick action buttons (`_QuickActionButton`) but move them inline

**Keep unchanged:**
- `CommunityStoryStrip` — community feel, user discovery
- `CommunityPillTabs` — core navigation
- `CommunitySectionBar` — sort functionality needed

**Feed list sliver order (after change):**
1. Quick Composer (compact, single row)
2. Story Strip (explore tab only)
3. Section Bar (with sort chips)
4. Post list

### 2. Dark Mode — Hardcoded Color Replacements

#### `community_user_header.dart` — Post Type Colors

| Current (hardcoded) | Replacement |
|---------------------|-------------|
| `Color(0xFFF0FDF4)` (photo bg) | `theme.colorScheme.primaryContainer` |
| `Color(0xFF16A34A)` (photo text) | `theme.colorScheme.onPrimaryContainer` |
| `Color(0xFFEFF6FF)` (guide bg) | `theme.colorScheme.secondaryContainer` |
| `Color(0xFF2563EB)` (guide text) | `theme.colorScheme.onSecondaryContainer` |
| `Color(0xFFFFF7ED)` (question bg) | `theme.colorScheme.tertiaryContainer` |
| `Color(0xFFEA580C)` (question text) | `theme.colorScheme.onTertiaryContainer` |
| `Color(0xFFFAF5FF)` (tip bg) | `theme.colorScheme.surfaceContainerHighest` |
| `Color(0xFF9333EA)` (tip text) | `theme.colorScheme.onSurface` |
| `Color(0xFFFFFBEB)` (showcase bg) | `theme.colorScheme.tertiaryContainer` |
| `Color(0xFFCA8A04)` (showcase text) | `theme.colorScheme.onTertiaryContainer` |

Note: Some post types will share container colors. This is acceptable — the type badge text differentiates them. Exact mapping may be adjusted during implementation to achieve best visual distinction with available semantic tokens.

#### `community_post_actions.dart` — Action Button Colors

| Current | Replacement |
|---------|-------------|
| `Color(0xFFFEF2F2)` (liked bg) | `theme.colorScheme.errorContainer` |
| `Color(0xFF2563EB)` (comment label) | `theme.colorScheme.secondary` |

### 3. Emoji → LucideIcons

In `community_user_header.dart`, replace `_postTypeLabel()`:

| Current | Replacement |
|---------|-------------|
| `📷` (photo) | `LucideIcons.camera` |
| `📚` (guide) | `LucideIcons.bookOpen` |
| `❓` (question) | `LucideIcons.helpCircle` |
| `💡` (tip) | `LucideIcons.lightbulb` |
| `🏆` (showcase) | `LucideIcons.trophy` |

The label widget changes from `Text('📷 Photo')` to a `Row` with `Icon` + `Text`.

### 4. CachedNetworkImage

Replace `NetworkImage` with `CachedNetworkImageProvider` in:
- `community_story_strip.dart:179` — `_StoryAvatar` CircleAvatar foregroundImage
- `community_creator_strip.dart:135` — `_CreatorCard` CircleAvatar foregroundImage

Add `maxWidth: 72, maxHeight: 72` for avatar optimization.

### 5. Feed Skeleton with Shimmer

Replace `_CommunityFeedSkeleton` content (plain `Container` boxes) with `SkeletonLoader` instances:
- Hero area placeholder: `SkeletonLoader(height: 48, borderRadius: AppSpacing.radiusXl)`
- Post card placeholders (×3): Column of SkeletonLoaders simulating avatar row + text lines + image area

### 6. Creator Strip Removal Note

`CommunityCreatorStrip` file is deleted. Its `CreatorHighlight` data class is only used internally, so no other files reference it. The `fromPosts` static method and `CreatorHighlight` class are removed with the file.

`CommunityFeedHero` file is deleted. Its `_HeroMetric` class is private and has no external consumers.

## Files Changed

| File | Action | Change |
|------|--------|--------|
| `community_feed_hero.dart` | DELETE | Remove entire file |
| `community_creator_strip.dart` | DELETE | Remove entire file |
| `community_feed_list.dart` | EDIT | Remove hero/creator slivers, update sliver order |
| `community_quick_composer.dart` | EDIT | Compact to single row, remove duplicate text |
| `community_user_header.dart` | EDIT | Replace hardcoded colors + emojis |
| `community_post_actions.dart` | EDIT | Replace hardcoded colors |
| `community_story_strip.dart` | EDIT | NetworkImage → CachedNetworkImageProvider |
| `community_screen.dart` | EDIT | Clean up imports (hero/creator gone) |
| `community_section_bar.dart` | EDIT | Minor — remove hero-related references if any |
| Related test files | EDIT | Update/remove tests for deleted widgets |

## Out of Scope

- PillTabs layout change (touch targets already meet 44px minimum via `minHeight: AppSpacing.touchTargetMd + AppSpacing.md`)
- New features (trending algorithm, push notifications, etc.)
- Translation key changes beyond removing unused ones
- CommunityPostCard redesign (already well-structured)

## Testing Strategy

- Update widget tests that reference removed widgets (hero, creator strip)
- Verify dark mode rendering by checking all replaced colors use theme tokens
- Verify CachedNetworkImage import doesn't break existing tests (already a dependency)
- Feed skeleton visual check (shimmer renders)
