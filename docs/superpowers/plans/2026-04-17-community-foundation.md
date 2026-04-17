# Community Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the structural foundation of `lib/features/community/` — codify naming exemption, split two oversized files by responsibility, remove a re-export shim, sweep anti-patterns. Behavior-neutral.

**Architecture:** All changes are structural. No runtime behavior change. Each commit is independently revertable. Existing community tests continue to pass. No new l10n keys. No DB or RLS changes.

**Tech Stack:** Flutter 3.41+ / Dart 3.8+ / Riverpod 3 / `flutter_test` / `mocktail`. Quality scripts in Python 3.

**Spec:** `docs/superpowers/specs/2026-04-17-community-foundation-design.md`

---

## Task 1: Add online-first exemption taxonomy to architecture rules

**Files:**
- Modify: `.claude/rules/architecture.md`
- Modify: `.claude/rules/data-layer.md`

- [ ] **Step 1: Add exemption subsection to architecture.md**

Open `.claude/rules/architecture.md`. Find the `## Import Rules` section. After that section and before the next `##` heading, insert:

```markdown
## Online-First Exemption

A class named `*Repository` MUST be offline-first (Drift table + DAO + `SyncMetadata` entry) UNLESS it serves a **cross-user public feed or realtime multi-party stream** where the server is the source of truth by design and a local mirror would not improve UX.

Exempt classes MUST declare the exemption in the first doc block:

\`\`\`dart
/// Online-first: <reason>. No local Drift mirror by design.
\`\`\`

Currently exempt:
- `CommunityPostRepository` — cross-user public feed, chronological
- `MessagingRepository` — realtime multi-party conversations

Online-only classes that are NOT cross-user/multi-party streams (e.g. a single-user remote-only resource) MUST use `*RemoteService` or `*OnlineSource` naming instead of `*Repository`.
```

- [ ] **Step 2: Cross-reference exemption from data-layer.md**

Open `.claude/rules/data-layer.md`. Find the `### Offline-First Classification (mandatory)` subsection. Replace the paragraph:

```
Audit-flagged offenders needing rename or offline-first implementation: `messaging_repository.dart`, `community_post_repository.dart`, `marketplace_listing_remote_source.dart`.
```

with:

```
Audit-flagged offender needing rename or offline-first implementation: none currently. `messaging_repository.dart` and `community_post_repository.dart` are exempt under the online-first rule (see architecture.md § Online-First Exemption — cross-user feeds). `marketplace_listing_remote_source.dart` already uses the correct `*RemoteSource` naming.
```

- [ ] **Step 3: Verify markdown renders correctly**

Run: `grep -n "Online-First Exemption" .claude/rules/architecture.md`
Expected: one match.

Run: `grep -n "Online-First Exemption" .claude/rules/data-layer.md`
Expected: one match (the cross-reference).

- [ ] **Step 4: Commit**

```bash
git add .claude/rules/architecture.md .claude/rules/data-layer.md
git commit -m "$(cat <<'EOF'
docs(rules): add online-first exemption taxonomy

Codify that *Repository classes serving cross-user feeds or realtime
multi-party streams are exempt from offline-first naming when a local
Drift mirror would not improve UX. Cross-reference from data-layer.md
and remove stale audit-flagged items.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Normalize exempt repository docstrings

**Files:**
- Modify: `lib/data/repositories/community_post_repository.dart:10-15`
- Modify: `lib/data/repositories/messaging_repository.dart:12-16`

- [ ] **Step 1: Update CommunityPostRepository docstring**

Open `lib/data/repositories/community_post_repository.dart`. Replace the existing doc block on lines 10–15 (currently):

```dart
/// Repository for community posts.
///
/// Custom implementation (not extending [BaseRepository]) because community
/// is online-first with no Drift mirror, and queries cross user boundaries.
/// An optional [CommunityPostCache] reduces redundant Supabase requests for
/// feed and single-post lookups.
```

with:

```dart
/// Online-first: cross-user public community feed. No local Drift mirror by design.
///
/// Exempt from offline-first naming (see `.claude/rules/architecture.md`
/// § Online-First Exemption). Custom implementation (does not extend
/// [BaseRepository]) because queries cross user boundaries and a local
/// mirror would not improve UX for a chronological public feed. An
/// optional [CommunityPostCache] reduces redundant Supabase requests for
/// feed and single-post lookups.
```

- [ ] **Step 2: Update MessagingRepository docstring**

Open `lib/data/repositories/messaging_repository.dart`. Replace the existing doc block on lines 12–16 (currently):

```dart
/// Repository for messaging conversations and messages.
///
/// Custom implementation (not extending [BaseRepository]) because messaging
/// is online-first with realtime subscriptions and no Drift mirror — messages
/// live only on Supabase and cross user boundaries (multi-party conversations).
```

with:

```dart
/// Online-first: realtime multi-party conversations. No local Drift mirror by design.
///
/// Exempt from offline-first naming (see `.claude/rules/architecture.md`
/// § Online-First Exemption). Custom implementation (does not extend
/// [BaseRepository]) because messages live only on Supabase with realtime
/// subscriptions and cross user boundaries.
```

- [ ] **Step 3: Verify analyzer still passes**

Run: `flutter analyze --no-fatal-infos lib/data/repositories/community_post_repository.dart lib/data/repositories/messaging_repository.dart`
Expected: `No issues found!` (or no new errors).

- [ ] **Step 4: Commit**

```bash
git add lib/data/repositories/community_post_repository.dart lib/data/repositories/messaging_repository.dart
git commit -m "$(cat <<'EOF'
docs(data): normalize exempt repository docstrings

