# Community Tab Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 7 community tab issues (dark mode, emoji anti-pattern, cache, layout, skeleton) in a single coherent PR.

**Architecture:** Edit-focused — mostly modifying existing widgets. Two files deleted (hero, creator strip), remaining files updated for theme compliance and layout compaction. No new files created.

**Tech Stack:** Flutter 3.16+ / Dart 3.8+ / Riverpod 3 / easy_localization / shimmer / cached_network_image / lucide_icons

**Spec:** `docs/superpowers/specs/2026-04-02-community-tab-improvements-design.md`

---

### Task 1: Fix hardcoded colors in community_user_header.dart

**Files:**
- Modify: `lib/features/community/widgets/community_user_header.dart:207-232`

- [ ] **Step 1: Replace `_postTypeColor` with theme-based colors**

Replace the static method at line 207-213:

```dart
  static Color _postTypeColor(CommunityPostType type, ThemeData theme) => switch (type) {
    CommunityPostType.photo => theme.colorScheme.primaryContainer,
    CommunityPostType.guide => theme.colorScheme.secondaryContainer,
    CommunityPostType.question => theme.colorScheme.tertiaryContainer,
    CommunityPostType.tip => theme.colorScheme.surfaceContainerHighest,
    CommunityPostType.showcase => theme.colorScheme.tertiaryContainer,
    _ => theme.colorScheme.surfaceContainerHighest,
  };
```

- [ ] **Step 2: Replace `_postTypeTextColor` with theme-based colors**

Replace the static method at line 216-223:

```dart
  static Color _postTypeTextColor(CommunityPostType type, ThemeData theme) => switch (type) {
    CommunityPostType.photo => theme.colorScheme.onPrimaryContainer,
    CommunityPostType.guide => theme.colorScheme.onSecondaryContainer,
    CommunityPostType.question => theme.colorScheme.onTertiaryContainer,
    CommunityPostType.tip => theme.colorScheme.onSurface,
    CommunityPostType.showcase => theme.colorScheme.onTertiaryContainer,
    _ => theme.colorScheme.onSurface,
  };
```

- [ ] **Step 3: Replace emoji `_postTypeLabel` with LucideIcons**

The current `_postTypeLabel` returns a `String` with emoji prefix. Change the post type badge area (line 129-143) to use an `Icon` + `Text` row instead of a `Text` with emoji.

Replace the `_postTypeLabel` method (line 225-232) and update the badge widget at line 129-143:

```dart
  // Replace the Container at line 129-143 with:
  if (postType != null && postType != CommunityPostType.general && postType != CommunityPostType.unknown)
    Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: _postTypeColor(postType!, theme),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _postTypeIcon(postType!),
            size: 12,
            color: _postTypeTextColor(postType!, theme),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _postTypeLabel(postType!),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _postTypeTextColor(postType!, theme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
```

Add the new `_postTypeIcon` method and simplify `_postTypeLabel`:

```dart
  static IconData _postTypeIcon(CommunityPostType type) => switch (type) {
    CommunityPostType.photo => LucideIcons.camera,
    CommunityPostType.guide => LucideIcons.bookOpen,
    CommunityPostType.question => LucideIcons.helpCircle,
    CommunityPostType.tip => LucideIcons.lightbulb,
    CommunityPostType.showcase => LucideIcons.trophy,
    _ => LucideIcons.messageSquare,
  };

  static String _postTypeLabel(CommunityPostType type) => switch (type) {
    CommunityPostType.photo => 'community.post_type_photo'.tr(),
    CommunityPostType.guide => 'community.post_type_guide'.tr(),
    CommunityPostType.question => 'community.post_type_question'.tr(),
    CommunityPostType.tip => 'community.post_type_tip'.tr(),
    CommunityPostType.showcase => 'community.post_type_showcase'.tr(),
    _ => '',
  };
```

- [ ] **Step 4: Run tests to verify**

