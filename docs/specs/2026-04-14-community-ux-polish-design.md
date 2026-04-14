# Community UX Polish — Design Spec

**Date:** 2026-04-14
**Goal:** Elevate the community tab's user experience to professional quality before public launch. No new features — focus on polish, animations, feedback, and consistency across 14 improvement areas.

---

## Scope

14 improvements in 3 priority tiers:

| # | Item | Tier | Files Affected |
|---|------|------|----------------|
| 1 | Search debounce + history | Critical | `community_search_providers.dart`, `community_search_screen.dart` |
| 2 | Draft auto-save | Critical | `community_create_post_screen.dart`, `community_create_providers.dart` |
| 3 | Comment pagination | Critical | `community_comment_providers.dart`, `community_comment_repository.dart`, `community_comment_remote_source.dart`, `community_post_detail_screen.dart` |
| 4 | Search layout shift fix | Critical | `community_search_screen.dart` |
| 5 | Bookmarks/UserPosts dedup | Critical | `community_bookmarks_screen.dart`, `community_user_posts_screen.dart`, new shared widget |
| 6 | Like/bookmark animations | Animation | `community_post_actions.dart`, `community_comment_tile.dart` |
| 7 | Tab transition animations | Animation | `community_screen.dart` |
| 8 | Report dialog redesign | Animation | `community_report_dialog.dart` |
| 9 | Comment input enrichment | Animation | `community_comment_input.dart` |
| 10 | Scroll-to-top FAB | Animation | `community_feed_list.dart` |
| 11 | Empty state improvements | Polish | `community_feed_states.dart`, `community_feed_items.dart` |
| 12 | Skeleton loading consistency | Polish | `community_bookmarks_screen.dart`, `community_user_posts_screen.dart`, `community_search_screen.dart`, `community_post_detail_screen.dart` |
| 13 | Haptic feedback standardization | Polish | Multiple widget files |
| 14 | Notification badge (AppBar) | Polish | `community_app_bar.dart` |

---

## 1. Search Debounce + History

**Problem:** Every keystroke in search triggers an API call. No search history.

**Solution:**
- Add 400ms `Timer`-based debounce in `communitySearchProvider` notifier
- Store last 10 searches in `SharedPreferences` under key `community_search_history`
- Show "Son Aramalar" section in `_SearchSuggestionsBody` with clear-all button
- Empty query shows: recent searches (if any) + popular tags + suggested users

**Implementation:**
- `CommunitySearchState` gains `_debounceTimer` field
- `updateQuery()` cancels previous timer, starts new 400ms timer before calling API
- New `CommunitySearchHistoryNotifier` manages SharedPreferences read/write
- `communitySearchHistoryProvider` exposes `List<String>` of recent queries
- On search submit (not debounce), add query to history

**L10n keys needed:**
- `community.recent_searches` → "Son Aramalar"
- `community.clear_search_history` → "Geçmişi Temizle"

---

## 2. Draft Auto-Save

**Problem:** User loses all post content if they navigate back or app crashes.

**Solution:**
- Auto-save draft to `SharedPreferences` with 2-second debounce after any field change
- On screen open, check for existing draft and show restore dialog
- On successful post, clear draft
- On back press with unsaved changes, show confirmation dialog

**Implementation:**
- `SharedPreferences` key: `community_post_draft`
- Serialized JSON: `{ "title": "", "content": "", "postType": "general", "tags": [] }`
- Images excluded (too large for SharedPreferences)
- `TextEditingController` listeners + `Timer` debounce (2s) trigger save
- `PopScope` (not deprecated `WillPopScope`) with `onPopInvokedWithResult` for back confirmation
- Dialog: "Taslağınız var. Devam etmek ister misiniz?" with "Devam Et" / "Sil" options
- Back dialog: "Kaydedilmemiş değişiklikler var. Çıkmak istediğinize emin misiniz?" with "Çık" / "Kal"

**L10n keys needed:**
- `community.draft_found` → "Taslağınız var"
- `community.draft_found_hint` → "Kaldığınız yerden devam etmek ister misiniz?"
- `community.draft_continue` → "Devam Et"
- `community.draft_discard` → "Sil"
- `community.unsaved_changes` → "Kaydedilmemiş değişiklikler var"
- `community.unsaved_changes_hint` → "Çıkmak istediğinize emin misiniz?"
- `community.exit` → "Çık"
- `community.stay` → "Kal"

---

## 3. Comment Pagination

**Problem:** All comments load at once — potential performance issue on popular posts.

**Solution:**
- Cursor-based pagination: 20 comments per page, ordered by `created_at` ascending
- Infinite scroll at bottom of comment list
- Skeleton loading for initial load, bottom spinner for subsequent pages