Declare online-first exemption in the first doc block of
CommunityPostRepository and MessagingRepository per the new rule
in architecture.md. No behavior change.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Remove `community_moderation_providers` re-export shim

**Files:**
- Delete: `lib/features/community/providers/community_moderation_providers.dart`
- Modify: `lib/features/community/providers/community_create_providers.dart:18`
- Modify: `lib/features/community/providers/community_comment_providers.dart:11`
- Modify: `test/features/community/providers/community_moderation_providers_test.dart` (delete)
- Modify: `test/features/marketplace/providers/marketplace_form_providers_test.dart:14`
- Modify: `test/features/messaging/providers/messaging_form_providers_test.dart:11`

The file is a 3-line re-export of `domain/services/moderation/moderation_providers.dart`. Replace all imports with direct imports and delete the shim.

- [ ] **Step 1: Verify the shim target exists**

Run: `test -f lib/domain/services/moderation/moderation_providers.dart && echo OK`
Expected: `OK`.

- [ ] **Step 2: Find every importer**

Run: `grep -rn "community_moderation_providers" lib/ test/`
Expected output (5 lines):

```
lib/features/community/providers/community_create_providers.dart:18:import 'community_moderation_providers.dart';
lib/features/community/providers/community_comment_providers.dart:11:import 'community_moderation_providers.dart';
test/features/community/providers/community_moderation_providers_test.dart:...
test/features/marketplace/providers/marketplace_form_providers_test.dart:14:...
test/features/messaging/providers/messaging_form_providers_test.dart:11:...
```

If the output differs (more or fewer matches), stop and reconcile before continuing.

- [ ] **Step 3: Update `community_create_providers.dart`**

In `lib/features/community/providers/community_create_providers.dart` line 18, replace:

```dart
import 'community_moderation_providers.dart';
```

with:

```dart
import '../../../domain/services/moderation/moderation_providers.dart';
```

- [ ] **Step 4: Update `community_comment_providers.dart`**

In `lib/features/community/providers/community_comment_providers.dart` line 11, replace:

```dart
import 'community_moderation_providers.dart';
```

with:

```dart
import '../../../domain/services/moderation/moderation_providers.dart';
```

- [ ] **Step 5: Update `marketplace_form_providers_test.dart`**

In `test/features/marketplace/providers/marketplace_form_providers_test.dart` line 14, replace:

```dart
import 'package:budgie_breeding_tracker/features/community/providers/community_moderation_providers.dart';
```

with:

```dart
import 'package:budgie_breeding_tracker/domain/services/moderation/moderation_providers.dart';
```

- [ ] **Step 6: Update `messaging_form_providers_test.dart`**

In `test/features/messaging/providers/messaging_form_providers_test.dart` line 11, apply the same replacement as Step 5.

- [ ] **Step 7: Delete the shim-specific test**

The file `test/features/community/providers/community_moderation_providers_test.dart` only tests the re-export. Delete it:

```bash
git rm test/features/community/providers/community_moderation_providers_test.dart
```

- [ ] **Step 8: Delete the shim**