Run: `flutter test test/features/community/widgets/community_user_header_test.dart`
Expected: All tests pass (existing tests don't check colors or emoji text)

- [ ] **Step 5: Commit**

```bash
git add lib/features/community/widgets/community_user_header.dart
git commit -m "fix(community): replace hardcoded colors and emojis with theme tokens and LucideIcons"
```

---

### Task 2: Fix hardcoded colors in community_post_actions.dart

**Files:**
- Modify: `lib/features/community/widgets/community_post_actions.dart:27-28,55`

- [ ] **Step 1: Replace hardcoded liked background color**

At line 27-28, replace:

```dart
    final likedBg = post.isLikedByMe
        ? const Color(0xFFFEF2F2)
        : theme.colorScheme.surfaceContainerHighest;
```

With:

```dart
    final likedBg = post.isLikedByMe
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.surfaceContainerHighest;
```

- [ ] **Step 2: Replace hardcoded comment label color**

At line 55, replace:

```dart
          labelColor: const Color(0xFF2563EB),
```

With:

```dart
          labelColor: theme.colorScheme.secondary,
```

- [ ] **Step 3: Run tests to verify**

Run: `flutter test test/features/community/widgets/community_post_actions_test.dart`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add lib/features/community/widgets/community_post_actions.dart
git commit -m "fix(community): replace hardcoded action button colors with theme tokens"
```

---

### Task 3: Replace NetworkImage with CachedNetworkImageProvider in story_strip

**Files:**
- Modify: `lib/features/community/widgets/community_story_strip.dart:1,177-179`

- [ ] **Step 1: Add import**

Add at the top of the file:

```dart
import 'package:cached_network_image/cached_network_image.dart';
```

- [ ] **Step 2: Replace NetworkImage in _StoryAvatar**

At line 177-179, replace:

```dart
                  foregroundImage: story.avatarUrl != null
                      ? NetworkImage(story.avatarUrl!)
                      : null,
```

With:

```dart
                  foregroundImage: story.avatarUrl != null
                      ? CachedNetworkImageProvider(
                          story.avatarUrl!,
                          maxWidth: 72,
                          maxHeight: 72,
                        )
                      : null,
```

- [ ] **Step 3: Run tests to verify**

Run: `flutter test test/features/community/widgets/community_story_strip_test.dart`
Expected: All tests pass (tests use `avatarUrl: null` so no network calls)

- [ ] **Step 4: Commit**

```bash
git add lib/features/community/widgets/community_story_strip.dart
git commit -m "perf(community): use CachedNetworkImageProvider in story strip avatars"
```

---

### Task 4: Compact CommunityQuickComposer to single row

**Files:**
- Modify: `lib/features/community/widgets/community_quick_composer.dart`
- Modify: `test/features/community/widgets/community_quick_composer_test.dart`

- [ ] **Step 1: Rewrite the build method to single-row layout**

Replace the entire `build` method body (lines 27-170) with a compact single-row design. Keep the same constructor signature and `_resolveInitial` method:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profile = ref.watch(userProfileProvider).value;
    final avatarUrl = profile?.avatarUrl;
    final initial = _resolveInitial(profile?.fullName, currentUserId);

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      onTap: onCreatePost,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(
                alpha: 0.12,
              ),
              foregroundImage: avatarUrl != null
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'community.quick_hint'.tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _CompactAction(
              icon: LucideIcons.image,
              onTap: () => onCreateTypedPost(CommunityPostType.photo),
            ),
            _CompactAction(
              icon: LucideIcons.helpCircle,
              onTap: () => onCreateTypedPost(CommunityPostType.question),
            ),
            _CompactAction(
              icon: LucideIcons.bookOpen,
              onTap: () => onCreateTypedPost(CommunityPostType.guide),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 2: Replace `_QuickActionButton` with compact `_CompactAction`**

Remove the `_QuickActionButton` class and replace with:

```dart
class _CompactAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CompactAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(
            icon,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Clean up imports**

Remove unused `AppColors` import if present. The `LucideIcons` and `CachedNetworkImageProvider` imports should already be there; add if missing:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
```

Remove the `CommunityPostType` import duplication — it's already exported from `community_enums.dart`.

- [ ] **Step 4: Update tests**

In `test/features/community/widgets/community_quick_composer_test.dart`:

The test `'shows content label hint'` (line 51-64) checks for `l10n('community.content_label')` which no longer exists in the compact layout. Update it to check for `l10n('community.quick_hint')`:

```dart
    testWidgets('shows placeholder hint text', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
            onCreateTypedPost: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n('community.quick_hint')), findsOneWidget);
    });