**Implementation:**
- `CommunityCommentRemoteSource.fetchByPost()` gains `limit` (default 20) and `cursor` (nullable `DateTime`) params
- Query: `.order('created_at').limit(limit)` + `.gt('created_at', cursor)` when cursor present
- `commentsForPostProvider` becomes a `NotifierProvider` managing `CommentListState`:
  ```
  CommentListState { List<CommunityComment> comments, bool hasMore, DateTime? cursor, bool isLoadingMore }
  ```
- `fetchInitial()` loads first 20, sets cursor to last comment's `createdAt`
- `fetchMore()` appends next page
- Detail screen: `SliverList` ends with loading indicator when `isLoadingMore`
- New comment appended locally after successful submit (no full reload needed)

---

## 4. Search Layout Shift Fix

**Problem:** TabBar appears/disappears when typing, causing layout jank.

**Solution:**
- TabBar always rendered in DOM
- When query is empty: `AnimatedOpacity(opacity: 0.0)` + `IgnorePointer`
- When query has value: `AnimatedOpacity(opacity: 1.0)`, pointer enabled
- Duration: 200ms, curve: `Curves.easeInOut`

**Implementation:**
- Remove conditional `if (hasQuery)` around TabBar in `community_search_screen.dart`
- Wrap TabBar in `AnimatedOpacity` + `IgnorePointer(ignoring: !hasQuery)`
- PreferredSize stays constant regardless of query state

---

## 5. Bookmarks/UserPosts Code Dedup

**Problem:** `CommunityBookmarksScreen` and `CommunityUserPostsScreen` are nearly identical (~60 lines each, same structure).

**Solution:**
- New shared widget: `CommunityPostListScreen`
- Parameters: `appBarTitle`, `postsProvider`, `emptyIcon`, `emptyTitle`, `emptyHint`
- Both screens become thin wrappers passing their specific provider and l10n keys

**Implementation:**
- New file: `lib/features/community/widgets/community_post_list_screen.dart`
- `CommunityPostListScreen` is a `ConsumerWidget` with:
  - `String appBarTitle`
  - `ProviderListenable<AsyncValue<List<CommunityPost>>> postsProvider`
  - `Widget emptyIcon`
  - `String emptyTitle`
  - `String emptyHint`
- Body: `postsAsync.when()` → skeleton loading / error / empty / RefreshIndicator + ListView.builder
- `CommunityBookmarksScreen` and `CommunityUserPostsScreen` each become ~15 lines

---

## 6. Like/Bookmark Animations

**Problem:** Like and bookmark toggles only change color — no satisfying visual feedback.

**Solution:**
- Scale bounce animation on toggle: 1.0 → 1.3 → 1.0 over 300ms
- Count change: slide-up fade-out micro-animation for "+1"/"-1" (200ms)
- Applied to: post actions (like, bookmark) and comment tile (like)

**Implementation:**
- Extract reusable `AnimatedToggleButton` widget (or inline `AnimationController` in actions)
- `AnimationController(duration: 300ms)` with `CurvedAnimation(curve: Curves.elasticOut)`
- On toggle: `controller.forward(from: 0)` triggers scale sequence
- `ScaleTransition` wraps the icon
- Count text: `AnimatedSwitcher` with `slideTransition` (vertical offset 0 → -8, opacity 1 → 0)
- Both `CommunityPostActions` and `CommunityCommentTile` use this pattern
- Must be `ConsumerStatefulWidget` (needs AnimationController lifecycle)

---

## 7. Tab Transition Animations

**Problem:** Tab switch is instant with no visual transition.

**Solution:**
- Wrap feed body in `AnimatedSwitcher` with fade transition
- Duration: 250ms
- Key changes when active tab changes

**Implementation:**
- In `community_screen.dart`, the `Expanded` child (CommunityFeedList or MarketplaceTabContent) wrapped in:
  ```dart
  AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
    child: KeyedSubtree(key: ValueKey(activeTab), child: feedBody),
  )
  ```
- Each tab's content gets unique `ValueKey` based on `CommunityFeedTab` enum value

---

## 8. Report Dialog Redesign

**Problem:** Plain `SimpleDialog` with just text options — feels bare.

**Solution:**
- Replace with `showModalBottomSheet` (card-based selection)
- Each reason: icon + title + short description
- "Diğer" option: reveals TextField (max 200 chars) for custom reason
- Confirmation step before submission
- Success animation (checkmark) + snackbar