```bash
git rm lib/features/community/providers/community_moderation_providers.dart
```

- [ ] **Step 9: Verify no stragglers**

Run: `grep -rn "community_moderation_providers" lib/ test/`
Expected: no output.

- [ ] **Step 10: Analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: no errors (warnings/infos ok if pre-existing).

- [ ] **Step 11: Run affected tests**

Run: `flutter test test/features/community/providers/ test/features/marketplace/providers/marketplace_form_providers_test.dart test/features/messaging/providers/messaging_form_providers_test.dart`
Expected: all pass.

- [ ] **Step 12: Commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore(community): remove moderation providers re-export shim

The shim just re-exported domain/services/moderation/moderation_providers.
Point the 4 importers (2 lib, 2 test) at the domain module directly and
remove the stale shim + its pass-through test.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Split `community_post_card.dart` — extract body into new widget

**Files:**
- Modify: `lib/features/community/widgets/community_post_card.dart` (394 → ~170 lines)
- Create: `lib/features/community/widgets/community_post_card_body.dart` (~230 lines)
- Modify: `test/features/community/widgets/community_post_card_test.dart` (add smoke test for extracted body)

The card's inner `cardChild` Column (header padding block + media gallery + actions padding block) and the private `_GuideLeadBlock` widget move to a new file. The composition root keeps the `Card`/`InkWell` wrapper, handlers (`_handleDelete`, `_handleReport`, `_handleBlock`, `_handleSendMessage`, `_openImageViewer`), and lifecycle. The body widget receives callbacks as parameters — no `ref` in the body.

- [ ] **Step 1: Run existing test to establish baseline**

Run: `flutter test test/features/community/widgets/community_post_card_test.dart`
Expected: all pass. Record the output.

- [ ] **Step 2: Create `community_post_card_body.dart` with `_GuideLeadBlock` moved**

Create `lib/features/community/widgets/community_post_card_body.dart` with this content:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/community_post_model.dart';
import 'community_media_gallery.dart';
import 'community_post_actions.dart';
import 'community_post_card_parts.dart';
import 'community_user_header.dart';

/// Visual body of a community post card.
///
/// Stateless composition of user header, optional guide lead block,
/// title/type badge, content text, bird link chip, tag wrap, media
/// gallery, action bar and engagement summary. Accepts all interaction
/// callbacks from the parent [CommunityPostCard] — has no ref access.
class CommunityPostCardBody extends StatelessWidget {
  const CommunityPostCardBody({
    super.key,
    required this.post,
    required this.showFullContent,
    required this.maxContentLines,
    required this.isOwnPost,
    required this.currentUserId,
    required this.onDelete,
    required this.onReport,
    required this.onBlock,
    required this.onSendMessage,
    required this.onFollowToggle,
    required this.onDoubleTapMedia,
    required this.onOpenImage,
  });