```

The test `'shows quick action shortcuts'` (line 66-81) checks for text labels that no longer exist (compact uses icon-only buttons). Replace it:

```dart
    testWidgets('shows quick action icon buttons', (tester) async {
      await tester.pumpWidget(
        wrap(
          CommunityQuickComposer(
            currentUserId: 'user-123',
            onCreatePost: () {},
            onCreateTypedPost: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.image), findsOneWidget);
      expect(find.byIcon(LucideIcons.helpCircle), findsOneWidget);
      expect(find.byIcon(LucideIcons.bookOpen), findsOneWidget);
    });
```

The test `'calls onCreatePost when hint area is tapped'` (line 83-98) taps on `l10n('community.content_label')`. Update to tap on `l10n('community.quick_hint')`:

```dart
      await tester.tap(find.text(l10n('community.quick_hint')));
```

The test `'calls typed callback for question shortcut'` (line 100-116) taps text label. Update to tap icon:

```dart
      await tester.tap(find.byIcon(LucideIcons.helpCircle));
```

Add the `LucideIcons` import to the test file:

```dart
import 'package:lucide_icons/lucide_icons.dart';
```

- [ ] **Step 5: Run tests to verify**

Run: `flutter test test/features/community/widgets/community_quick_composer_test.dart`
Expected: All 5 tests pass

- [ ] **Step 6: Commit**

```bash
git add lib/features/community/widgets/community_quick_composer.dart test/features/community/widgets/community_quick_composer_test.dart
git commit -m "refactor(community): compact quick composer to single row layout"
```

---

### Task 5: Delete CommunityFeedHero and CommunityCreatorStrip

**Files:**
- Delete: `lib/features/community/widgets/community_feed_hero.dart`
- Delete: `lib/features/community/widgets/community_creator_strip.dart`
- Delete: `test/features/community/widgets/community_creator_strip_test.dart`

- [ ] **Step 1: Delete the three files**

```bash
rm lib/features/community/widgets/community_feed_hero.dart
rm lib/features/community/widgets/community_creator_strip.dart
rm test/features/community/widgets/community_creator_strip_test.dart
```

- [ ] **Step 2: Verify no other files import them**

Run: `grep -r "community_feed_hero\|community_creator_strip\|CommunityFeedHero\|CommunityCreatorStrip\|CreatorHighlight" lib/ test/ --include="*.dart" -l`

Expected: Only `community_feed_list.dart` and `community_feed_list_test.dart` (will be fixed in Task 6)

- [ ] **Step 3: Commit deletions**

```bash
git add -A lib/features/community/widgets/community_feed_hero.dart lib/features/community/widgets/community_creator_strip.dart test/features/community/widgets/community_creator_strip_test.dart
git commit -m "refactor(community): remove FeedHero and CreatorStrip widgets"
```

---

### Task 6: Update CommunityFeedList — remove hero/creator slivers, update order

**Files:**
- Modify: `lib/features/community/widgets/community_feed_list.dart`
- Modify: `test/features/community/widgets/community_feed_list_test.dart`

- [ ] **Step 1: Remove imports for deleted widgets**

Remove these import lines:

```dart
import 'community_creator_strip.dart';
import 'community_feed_hero.dart';
```

- [ ] **Step 2: Update the slivers in the build method**

In the `build` method, remove the `CommunityFeedHero` sliver (lines 91-99), the `CommunityCreatorStrip` sliver (lines 142-152), and reorder. The new sliver list should be:

```dart
        slivers: [
          // 1. Quick Composer
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: CommunityQuickComposer(
                currentUserId: currentUserId,
                onCreatePost: () =>
                    context.push(_buildCreatePostRoute(defaultCreateType)),
                onCreateTypedPost: (type) =>
                    context.push(_buildCreatePostRoute(type)),
              ),
            ),
          ),
          // 2. Story Strip (explore only)
          if (isExplore && showExploreExtras)
            SliverToBoxAdapter(
              child: CommunityStoryStrip(
                stories: CommunityStoryStrip.fromPosts(visiblePosts),
                onCreatePost: () =>
                    context.push(_buildCreatePostRoute(defaultCreateType)),
              ),
            ),
          // 3. Section Bar
          if (visiblePosts.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: CommunitySectionBar(
                  tab: widget.tab,
                  visibleCount: visiblePosts.length,
                  exploreSort: exploreSort,
                  onExploreSortChanged: _changeSort,
                ),
              ),
            ),
          // 4. Empty states or post list (same as before)
          if (!feedState.isLoading && posts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxxl * 2,
                ),
                child: EmptyState(
                  icon: const AppIcon(AppIcons.community),
                  title: 'community.no_posts'.tr(),
                  subtitle: 'community.no_posts_hint'.tr(),
                  actionLabel: 'community.create_post'.tr(),
                  onAction: () => context.push(AppRoutes.communityCreatePost),
                ),
              ),
            )
          else if (!feedState.isLoading && visiblePosts.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                ),
                child: _FilteredFeedEmptyState(
                  tab: widget.tab,
                  onReset: widget.tab == CommunityFeedTab.explore
                      ? null
                      : () => context.go(AppRoutes.community),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xxxl * 2,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= visiblePosts.length) {
                      if (feedState.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return const SizedBox.shrink();
                    }
                    final post = visiblePosts[index];
                    return CommunityPostCard(
                      key: ValueKey(post.id),
                      post: post,
                    );
                  },
                  childCount: visiblePosts.length + (feedState.hasMore ? 1 : 0),
                ),
              ),
            ),
        ],