**Implementation:**
- New `CommunityReportSheet` widget replaces `CommunityReportDialog`
- `showModalBottomSheet(isScrollControlled: true)` with `DraggableScrollableSheet`
- Report reasons as cards:
  - Spam → `LucideIcons.mailWarning` + "Spam veya reklam içeriği"
  - Harassment → `LucideIcons.shieldAlert` + "Kişisel saldırı veya taciz"
  - Inappropriate → `LucideIcons.eyeOff` + "Uygunsuz veya müstehcen içerik"
  - Misinformation → `LucideIcons.circleAlert` + "Yanlış veya yanıltıcı bilgi"
  - Other → `LucideIcons.messageCircleQuestion` + "Başka bir neden"
- On "Other" select: `AnimatedContainer` expands to show TextField
- Confirm step: bottom bar with "Bildir" button, tap submits
- Success: `LucideIcons.checkCircle` green icon + `'community.report_submitted'.tr()` snackbar

**L10n keys needed:**
- `community.report_title` → "Gönderiyi Bildir"
- `community.report_spam_hint` → "Spam veya reklam içeriği"
- `community.report_harassment_hint` → "Kişisel saldırı veya taciz"
- `community.report_inappropriate_hint` → "Uygunsuz veya müstehcen içerik"
- `community.report_misinformation_hint` → "Yanlış veya yanıltıcı bilgi"
- `community.report_other_hint` → "Başka bir neden"
- `community.report_other_placeholder` → "Nedenini açıklayın..."
- `community.report_confirm` → "Bildir"
- `community.report_confirm_message` → "Bu içeriği bildirmek istediğinize emin misiniz?"

---

## 9. Comment Input Enrichment

**Problem:** Minimal input — no character counter, no focus animation, no scroll-to-new-comment.

**Solution:**
- Character counter visible after 800 chars, turns red at 950+
- Focus border animates to `primaryColor`
- After successful comment submit, auto-scroll to new comment
- Send button: `AnimatedContainer` for enabled/disabled transition

**Implementation:**
- `CommunityCommentInput` becomes `ConsumerStatefulWidget` (needs FocusNode + AnimationController)
- `FocusNode` listener triggers border color `AnimatedContainer` (200ms)
- `ValueListenableBuilder` on `TextEditingController` for character count:
  - `count >= 800`: show `"$count/1000"` in `bodySmall` text
  - `count >= 950`: text color → `colorScheme.error`
- After successful comment (detected via `ref.listen` on commentFormProvider):
  - `scrollController.animateTo(scrollController.position.maxScrollExtent, duration: 300ms)`
- Send button: `AnimatedOpacity` + `AnimatedScale` for smooth enable/disable

---

## 10. Scroll-to-Top FAB

**Problem:** No way to quickly scroll back to top of feed.

**Solution:**
- Mini FAB appears when scroll offset > 600px
- Positioned to not conflict with create-post FAB
- Tap scrolls to top with smooth animation

**Implementation:**
- In `CommunityFeedList`, add `ScrollController` listener (already exists)
- New state: `_showScrollToTop` bool, updated on scroll
- `AnimatedScale(scale: _showScrollToTop ? 1.0 : 0.0, duration: 200ms)`
- Position: bottom-left with `AppSpacing.md` padding (create FAB is bottom-right)
- Icon: `LucideIcons.arrowUp`
- Size: `FloatingActionButton.small`
- On tap: `_scrollController.animateTo(0, duration: Duration(milliseconds: 400), curve: Curves.easeOutCubic)`
- Haptic: `HapticFeedback.lightImpact()` on tap

---

## 11. Empty State Improvements

**Problem:** Empty states are functional but bland — just icon + text.

**Solution:**
- Contextual CTA buttons that guide user to action
- Better subtitle messages explaining what to do
- Tab-specific empty states with relevant icons

**Changes per empty state:**
- **Following (empty):** Current text + "Keşfet'e Git" outlined button → navigates to explore tab
- **Guides (empty, founder):** Current text + "İlk Rehberi Yaz" filled button → navigates to create post with guide type
- **Guides (empty, non-founder):** "Yakında rehberler eklenecek" message, no CTA
- **Bookmarks (empty):** Current text + subtle hint: "Gönderilerdeki kaydet ikonuna dokunarak başlayın"
- **Search no results:** Current text + popular tags as `ActionChip` row below
- **User posts (empty):** Differentiate own profile ("İlk paylaşımınızı yapın!") vs. other user ("Bu kullanıcı henüz paylaşmamış")

**L10n keys needed:**
- `community.go_to_explore` → "Keşfet'e Git"
- `community.write_first_guide` → "İlk Rehberi Yaz"
- `community.guides_coming_soon` → "Yakında rehberler eklenecek"
- `community.bookmark_hint_action` → "Gönderilerdeki kaydet ikonuna dokunarak başlayın"
- `community.write_first_post` → "İlk paylaşımınızı yapın!"

---

## 12. Skeleton Loading Consistency