  final CommunityPost post;
  final bool showFullContent;
  final int maxContentLines;
  final bool isOwnPost;
  final String currentUserId;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;
  final VoidCallback? onSendMessage;
  final VoidCallback? onFollowToggle;
  final VoidCallback onDoubleTapMedia;
  final ValueChanged<String> onOpenImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEngagement = post.likeCount > 0 || post.commentCount > 0;
    final allImages = post.allImageUrls;
    final isGuide = post.postType == CommunityPostType.guide;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityUserHeader(
                userId: post.userId,
                username: post.username,
                avatarUrl: post.avatarUrl,
                createdAt: post.createdAt ?? DateTime.now(),
                isOwnPost: isOwnPost,
                isFollowing: post.isFollowingAuthor,
                onDelete: onDelete,
                onReport: onReport,
                onBlock: onBlock,
                onSendMessage: onSendMessage,
                onFollowToggle: onFollowToggle,
                postType: post.postType,
              ),
              if (isGuide) ...[
                const SizedBox(height: AppSpacing.md),
                _GuideLeadBlock(post: post),
              ] else if (post.postType != CommunityPostType.general ||
                  post.title != null) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (post.postType != CommunityPostType.general &&
                        post.postType != CommunityPostType.unknown)
                      PostTypeBadge(postType: post.postType),
                    if (post.title != null)
                      Text(
                        post.title!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
              if (post.content.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ContentText(
                  content: post.content,
                  showFull: showFullContent,
                  maxLines: maxContentLines,
                ),
              ],
              if (post.birdId != null) ...[
                const SizedBox(height: AppSpacing.md),
                BirdLinkChip(post: post),
              ],
              if (post.mutationTags.isNotEmpty || post.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                PostTagWrap(post: post),
              ],
            ],
          ),
        ),
        if (allImages.isNotEmpty)
          CommunityMediaGallery(
            imageUrls: allImages,
            onDoubleTap: onDoubleTapMedia,
            onOpenImage: onOpenImage,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommunityPostActions(post: post),
              if (hasEngagement) ...[
                const SizedBox(height: AppSpacing.md),
                EngagementSummary(post: post),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GuideLeadBlock extends StatelessWidget {
  const _GuideLeadBlock({required this.post});

  final CommunityPost post;

  int get _estimatedReadMinutes {
    final text = [if (post.title != null) post.title!, post.content].join(' ');
    final wordCount = text
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .length;
    final minutes = (wordCount / 180).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.12),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  'community.tab_guides'.tr(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  ),
                ),
                child: Text(
                  'community.guide_read_time'.tr(
                    args: ['$_estimatedReadMinutes'],
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (post.title != null && post.title!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.title!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
          ],
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  LucideIcons.bookOpen,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'community.guide_open_hint'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Replace `community_post_card.dart` with slim composition root**

Overwrite `lib/features/community/widgets/community_post_card.dart` with:

```dart
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/enums/community_enums.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../data/models/community_post_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../router/route_names.dart';
import '../../messaging/providers/messaging_form_providers.dart';
import '../providers/community_feed_providers.dart';
import '../providers/community_post_providers.dart';
import 'community_image_viewer.dart';
import 'community_post_card_body.dart';
import 'community_report_sheet.dart';

/// Card widget displaying a single community post with full interaction.
///
/// Composition root. Owns handlers for delete/report/block/DM and the
/// outer [Card] + [InkWell] wrapper. Visual layout lives in
/// [CommunityPostCardBody].
class CommunityPostCard extends ConsumerStatefulWidget {
  static const interactionKey = ValueKey('community_post_card_interaction');
  final CommunityPost post;
  final bool showFullContent;
  final bool isInteractive;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.showFullContent = false,
    this.isInteractive = true,
  });

  static const _maxContentLines = 3;

  @override
  ConsumerState<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends ConsumerState<CommunityPostCard> {
  CommunityPost get post => widget.post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwnPost = post.userId == currentUserId;
    final isGuide = post.postType == CommunityPostType.guide;

    final cardChild = CommunityPostCardBody(
      post: post,
      showFullContent: widget.showFullContent,
      maxContentLines: CommunityPostCard._maxContentLines,
      isOwnPost: isOwnPost,
      currentUserId: currentUserId,
      onDelete: isOwnPost ? _handleDelete : null,
      onReport: isOwnPost ? null : _handleReport,
      onBlock: isOwnPost ? null : _handleBlock,
      onSendMessage: (!isOwnPost && currentUserId != 'anonymous')
          ? _handleSendMessage
          : null,
      onFollowToggle: isOwnPost
          ? null
          : () => ref
              .read(followToggleProvider.notifier)
              .toggleFollow(post.userId),
      onDoubleTapMedia: () {
        AppHaptics.mediumImpact();
        ref.read(likeToggleProvider.notifier).toggleLike(post.id);
      },
      onOpenImage: _openImageViewer,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      color: isGuide
          ? theme.colorScheme.surfaceContainerLowest
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: BorderSide(
          color: isGuide
              ? theme.colorScheme.primary.withValues(alpha: 0.22)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.22),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.isInteractive
          ? InkWell(
              key: CommunityPostCard.interactionKey,
              onTap: () => context.push(
                AppRoutes.communityPostDetail.replaceFirst(':postId', post.id),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              child: cardChild,
            )
          : cardChild,
    );
  }

  Future<void> _handleDelete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'community.delete_post'.tr(),
      message: 'community.confirm_delete_post'.tr(),
      confirmLabel: 'common.delete'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    ref.read(postDeleteProvider.notifier).deletePost(post.id);
  }

  Future<void> _handleReport() async {
    final reason = await showCommunityReportSheet(
      context,
      title: 'community.report_post'.tr(),
    );
    if (reason == null || !mounted) return;
    try {
      final userId = ref.read(currentUserIdProvider);
      final repo = ref.read(communitySocialRepositoryProvider);
      await repo.reportContent(
        userId: userId,
        targetId: post.id,
        targetType: 'post',
        reason: reason,
      );
      ref.read(communityFeedProvider.notifier).removePost(post.id);
      if (mounted) {
        ActionFeedbackService.show('community.report_submitted'.tr());
      }
    } catch (e, st) {
      AppLogger.error('CommunityPostCard._handleReport', e, st);
      Sentry.captureException(e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('community.report_error'.tr())));
      }
    }
  }

  Future<void> _handleBlock() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'community.block_user_confirm'.tr(),
      message: 'community.block_user_hint'.tr(args: [post.username]),
      confirmLabel: 'community.block_user'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    await ref.read(blockedUsersProvider.notifier).block(post.userId);
    if (mounted) {
      ActionFeedbackService.show('community.user_blocked'.tr());
    }
  }

  Future<void> _handleSendMessage() async {
    final userId = ref.read(currentUserIdProvider);
    final conversationId = await ref
        .read(messagingFormStateProvider.notifier)
        .startDirectConversation(userId1: userId, userId2: post.userId);
    if (!mounted || conversationId == null) return;
    ref.read(messagingFormStateProvider.notifier).reset();
    context.push('${AppRoutes.messages}/$conversationId');
  }

  void _openImageViewer(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommunityImageViewer(imageUrl: imageUrl),
      ),
    );
  }
}
```

- [ ] **Step 4: Verify imports are tidy**

Run: `dart fix --apply lib/features/community/widgets/community_post_card.dart lib/features/community/widgets/community_post_card_body.dart`
Expected: "Applied N fixes" or "Nothing to fix".

- [ ] **Step 5: Analyze**

Run: `flutter analyze --no-fatal-infos lib/features/community/`
Expected: 0 errors, no new warnings.

- [ ] **Step 6: Run existing card test**

Run: `flutter test test/features/community/widgets/community_post_card_test.dart test/features/community/widgets/community_post_card_dialog_test.dart test/features/community/widgets/community_post_card_parts_test.dart`
Expected: same number of passes as Step 1 baseline. If any fail, compare against baseline — a failure means the split changed behavior and must be reconciled before commit.

- [ ] **Step 7: Add body smoke test**

Create `test/features/community/widgets/community_post_card_body_test.dart`:

```dart
import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_post_card_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_helpers.dart';

CommunityPost _post({
  CommunityPostType postType = CommunityPostType.general,
  String content = 'Hello budgies',
  String? title,
  List<String> imageUrls = const [],
}) => CommunityPost(
      id: 'p1',
      userId: 'u1',
      username: 'alice',
      avatarUrl: null,
      content: content,
      title: title,
      postType: postType,
      createdAt: DateTime(2026, 4, 17),
      likeCount: 0,
      commentCount: 0,
      isLikedByCurrentUser: false,
      isFollowingAuthor: false,
      imageUrls: imageUrls,
      mutationTags: const [],
      tags: const [],
    );

void main() {
  group('CommunityPostCardBody', () {
    testWidgets('renders post content', (tester) async {
      await pumpWidgetSimple(
        tester,
        CommunityPostCardBody(
          post: _post(content: 'The canary sings'),
          showFullContent: false,
          maxContentLines: 3,
          isOwnPost: false,
          currentUserId: 'u2',
          onDelete: null,
          onReport: () {},
          onBlock: () {},
          onSendMessage: () {},
          onFollowToggle: () {},
          onDoubleTapMedia: () {},
          onOpenImage: (_) {},
        ),
      );
      expect(find.textContaining('canary'), findsOneWidget);
    });

    testWidgets('renders guide lead block for guide type', (tester) async {
      await pumpWidgetSimple(
        tester,
        CommunityPostCardBody(
          post: _post(postType: CommunityPostType.guide, title: 'Guide'),
          showFullContent: false,
          maxContentLines: 3,
          isOwnPost: false,
          currentUserId: 'u2',
          onDelete: null,
          onReport: () {},
          onBlock: () {},
          onSendMessage: () {},
          onFollowToggle: () {},
          onDoubleTapMedia: () {},
          onOpenImage: (_) {},
        ),
      );
      // Guide lead block shows the guide tab label
      expect(find.textContaining('Guide', findRichText: true), findsWidgets);
    });
  });
}
```

**Note on `_post(...)`:** the field list matches `CommunityPost`'s required fields as of this commit. If `CommunityPost` has different required fields in the codebase, adapt the fixture — do not change the model.

- [ ] **Step 8: Run body smoke test**

Run: `flutter test test/features/community/widgets/community_post_card_body_test.dart`
Expected: both tests pass.

- [ ] **Step 9: Verify line count targets**

Run: `wc -l lib/features/community/widgets/community_post_card.dart lib/features/community/widgets/community_post_card_body.dart`
Expected: `community_post_card.dart` < 200; `community_post_card_body.dart` ≤ 260.

- [ ] **Step 10: Commit**

```bash
git add lib/features/community/widgets/community_post_card.dart \
        lib/features/community/widgets/community_post_card_body.dart \
        test/features/community/widgets/community_post_card_body_test.dart
git commit -m "$(cat <<'EOF'
refactor(community): split post card composition from body

Extract the visual Column (header + guide lead + title + content +
media + actions) and the _GuideLeadBlock helper into a new stateless
CommunityPostCardBody. The composition root keeps handlers, lifecycle,
and the Card/InkWell wrapper; body takes callbacks and has no ref.
Card drops from 394 to ~170 lines. Smoke test added for the body.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Extract reason-list constants from `community_report_sheet.dart`

**Files:**
- Create: `lib/features/community/widgets/community_report_reasons.dart` (~70 lines)
- Modify: `lib/features/community/widgets/community_report_sheet.dart` (302 → ~230 lines)

Move the `_reasons` list and the three switch-based helpers (`_iconFor`, `_titleFor`, `_hintFor`) into a top-level helper module so the sheet file concentrates on UI + form state.

- [ ] **Step 1: Baseline test**

Run: `flutter test test/features/community/widgets/community_report_sheet_test.dart`
Expected: all pass. Record the output.

- [ ] **Step 2: Create `community_report_reasons.dart`**

Create `lib/features/community/widgets/community_report_reasons.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/community_enums.dart';

/// Ordered list of user-selectable report reasons shown in
/// [showCommunityReportSheet]. `unknown` is intentionally excluded —
/// it is a deserialization fallback, not a user choice.
const List<CommunityReportReason> kCommunityReportReasons = [
  CommunityReportReason.spam,
  CommunityReportReason.harassment,
  CommunityReportReason.inappropriate,
  CommunityReportReason.misinformation,
  CommunityReportReason.other,
];

/// Icon mapping for a report reason. `unknown` falls back to a help icon
/// even though it never appears in the UI list.
IconData iconForReportReason(CommunityReportReason reason) => switch (reason) {
      CommunityReportReason.spam => LucideIcons.mailWarning,
      CommunityReportReason.harassment => LucideIcons.shieldAlert,
      CommunityReportReason.inappropriate => LucideIcons.eyeOff,
      CommunityReportReason.misinformation => LucideIcons.alertCircle,
      CommunityReportReason.other => LucideIcons.messageCircle,
      CommunityReportReason.unknown => LucideIcons.helpCircle,
    };

/// Localized title key mapping for a report reason.
String titleForReportReason(CommunityReportReason reason) => switch (reason) {
      CommunityReportReason.spam => 'community.report_reason_spam'.tr(),
      CommunityReportReason.harassment =>
        'community.report_reason_harassment'.tr(),
      CommunityReportReason.inappropriate =>
        'community.report_reason_inappropriate'.tr(),
      CommunityReportReason.misinformation =>
        'community.report_reason_misinformation'.tr(),
      CommunityReportReason.other => 'community.report_reason_other'.tr(),
      CommunityReportReason.unknown => '',
    };

/// Localized hint key mapping for a report reason.
String hintForReportReason(CommunityReportReason reason) => switch (reason) {
      CommunityReportReason.spam => 'community.report_spam_hint'.tr(),
      CommunityReportReason.harassment =>
        'community.report_harassment_hint'.tr(),
      CommunityReportReason.inappropriate =>
        'community.report_inappropriate_hint'.tr(),
      CommunityReportReason.misinformation =>
        'community.report_misinformation_hint'.tr(),
      CommunityReportReason.other => 'community.report_other_hint'.tr(),
      CommunityReportReason.unknown => '',
    };
```

- [ ] **Step 3: Update `community_report_sheet.dart` to consume the new module**

In `lib/features/community/widgets/community_report_sheet.dart`:

3a. Add import after the existing imports (alphabetical order):

```dart
import 'community_report_reasons.dart';
```

3b. Delete the local `static const _reasons = [...]` list (lines 39–45 in the current file).

3c. Delete the three helper methods `_iconFor`, `_titleFor`, `_hintFor` (lines 53–88 in the current file) from `_CommunityReportSheetState`.

3d. In the build method, replace the `..._reasons.map((reason) => _ReasonCard(...))` spread (around line 151) with:

```dart
...kCommunityReportReasons.map((reason) => _ReasonCard(
      icon: iconForReportReason(reason),
      title: titleForReportReason(reason),
      hint: hintForReportReason(reason),
      isSelected: _selected == reason,
      onTap: () => _onTapReason(reason),
    )),
```

- [ ] **Step 4: Analyze**

Run: `flutter analyze --no-fatal-infos lib/features/community/widgets/community_report_sheet.dart lib/features/community/widgets/community_report_reasons.dart`
Expected: 0 errors.

- [ ] **Step 5: Run existing report sheet test**

Run: `flutter test test/features/community/widgets/community_report_sheet_test.dart`
Expected: same pass count as Step 1 baseline.

- [ ] **Step 6: Line count check**

Run: `wc -l lib/features/community/widgets/community_report_sheet.dart lib/features/community/widgets/community_report_reasons.dart`
Expected: `community_report_sheet.dart` ≤ 240; `community_report_reasons.dart` ≤ 80.

- [ ] **Step 7: Commit**

```bash
git add lib/features/community/widgets/community_report_sheet.dart \
        lib/features/community/widgets/community_report_reasons.dart
git commit -m "$(cat <<'EOF'
refactor(community): extract report reason constants

Move the reason list and icon/title/hint mappings out of the sheet
into a dedicated community_report_reasons.dart. Sheet now focuses on
UI + form state; mappings are reusable.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Anti-pattern sweep — triage

**Files:** (to be determined by scan output)

- [ ] **Step 1: Run the quality scanner**

Run: `python3 scripts/verify_code_quality.py 2>&1 | tee /tmp/community_quality.txt`
Expected: exits non-zero if violations present, zero otherwise.

- [ ] **Step 2: Filter to community/**

Run: `grep "lib/features/community/" /tmp/community_quality.txt > /tmp/community_violations.txt ; cat /tmp/community_violations.txt`
Expected: either empty (no violations — skip to Task 7) or a list grouped implicitly by violation type.

- [ ] **Step 3: Categorize**

For each unique violation category in the filtered output (e.g. "withOpacity", "ref.watch in callback", "hardcoded color", "context.go in forward nav"), note the count and list of file:line references. Record in a scratch file:

```
categories = {
  "withOpacity": [file1:line, file2:line, ...],
  "ref_watch_callback": [...],
  ...
}
```

- [ ] **Step 4: Decide scope per category**

For each category:
- If the fix is a mechanical replacement (e.g. `withOpacity(x)` → `withValues(alpha: x)`): **include** in the sweep.
- If the fix requires a new l10n key (hardcoded text where no existing key applies): **defer** — out of scope for this spec. Record deferred items in the final commit message so Sub-project 3 picks them up.
- If the fix requires behavior change (e.g. changing a `context.go` to `context.push` alters navigation stack semantics and a caller relies on stack replacement): **pause and ask** — do not auto-apply.

- [ ] **Step 5: Record the plan**

Write a short note `/tmp/community_sweep_plan.md` listing, per category to fix: the commit message subject, file list, and the mechanical change. This note guides Tasks 7a–7n.

---

## Task 7: Anti-pattern sweep — apply fixes (one category per commit)

For each category decided in Task 6 Step 4, follow this template. Repeat until `/tmp/community_violations.txt` is empty (re-run after every commit).

- [ ] **Step 1: Re-run scanner to confirm the category still has violations**

Run: `python3 scripts/verify_code_quality.py 2>&1 | grep "lib/features/community/" | grep <category-marker>`
Expected: at least one line.

- [ ] **Step 2: Apply the mechanical change across the category**

Example for `withOpacity`:
- For each reported `file:line`, open the file and replace `.withOpacity(<expr>)` with `.withValues(alpha: <expr>)`.

Example for `ref.watch` in callback:
- For each reported location, change `ref.watch(...)` inside a `onPressed`/`onTap`/`onChanged`/`onSubmitted` callback to `ref.read(...)`.

Example for `print`:
- For each reported location, replace `print(x)` with `AppLogger.debug('<ClassName>', x)` and add `import '.../core/utils/logger.dart';` if missing.

Do one category per pass. Do NOT mix categories in one commit.

- [ ] **Step 3: Analyze**

Run: `flutter analyze --no-fatal-infos lib/features/community/`
Expected: 0 errors.

- [ ] **Step 4: Re-run scanner for this category**

Run: `python3 scripts/verify_code_quality.py 2>&1 | grep "lib/features/community/" | grep <category-marker>`
Expected: no output.

- [ ] **Step 5: Run affected community tests**

Run: `flutter test test/features/community/`
Expected: all pass.

- [ ] **Step 6: Commit with category-specific subject**

Use subject of the form: `chore(community): sweep <category> anti-pattern`.

Example:

```bash
git add lib/features/community/
git commit -m "$(cat <<'EOF'
chore(community): sweep withOpacity anti-pattern

Replace deprecated .withOpacity(x) with .withValues(alpha: x) across
community widgets. No behavior change.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 7: Loop**

Go back to Task 7 Step 1 with the next category. When all categories are clean, continue to Task 8.

---

## Task 8: Final verification gate

- [ ] **Step 1: Analyzer clean**

Run: `flutter analyze --no-fatal-infos`
Expected: `No issues found!` (or same pre-existing infos as before this plan started — no new errors/warnings introduced).

- [ ] **Step 2: Anti-pattern scan clean (community scope)**

Run: `python3 scripts/verify_code_quality.py 2>&1 | grep "lib/features/community/" || echo CLEAN`
Expected: `CLEAN`.

- [ ] **Step 3: Repo-wide anti-pattern scan still passes**

Run: `python3 scripts/verify_code_quality.py`
Expected: exit code 0 ("No anti-patterns detected" or equivalent).

- [ ] **Step 4: L10n parity**

Run: `python3 scripts/check_l10n_sync.py`
Expected: exit code 0.

- [ ] **Step 5: Rules/stats sync**

Run: `python3 scripts/verify_rules.py --fix`
Expected: either no changes (CLAUDE.md stats unchanged) or a single stats-drift commit. If stats drifted, commit:

```bash
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
docs(claude-md): refresh stats after community foundation refactor

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 6: Community test suite**

Run: `flutter test test/features/community/`
Expected: all pass.

- [ ] **Step 7: Full test suite (excluding golden)**

Run: `flutter test --exclude-tags golden`
Expected: all pass.

- [ ] **Step 8: File size acceptance**

Run:
```bash
wc -l lib/features/community/widgets/community_post_card.dart \
      lib/features/community/widgets/community_post_card_body.dart \
      lib/features/community/widgets/community_report_sheet.dart \
      lib/features/community/widgets/community_report_reasons.dart
```
Expected:
- `community_post_card.dart` < 200
- `community_post_card_body.dart` ≤ 260
- `community_report_sheet.dart` ≤ 240
- `community_report_reasons.dart` ≤ 80

- [ ] **Step 9: Exemption docstrings present**

Run:
```bash
grep -l "Online-first:" lib/data/repositories/community_post_repository.dart lib/data/repositories/messaging_repository.dart
```
Expected: both files listed.

- [ ] **Step 10: Shim removed**

Run: `test ! -f lib/features/community/providers/community_moderation_providers.dart && echo REMOVED`
Expected: `REMOVED`.

- [ ] **Step 11: Summary**

Print a bulleted summary of the commits made (subject lines only) via:

Run: `git log --oneline origin/develop..HEAD`
Expected: 6–12 commits with conventional-commit subjects (`docs(rules)`, `docs(data)`, `chore(community)`, `refactor(community)`).

This list goes into the PR description.

---

## Out-of-Spec Items (for follow-up sub-projects)

- Any hardcoded text requiring NEW l10n keys — deferred to Sub-project 3 (UX polish).
- Any navigation stack semantic changes flagged during sweep — deferred to Sub-project 3.
- Feed rebuild scope narrowing, `.select()` adoption — Sub-project 2 (performance).
- Block/mute UX surfacing — Sub-project 2 (security hardening).
- `@mention`, `#hashtag`, trending feed, push integration — Sub-project 4 (new features).