```

- [ ] **Step 3: Remove `showExploreExtras` dependency on `visiblePosts.isNotEmpty` if needed**

The existing line `final showExploreExtras = isExplore && visiblePosts.isNotEmpty;` is still correct — Story Strip should only show when there are posts to derive stories from. Keep this line.

- [ ] **Step 4: Update feed list test**

In `test/features/community/widgets/community_feed_list_test.dart`, the first test (line 31-73) checks for `l10n('community.hero_explore_title')`, `l10n('community.bookmarks')`, and `l10n('community.top_creators')`. These no longer exist. Replace the test:

```dart
    testWidgets('shows explore sort controls and story strip', (
      tester,
    ) async {
      final posts = [
        CommunityPost(
          id: '1',
          userId: 'u1',
          username: 'Alpha Loft',
          content: 'First post',
          likeCount: 8,
          commentCount: 3,
          createdAt: DateTime(2026, 3, 5, 10),
        ),
        CommunityPost(
          id: '2',
          userId: 'u2',
          username: 'Blue Sky',
          content: 'Photo post',
          imageUrl: 'https://example.com/photo.jpg',
          likeCount: 5,
          commentCount: 1,
          createdAt: DateTime(2026, 3, 5, 9),
        ),
      ];

      await tester.pumpWidget(
        createSubject(
          feedState: FeedState(posts: posts, isLoading: false, hasMore: false),
        ),
      );
      await tester.pumpAndSettle();

      // Quick composer hint visible
      expect(find.text(l10n('community.quick_hint')), findsOneWidget);
      // Story strip title visible
      expect(find.text(l10n('community.stories_title')), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Sort controls visible
      expect(find.text(l10n('community.sort_newest')), findsOneWidget);
      expect(find.text(l10n('community.sort_trending')), findsOneWidget);
      // Post content visible
      expect(find.text('Alpha Loft'), findsWidgets);
    });
```

- [ ] **Step 5: Run tests to verify**

Run: `flutter test test/features/community/widgets/community_feed_list_test.dart`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add lib/features/community/widgets/community_feed_list.dart test/features/community/widgets/community_feed_list_test.dart
git commit -m "refactor(community): remove hero/creator slivers from feed list, reorder layout"
```

---

### Task 7: Replace feed skeleton with SkeletonLoader shimmer

**Files:**
- Modify: `lib/features/community/widgets/community_feed_list.dart` (the `_CommunityFeedSkeleton` class, lines 243-290)

- [ ] **Step 1: Add SkeletonLoader import**

Add at the top of the file:

```dart
import '../../../core/widgets/skeleton_loader.dart';
```

- [ ] **Step 2: Replace `_CommunityFeedSkeleton` build content**

Replace the entire build method of `_CommunityFeedSkeleton` (keep the class and key):

```dart
class _CommunityFeedSkeleton extends StatelessWidget {
  const _CommunityFeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('community_feed_skeleton'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        // Compact composer skeleton
        const SkeletonLoader(height: 48, borderRadius: AppSpacing.radiusXl),
        const SizedBox(height: AppSpacing.lg),
        // Post card skeletons (x3)
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar row
                Row(
                  children: [
                    const SkeletonLoader(
                      width: 36,
                      height: 36,
                      borderRadius: AppSpacing.radiusFull,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLoader(width: 120, height: 14),
                        SizedBox(height: AppSpacing.xs),
                        SkeletonLoader(width: 80, height: 10),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Content lines
                const SkeletonLoader(height: 14),
                const SizedBox(height: AppSpacing.sm),
                const SkeletonLoader(width: 240, height: 14),
                const SizedBox(height: AppSpacing.md),
                // Image placeholder
                const SkeletonLoader(
                  height: 160,
                  borderRadius: AppSpacing.radiusLg,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Run tests to verify**

Run: `flutter test test/features/community/widgets/community_feed_list_test.dart`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add lib/features/community/widgets/community_feed_list.dart
git commit -m "fix(community): replace plain skeleton boxes with SkeletonLoader shimmer"
```

---

### Task 8: Clean up community_screen.dart imports

**Files:**
- Modify: `lib/features/community/screens/community_screen.dart`

- [ ] **Step 1: Verify no references to deleted widgets remain**

The community screen does not directly import `community_feed_hero.dart` or `community_creator_strip.dart` (these were only used in `community_feed_list.dart`). But verify imports are clean. No code changes should be needed here.

Run: `grep -n "feed_hero\|creator_strip" lib/features/community/screens/community_screen.dart`
Expected: No matches

- [ ] **Step 2: Run the full community test suite**

Run: `flutter test test/features/community/`
Expected: All tests pass

- [ ] **Step 3: Commit if any cleanup was needed**

Only commit if changes were made. Otherwise skip to Task 9.

---

### Task 9: Run static analysis and final verification

**Files:** None (verification only)

- [ ] **Step 1: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors related to community files

- [ ] **Step 2: Run code quality script**

Run: `python3 scripts/verify_code_quality.py`
Expected: No new violations. The emoji anti-pattern should no longer be flagged.

- [ ] **Step 3: Run full community test suite one more time**

Run: `flutter test test/features/community/`
Expected: All tests pass

- [ ] **Step 4: Final commit if any fixups needed**

If analysis found issues, fix and commit:

```bash
git add -A
git commit -m "fix(community): address analysis warnings from community improvements"
```