**Problem:** Some screens show `CircularProgressIndicator`, others show skeleton. Inconsistent.

**Solution:**
- Replace all community list loading spinners with `CommunityFeedSkeleton`
- Add comment skeleton variant for post detail screen

**Changes:**
- `CommunityBookmarksScreen` loading → `CommunityFeedSkeleton(count: 3)`
- `CommunityUserPostsScreen` loading → `CommunityFeedSkeleton(count: 3)`
- `CommunitySearchScreen` results loading → `CommunityFeedSkeleton(count: 2)`
- `CommunityPostDetailScreen` comments loading → new `_CommentSkeleton` (3 rows: avatar circle + 2 text lines)
- All skeletons wrapped in `RepaintBoundary`

**New widget:**
- `CommunityCommentSkeleton` in `community_feed_states.dart`: shimmer with avatar circle (32px) + name line (80px) + content lines (2, varying width)

---

## 13. Haptic Feedback Standardization

**Problem:** Haptic feedback is inconsistent — some actions have it, some don't.

**Solution:**
- Define standard haptic levels per action type
- Audit all community widgets and add/fix haptics

**Standard:**
| Action | Haptic Level |
|--------|-------------|
| Like/bookmark/follow toggle | `lightImpact` |
| Post submit, comment submit | `mediumImpact` |
| Tab switch, filter/sort change | `selectionClick` |
| Delete confirmation | `heavyImpact` |
| Report reason selection | `selectionClick` |
| Scroll-to-top tap | `lightImpact` |
| Pull-to-refresh trigger | `selectionClick` |
| Swipe action threshold | `lightImpact` |

**Files to audit:**
- `community_post_actions.dart` — like, bookmark, share
- `community_comment_tile.dart` — like, delete
- `community_user_header.dart` — follow toggle
- `community_pill_tabs.dart` — tab selection
- `community_section_bar.dart` — sort/filter chips
- `community_report_dialog.dart` (→ sheet) — reason selection
- `community_feed_list.dart` — scroll-to-top, pull-to-refresh
- `community_create_post_screen.dart` — submit
- `community_comment_input.dart` — submit

---

## 14. Notification Badge (AppBar)

**Problem:** Bell icon in AppBar has no badge — user can't see unread notifications.

**Solution:**
- Overlay red dot / count badge on bell icon
- Data from existing notifications provider
- Pulse animation on first appearance

**Implementation:**
- Existing `NotificationBellButton` widget already exists at `lib/features/notifications/widgets/notification_bell_button.dart`
- It uses `unreadNotificationsProvider` from `notification_list_providers.dart` and shows badge
- In `CommunityAppBar`, replace the manual bell icon with `NotificationBellButton`
- This gives us: badge with unread count, tap navigation to notifications, auto-update via provider
- Add entry animation: `ScaleTransition` from 0 to 1, 300ms, once on first render (if not already present)
- Reuse existing widget — no custom badge implementation needed

---

## Out of Scope

- New features (polls, events, stories UI)
- Comment threading / replies
- User profile page redesign
- Mention / @ autocomplete
- Emoji picker
- Markdown editor for post creation
- Real-time / WebSocket updates

---

## Testing Strategy

Each improvement gets corresponding test updates:
- **Debounce:** Timer-based test with `fakeAsync`, verify API not called before 400ms
- **Draft:** SharedPreferences mock, verify save/restore/clear cycle
- **Comment pagination:** Mock remote source with cursor param verification
- **Layout shift:** Widget test verifying TabBar always present in tree
- **Code dedup:** Existing bookmark/user-posts tests refactored to use shared widget
- **Animations:** Widget tests verify AnimationController creation and disposal
- **Skeletons:** Widget tests verify skeleton shown during loading state
- **Haptics:** Not directly testable in widget tests (platform channel)
- **Badge:** Widget test verifying badge visibility based on provider state

---

## L10n Summary

New keys to add (all 3 languages):
- `community.recent_searches`
- `community.clear_search_history`
- `community.draft_found`
- `community.draft_found_hint`
- `community.draft_continue`
- `community.draft_discard`
- `community.unsaved_changes`
- `community.unsaved_changes_hint`
- `community.exit`
- `community.stay`
- `community.report_title`
- `community.report_spam_hint`
- `community.report_harassment_hint`
- `community.report_inappropriate_hint`
- `community.report_misinformation_hint`
- `community.report_other_hint`
- `community.report_other_placeholder`
- `community.report_confirm`
- `community.report_confirm_message`
- `community.go_to_explore`
- `community.write_first_guide`
- `community.guides_coming_soon`
- `community.bookmark_hint_action`
- `community.write_first_post`

Total: 24 new l10n keys across 3 languages (tr, en, de).
