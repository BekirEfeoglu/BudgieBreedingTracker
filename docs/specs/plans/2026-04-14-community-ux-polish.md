# Community UX Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevate community tab UX to professional quality before public launch — 14 improvements across animations, feedback, consistency, and functional fixes.

**Architecture:** Modify existing community widgets and providers. No new entities/models. Online-first Supabase architecture unchanged. All changes are UI-layer and provider-layer.

**Tech Stack:** Flutter 3.41+, Riverpod 3, easy_localization, SharedPreferences, GoRouter

**Spec:** `docs/specs/2026-04-14-community-ux-polish-design.md`

---

## File Map

### New Files
- `lib/features/community/widgets/community_post_list_screen.dart` — Shared post list widget (dedup bookmarks/user-posts)
- `lib/features/community/widgets/community_report_sheet.dart` — Redesigned report bottom sheet
- `lib/features/community/widgets/animated_toggle_button.dart` — Reusable animated toggle for like/bookmark
- `test/features/community/widgets/community_post_list_screen_test.dart`
- `test/features/community/widgets/community_report_sheet_test.dart`
- `test/features/community/widgets/animated_toggle_button_test.dart`

### Modified Files
- `assets/translations/{tr,en,de}.json` — 24 new l10n keys
- `lib/features/community/providers/community_search_providers.dart` — Debounce + history
- `lib/features/community/screens/community_search_screen.dart` — Layout shift fix + history UI
- `lib/features/community/screens/community_create_post_screen.dart` — Draft auto-save
- `lib/features/community/providers/community_comment_providers.dart` — Pagination notifier
- `lib/data/remote/api/community_comment_remote_source.dart` — Cursor params
- `lib/data/repositories/community_comment_repository.dart` — Cursor passthrough
- `lib/features/community/screens/community_post_detail_screen.dart` — Paginated comments
- `lib/features/community/screens/community_bookmarks_screen.dart` — Use shared widget
- `lib/features/community/screens/community_user_posts_screen.dart` — Use shared widget
- `lib/features/community/widgets/community_post_actions.dart` — Animations
- `lib/features/community/widgets/community_comment_tile.dart` — Animations + haptic
- `lib/features/community/widgets/community_comment_input.dart` — Enrichment
- `lib/features/community/widgets/community_feed_list.dart` — Scroll-to-top FAB
- `lib/features/community/widgets/community_feed_states.dart` — Comment skeleton + empty states
- `lib/features/community/widgets/community_feed_items.dart` — Empty state CTAs
- `lib/features/community/screens/community_screen.dart` — Tab animations
- `lib/features/community/widgets/community_app_bar.dart` — NotificationBellButton
- `lib/features/community/widgets/community_section_bar.dart` — Haptic
- `lib/features/community/widgets/community_pill_tabs.dart` — Haptic
- `lib/features/community/widgets/community_user_header.dart` — Haptic
- `lib/features/community/widgets/community_report_dialog.dart` — Deprecated, replaced by sheet

---

## Task 1: Add L10n Keys (Foundation)

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add Turkish keys to tr.json**

Add these 24 keys inside the `"community"` object:

```json
"recent_searches": "Son Aramalar",
"clear_search_history": "Geçmişi Temizle",
"draft_found": "Taslağınız var",
"draft_found_hint": "Kaldığınız yerden devam etmek ister misiniz?",
"draft_continue": "Devam Et",
"draft_discard": "Sil",
"unsaved_changes": "Kaydedilmemiş değişiklikler var",
"unsaved_changes_hint": "Çıkmak istediğinize emin misiniz?",
"exit": "Çık",
"stay": "Kal",
"report_title": "Gönderiyi Bildir",
"report_spam_hint": "Spam veya reklam içeriği",
"report_harassment_hint": "Kişisel saldırı veya taciz",
"report_inappropriate_hint": "Uygunsuz veya müstehcen içerik",
"report_misinformation_hint": "Yanlış veya yanıltıcı bilgi",
"report_other_hint": "Başka bir neden",
"report_other_placeholder": "Nedenini açıklayın...",
"report_confirm": "Bildir",
"report_confirm_message": "Bu içeriği bildirmek istediğinize emin misiniz?",
"go_to_explore": "Keşfet'e Git",
"write_first_guide": "İlk Rehberi Yaz",
"guides_coming_soon": "Yakında rehberler eklenecek",
"bookmark_hint_action": "Gönderilerdeki kaydet ikonuna dokunarak başlayın",
"write_first_post": "İlk paylaşımınızı yapın!"
```

- [ ] **Step 2: Add English keys to en.json**

```json
"recent_searches": "Recent Searches",
"clear_search_history": "Clear History",
"draft_found": "Draft found",
"draft_found_hint": "Would you like to continue where you left off?",
"draft_continue": "Continue",
"draft_discard": "Discard",
"unsaved_changes": "Unsaved changes",
"unsaved_changes_hint": "Are you sure you want to leave?",
"exit": "Leave",
"stay": "Stay",
"report_title": "Report Post",
"report_spam_hint": "Spam or promotional content",
"report_harassment_hint": "Personal attack or harassment",
"report_inappropriate_hint": "Inappropriate or explicit content",
"report_misinformation_hint": "False or misleading information",
"report_other_hint": "Another reason",
"report_other_placeholder": "Describe the reason...",
"report_confirm": "Report",
"report_confirm_message": "Are you sure you want to report this content?",
"go_to_explore": "Go to Explore",
"write_first_guide": "Write First Guide",
"guides_coming_soon": "Guides coming soon",
"bookmark_hint_action": "Tap the save icon on posts to get started",
"write_first_post": "Make your first post!"
```

- [ ] **Step 3: Add German keys to de.json**

```json
"recent_searches": "Letzte Suchen",
"clear_search_history": "Verlauf löschen",
"draft_found": "Entwurf gefunden",
"draft_found_hint": "Möchten Sie dort weitermachen, wo Sie aufgehört haben?",
"draft_continue": "Fortsetzen",
"draft_discard": "Verwerfen",
"unsaved_changes": "Ungespeicherte Änderungen",
"unsaved_changes_hint": "Sind Sie sicher, dass Sie die Seite verlassen möchten?",
"exit": "Verlassen",
"stay": "Bleiben",
"report_title": "Beitrag melden",
"report_spam_hint": "Spam oder Werbeinhalte",
"report_harassment_hint": "Persönlicher Angriff oder Belästigung",
"report_inappropriate_hint": "Unangemessene oder explizite Inhalte",
"report_misinformation_hint": "Falsche oder irreführende Informationen",
"report_other_hint": "Ein anderer Grund",
"report_other_placeholder": "Beschreiben Sie den Grund...",
"report_confirm": "Melden",
"report_confirm_message": "Sind Sie sicher, dass Sie diesen Inhalt melden möchten?",
"go_to_explore": "Zu Entdecken",
"write_first_guide": "Ersten Ratgeber schreiben",
"guides_coming_soon": "Ratgeber kommen bald",
"bookmark_hint_action": "Tippen Sie auf das Speichersymbol bei Beiträgen",
"write_first_post": "Erstellen Sie Ihren ersten Beitrag!"
```

- [ ] **Step 4: Verify l10n sync**

Run: `python3 scripts/check_l10n_sync.py`
Expected: All 3 languages in sync, 0 missing keys.

- [ ] **Step 5: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(l10n): add 24 community UX polish translation keys"
```

---

## Task 2: Search Debounce + History

**Files:**
- Modify: `lib/features/community/providers/community_search_providers.dart`
- Modify: `lib/features/community/screens/community_search_screen.dart`
- Test: `test/features/community/providers/community_search_providers_test.dart`
- Test: `test/features/community/screens/community_search_screen_test.dart`

- [ ] **Step 1: Add debounce timer to CommunitySearchNotifier**

In `community_search_providers.dart`, modify `CommunitySearchNotifier`:

```dart
class CommunitySearchNotifier extends Notifier<CommunitySearchState> {
  Timer? _debounceTimer;

  @override
  CommunitySearchState build() {
    ref.onDispose(() => _debounceTimer?.cancel());
    return const CommunitySearchState();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) return;
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref.invalidate(communitySearchResultsProvider);
    });
  }

  void clear() {
    _debounceTimer?.cancel();
    state = const CommunitySearchState();
  }
}
```

Add `import 'dart:async';` at top.

- [ ] **Step 2: Add search history provider**

In same file, add after existing providers:

```dart
final communitySearchHistoryProvider =
    NotifierProvider<CommunitySearchHistoryNotifier, List<String>>(
  CommunitySearchHistoryNotifier.new,
);

class CommunitySearchHistoryNotifier extends Notifier<List<String>> {
  static const _key = 'community_search_history';
  static const _maxHistory = 10;

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    state = history;
  }

  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ...state.where((q) => q != trimmed)];
    state = updated.take(_maxHistory).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
```

Add `import 'package:shared_preferences/shared_preferences.dart';` at top.

- [ ] **Step 3: Update search screen to show history**

In `community_search_screen.dart`, update `_applyQuery` to save history:

```dart
void _applyQuery(String query) {
  ref.read(communitySearchProvider.notifier).setQuery(query);
  if (query.trim().isNotEmpty) {
    ref.read(communitySearchHistoryProvider.notifier).addQuery(query);
  }
}
```

In `_SearchSuggestionsBody`, add recent searches section before popular tags:

```dart
final history = ref.watch(communitySearchHistoryProvider);
if (history.isNotEmpty) ...[
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('community.recent_searches'.tr(),
            style: theme.textTheme.titleSmall),
        TextButton(
          onPressed: () => ref
              .read(communitySearchHistoryProvider.notifier)
              .clearHistory(),
          child: Text('community.clear_search_history'.tr()),
        ),
      ],
    ),
  ),
  Wrap(
    spacing: AppSpacing.xs,
    children: history
        .map((q) => ActionChip(
              label: Text(q),
              onPressed: () => onTagTap(q),
            ))
        .toList(),
  ),
  const SizedBox(height: AppSpacing.md),
],
```

- [ ] **Step 4: Write tests for debounce**

In `community_search_providers_test.dart`, add:

```dart
test('should debounce search queries by 400ms', () async {
  fakeAsync((async) {
    final container = ProviderContainer(overrides: [
      communityPostRepositoryProvider.overrideWithValue(mockRepo),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(communitySearchProvider.notifier);
    notifier.setQuery('bud');
    notifier.setQuery('budg');
    notifier.setQuery('budgie');

    // Before 400ms, search should not trigger
    async.elapse(const Duration(milliseconds: 300));
    verifyNever(() => mockRepo.search(any()));

    // After 400ms, only final query triggers
    async.elapse(const Duration(milliseconds: 200));
    // Provider invalidation triggers search
  });
});

test('should clear debounce timer on clear', () {
  fakeAsync((async) {
    final container = ProviderContainer(overrides: [
      communityPostRepositoryProvider.overrideWithValue(mockRepo),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(communitySearchProvider.notifier);
    notifier.setQuery('budgie');
    notifier.clear();
    async.elapse(const Duration(milliseconds: 500));
    expect(container.read(communitySearchProvider).query, '');
  });
});
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/features/community/providers/community_search_providers_test.dart`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/community/providers/community_search_providers.dart \
  lib/features/community/screens/community_search_screen.dart \
  test/features/community/providers/community_search_providers_test.dart
git commit -m "feat(community): add search debounce (400ms) and search history"
```

---

## Task 3: Draft Auto-Save

**Files:**
- Modify: `lib/features/community/screens/community_create_post_screen.dart`
- Test: `test/features/community/screens/community_create_post_screen_test.dart`

- [ ] **Step 1: Add draft save/load methods to state**

In `_CommunityCreatePostScreenState`, add draft constants and methods:

```dart
static const _draftKey = 'community_post_draft';
Timer? _draftTimer;

Future<void> _saveDraft() async {
  final draft = {
    'title': _titleController.text,
    'content': _contentController.text,
    'postType': _postType.toJson(),
    'tags': _tags,
  };
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_draftKey, jsonEncode(draft));
}

Future<Map<String, dynamic>?> _loadDraft() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_draftKey);
  if (json == null) return null;
  return jsonDecode(json) as Map<String, dynamic>;
}

Future<void> _clearDraft() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_draftKey);
}

void _scheduleDraftSave() {
  _draftTimer?.cancel();
  _draftTimer = Timer(const Duration(seconds: 2), _saveDraft);
}
```

Add imports: `dart:async`, `dart:convert`, `package:shared_preferences/shared_preferences.dart`.

- [ ] **Step 2: Wire up draft save to controllers and restore on init**

In `initState()`, add draft restore check:

```dart
@override
void initState() {
  super.initState();
  _titleController.addListener(_scheduleDraftSave);
  _contentController.addListener(_scheduleDraftSave);
  _checkDraft();
}

Future<void> _checkDraft() async {
  final draft = await _loadDraft();
  if (draft == null || !mounted) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('community.draft_found'.tr()),
      content: Text('community.draft_found_hint'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('community.draft_discard'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('community.draft_continue'.tr()),
        ),
      ],
    ),
  );
  if (confirmed == true && mounted) {
    _titleController.text = draft['title'] as String? ?? '';
    _contentController.text = draft['content'] as String? ?? '';
    _postType = CommunityPostType.fromJson(draft['postType'] as String? ?? 'general');
    _tags = List<String>.from(draft['tags'] as List? ?? []);
    setState(() {});
  } else {
    await _clearDraft();
  }
}
```

- [ ] **Step 3: Add PopScope for back confirmation**

Wrap Scaffold with `PopScope`:

```dart
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    final hasContent = _titleController.text.isNotEmpty ||
        _contentController.text.isNotEmpty ||
        _tags.isNotEmpty ||
        _selectedImages.isNotEmpty;
    if (!hasContent) {
      Navigator.pop(context);
      return;
    }
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('community.unsaved_changes'.tr()),
        content: Text('community.unsaved_changes_hint'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('community.stay'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('community.exit'.tr()),
          ),
        ],
      ),
    );
    if (shouldLeave == true && context.mounted) {
      await _clearDraft();
      Navigator.pop(context);
    }
  },
  child: Scaffold(/* ... existing scaffold ... */),
)
```

- [ ] **Step 4: Clear draft on successful submit**

In `_submit()`, after successful post, add: `await _clearDraft();`

- [ ] **Step 5: Update dispose**

```dart
@override
void dispose() {
  _draftTimer?.cancel();
  _titleController.dispose();
  _contentController.dispose();
  _tagController.dispose();
  super.dispose();
}
```

- [ ] **Step 6: Write tests**

```dart
testWidgets('should show draft restore dialog when draft exists', (tester) async {
  SharedPreferences.setMockInitialValues({
    'community_post_draft': jsonEncode({
      'title': 'Test Title',
      'content': 'Test Content',
      'postType': 'general',
      'tags': ['tag1'],
    }),
  });
  await pumpWidget(tester, const CommunityCreatePostScreen());
  await tester.pumpAndSettle();
  expect(find.text('community.draft_found'.tr()), findsOneWidget);
});

testWidgets('should show unsaved changes dialog on back press', (tester) async {
  SharedPreferences.setMockInitialValues({});
  await pumpWidget(tester, const CommunityCreatePostScreen());
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'Some content');
  // Simulate back press
  final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
  await widgetsAppState.didPopRoute();
  await tester.pumpAndSettle();
  expect(find.text('community.unsaved_changes'.tr()), findsOneWidget);
});
```

- [ ] **Step 7: Run tests**

Run: `flutter test test/features/community/screens/community_create_post_screen_test.dart`
Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/features/community/screens/community_create_post_screen.dart \
  test/features/community/screens/community_create_post_screen_test.dart
git commit -m "feat(community): add draft auto-save with restore dialog and back confirmation"
```

---

## Task 4: Comment Pagination

**Files:**
- Modify: `lib/data/remote/api/community_comment_remote_source.dart`
- Modify: `lib/data/repositories/community_comment_repository.dart`
- Modify: `lib/features/community/providers/community_comment_providers.dart`
- Modify: `lib/features/community/screens/community_post_detail_screen.dart`
- Modify: `lib/features/community/widgets/community_feed_states.dart` (add comment skeleton)
- Test: `test/data/remote/api/community_comment_remote_source_test.dart`
- Test: `test/features/community/providers/community_comment_providers_test.dart`

- [ ] **Step 1: Add cursor params to remote source**

In `community_comment_remote_source.dart`, update `fetchByPost`:

```dart
Future<List<Map<String, dynamic>>> fetchByPost(
  String postId, {
  int limit = 20,
  DateTime? cursor,
}) async {
  var query = _client
      .from(SupabaseConstants.communityCommentsTable)
      .select()
      .eq(SupabaseConstants.postId, postId)
      .eq('is_deleted', false)
      .order('created_at');

  if (cursor != null) {
    query = query.gt('created_at', cursor.toIso8601String());
  }

  final rows = await query.limit(limit);
  await _profileCache.mergeIntoRows(rows);
  return rows;
}
```

- [ ] **Step 2: Update repository to pass cursor**

In `community_comment_repository.dart`, update `getByPost`:

```dart
Future<List<CommunityComment>> getByPost(
  String postId, {
  int limit = 20,
  DateTime? cursor,
}) async {
  final rows = await _commentSource.fetchByPost(
    postId,
    limit: limit,
    cursor: cursor,
  );
  // ... existing enrichment logic with likedIds ...
  return rows.map(_parseComment).toList();
}
```

- [ ] **Step 3: Replace FutureProvider with NotifierProvider for comments**

In `community_comment_providers.dart`, replace `commentsForPostProvider`:

```dart
class CommentListState {
  const CommentListState({
    this.comments = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  final List<CommunityComment> comments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final DateTime? cursor;
  final Object? error;
}

final commentListProvider =
    NotifierProvider.family<CommentListNotifier, CommentListState, String>(
  CommentListNotifier.new,
);

class CommentListNotifier extends FamilyNotifier<CommentListState, String> {
  static const _pageSize = 20;

  @override
  CommentListState build(String arg) {
    fetchInitial();
    return const CommentListState(isLoading: true);
  }

  Future<void> fetchInitial() async {
    state = const CommentListState(isLoading: true);
    try {
      final repo = ref.read(communityCommentRepositoryProvider);
      final comments = await repo.getByPost(arg, limit: _pageSize);
      state = CommentListState(
        comments: comments,
        hasMore: comments.length >= _pageSize,
        cursor: comments.isNotEmpty ? comments.last.createdAt : null,
      );
    } catch (e) {
      state = CommentListState(error: e);
    }
  }

  Future<void> fetchMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = CommentListState(
      comments: state.comments,
      isLoadingMore: true,
      hasMore: state.hasMore,
      cursor: state.cursor,
    );
    try {
      final repo = ref.read(communityCommentRepositoryProvider);
      final newComments = await repo.getByPost(
        arg,
        limit: _pageSize,
        cursor: state.cursor,
      );
      state = CommentListState(
        comments: [...state.comments, ...newComments],
        hasMore: newComments.length >= _pageSize,
        cursor: newComments.isNotEmpty ? newComments.last.createdAt : null,
      );
    } catch (e) {
      state = CommentListState(
        comments: state.comments,
        hasMore: state.hasMore,
        cursor: state.cursor,
        error: e,
      );
    }
  }

  void addCommentLocally(CommunityComment comment) {
    state = CommentListState(
      comments: [...state.comments, comment],
      hasMore: state.hasMore,
      cursor: state.cursor,
    );
  }
}
```

Keep old `commentsForPostProvider` as deprecated or remove after updating detail screen.

- [ ] **Step 4: Add CommunityCommentSkeleton widget**

In `community_feed_states.dart`, add:

```dart
class CommunityCommentSkeleton extends StatelessWidget {
  const CommunityCommentSkeleton({super.key, this.count = 3});
  final int count;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: List.generate(count, (_) => const _CommentSkeletonItem()),
      ),
    );
  }
}

class _CommentSkeletonItem extends StatelessWidget {
  const _CommentSkeletonItem();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shimmer = theme.colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(shape: BoxShape.circle, color: shimmer),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 80, height: 12, color: shimmer),
                const SizedBox(height: AppSpacing.xs),
                Container(width: double.infinity, height: 12, color: shimmer),
                const SizedBox(height: 4),
                Container(width: 160, height: 12, color: shimmer),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Update detail screen to use paginated comments**

In `community_post_detail_screen.dart`, replace `commentsForPostProvider` usage with `commentListProvider`:

```dart
final commentState = ref.watch(commentListProvider(postId));

// Replace comments SliverList section:
if (commentState.isLoading)
  const SliverToBoxAdapter(child: CommunityCommentSkeleton())
else if (commentState.comments.isEmpty)
  SliverToBoxAdapter(child: Center(child: Text('community.no_comments'.tr())))
else ...[
  SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, index) {
        if (index == commentState.comments.length) {
          if (commentState.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (commentState.hasMore) {
            return TextButton(
              onPressed: () => ref.read(commentListProvider(postId).notifier).fetchMore(),
              child: Text('community.show_more_following'.tr(args: [''])),
            );
          }
          return const SizedBox.shrink();
        }
        return CommunityCommentTile(comment: commentState.comments[index]);
      },
      childCount: commentState.comments.length + 1,
    ),
  ),
],
```

Update RefreshIndicator to call `fetchInitial`:
```dart
onRefresh: () async {
  ref.invalidate(communityPostByIdProvider(postId));
  await ref.read(commentListProvider(postId).notifier).fetchInitial();
},
```

- [ ] **Step 6: Write tests and run**

Run: `flutter test test/features/community/providers/community_comment_providers_test.dart`
Run: `flutter test test/features/community/screens/community_post_detail_screen_test.dart`

- [ ] **Step 7: Commit**

```bash
git add lib/data/remote/api/community_comment_remote_source.dart \
  lib/data/repositories/community_comment_repository.dart \
  lib/features/community/providers/community_comment_providers.dart \
  lib/features/community/screens/community_post_detail_screen.dart \
  lib/features/community/widgets/community_feed_states.dart \
  test/
git commit -m "feat(community): add cursor-based comment pagination with skeleton loading"
```

---

## Task 5: Search Layout Shift Fix

**Files:**
- Modify: `lib/features/community/screens/community_search_screen.dart`
- Test: `test/features/community/screens/community_search_screen_test.dart`

- [ ] **Step 1: Make TabBar always visible with animated opacity**

In `_CommunitySearchScreenState.build()`, replace conditional TabBar with:

```dart
// In AppBar bottom:
bottom: PreferredSize(
  preferredSize: const Size.fromHeight(48),
  child: AnimatedOpacity(
    opacity: hasQuery ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeInOut,
    child: IgnorePointer(
      ignoring: !hasQuery,
      child: TabBar(
        tabs: [
          Tab(text: 'community.search_posts'.tr()),
          Tab(text: 'community.search_users'.tr()),
          Tab(text: 'community.search_tags'.tr()),
        ],
      ),
    ),
  ),
),
```

Remove the old `if (hasQuery)` conditional around TabBar.

- [ ] **Step 2: Write test**

```dart
testWidgets('TabBar is always in widget tree regardless of query', (tester) async {
  await pumpWidget(tester, const CommunitySearchScreen());
  await tester.pumpAndSettle();
  // TabBar present even without query
  expect(find.byType(TabBar), findsOneWidget);
  // Enter query - TabBar still present
  await tester.enterText(find.byType(TextField), 'test');
  await tester.pumpAndSettle();
  expect(find.byType(TabBar), findsOneWidget);
});
```

- [ ] **Step 3: Run tests and commit**

Run: `flutter test test/features/community/screens/community_search_screen_test.dart`

```bash
git add lib/features/community/screens/community_search_screen.dart \
  test/features/community/screens/community_search_screen_test.dart
git commit -m "fix(community): eliminate search TabBar layout shift with AnimatedOpacity"
```

---

## Task 6: Bookmarks/UserPosts Code Dedup

**Files:**
- Create: `lib/features/community/widgets/community_post_list_screen.dart`
- Modify: `lib/features/community/screens/community_bookmarks_screen.dart`
- Modify: `lib/features/community/screens/community_user_posts_screen.dart`
- Create: `test/features/community/widgets/community_post_list_screen_test.dart`

- [ ] **Step 1: Create shared CommunityPostListScreen widget**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart' as app;
import '../../../../data/models/community_post_model.dart';
import '../widgets/community_feed_states.dart';
import '../widgets/community_post_card.dart';

class CommunityPostListScreen extends ConsumerWidget {
  const CommunityPostListScreen({
    super.key,
    required this.appBarTitle,
    required this.postsProvider,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyHint,
  });

  final String appBarTitle;
  final ProviderListenable<AsyncValue<List<CommunityPost>>> postsProvider;
  final Widget emptyIcon;
  final String emptyTitle;
  final String emptyHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: postsAsync.when(
        loading: () => const CommunityFeedSkeleton(),
        error: (e, _) => app.ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(postsProvider),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return EmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptyHint,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(postsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
              itemCount: posts.length,
              itemBuilder: (_, i) => CommunityPostCard(post: posts[i]),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Refactor BookmarksScreen to use shared widget**

```dart
class CommunityBookmarksScreen extends StatelessWidget {
  const CommunityBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CommunityPostListScreen(
      appBarTitle: 'community.bookmarks'.tr(),
      postsProvider: bookmarkedPostsProvider,
      emptyIcon: AppIcon(AppIcons.bookmark),
      emptyTitle: 'community.no_bookmarks'.tr(),
      emptyHint: 'community.bookmark_hint_action'.tr(),
    );
  }
}
```

- [ ] **Step 3: Refactor UserPostsScreen to use shared widget**

```dart
class CommunityUserPostsScreen extends StatelessWidget {
  const CommunityUserPostsScreen({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return CommunityPostListScreen(
      appBarTitle: 'community.user_posts'.tr(),
      postsProvider: userPostsProvider(userId),
      emptyIcon: AppIcon(AppIcons.community),
      emptyTitle: 'community.no_user_posts'.tr(),
      emptyHint: 'community.write_first_post'.tr(),
    );
  }
}
```

- [ ] **Step 4: Write tests for shared widget**

```dart
testWidgets('shows skeleton during loading', (tester) async {
  await pumpWidget(tester, CommunityPostListScreen(
    appBarTitle: 'Test',
    postsProvider: Provider((ref) => const AsyncValue<List<CommunityPost>>.loading()),
    emptyIcon: const Icon(Icons.bookmark),
    emptyTitle: 'Empty',
    emptyHint: 'Hint',
  ));
  expect(find.byType(CommunityFeedSkeleton), findsOneWidget);
});

testWidgets('shows empty state when no posts', (tester) async {
  await pumpWidget(tester, CommunityPostListScreen(
    appBarTitle: 'Test',
    postsProvider: Provider((ref) => const AsyncValue.data(<CommunityPost>[])),
    emptyIcon: const Icon(Icons.bookmark),
    emptyTitle: 'No items',
    emptyHint: 'Try again',
  ));
  await tester.pumpAndSettle();
  expect(find.text('No items'), findsOneWidget);
});
```

- [ ] **Step 5: Run tests and commit**

Run: `flutter test test/features/community/widgets/community_post_list_screen_test.dart`
Run: `flutter test test/features/community/screens/community_bookmarks_screen_test.dart`
Run: `flutter test test/features/community/screens/community_user_posts_screen_test.dart`

```bash
git add lib/features/community/widgets/community_post_list_screen.dart \
  lib/features/community/screens/community_bookmarks_screen.dart \
  lib/features/community/screens/community_user_posts_screen.dart \
  test/
git commit -m "refactor(community): extract shared CommunityPostListScreen, dedup bookmarks and user posts"
```

---

## Task 7: Like/Bookmark Animations

**Files:**
- Create: `lib/features/community/widgets/animated_toggle_button.dart`
- Modify: `lib/features/community/widgets/community_post_actions.dart`
- Modify: `lib/features/community/widgets/community_comment_tile.dart`
- Create: `test/features/community/widgets/animated_toggle_button_test.dart`

- [ ] **Step 1: Create reusable AnimatedToggleButton**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedToggleButton extends StatefulWidget {
  const AnimatedToggleButton({
    super.key,
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.onToggle,
    this.activeColor,
    this.inactiveColor,
    this.size = 20,
    this.label,
    this.labelStyle,
    this.semanticLabel,
  });

  final bool isActive;
  final Widget activeIcon;
  final Widget inactiveIcon;
  final VoidCallback onToggle;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;
  final String? label;
  final TextStyle? labelStyle;
  final String? semanticLabel;

  @override
  State<AnimatedToggleButton> createState() => _AnimatedToggleButtonState();
}

class _AnimatedToggleButtonState extends State<AnimatedToggleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void didUpdateWidget(AnimatedToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onToggle();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: widget.isActive ? widget.activeIcon : widget.inactiveIcon,
            ),
            if (widget.label != null) ...[
              const SizedBox(width: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  widget.label!,
                  key: ValueKey(widget.label),
                  style: widget.labelStyle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update CommunityPostActions to use AnimatedToggleButton**

In `community_post_actions.dart`, replace like and bookmark buttons with `AnimatedToggleButton`:

```dart
// Like button (replace existing _PillActionButton for like):
AnimatedToggleButton(
  isActive: post.isLikedByMe,
  activeIcon: Icon(LucideIcons.heart, color: theme.colorScheme.primary, size: 18, fill: 1),
  inactiveIcon: Icon(LucideIcons.heart, color: theme.colorScheme.onSurfaceVariant, size: 18),
  onToggle: _onLike,
  label: '${post.likeCount}',
  labelStyle: theme.textTheme.labelMedium,
  semanticLabel: 'community.like'.tr(),
),

// Bookmark button (replace existing _ActionButton for bookmark):
AnimatedToggleButton(
  isActive: post.isBookmarkedByMe,
  activeIcon: Icon(LucideIcons.bookmark, color: theme.colorScheme.primary, size: 18, fill: 1),
  inactiveIcon: Icon(LucideIcons.bookmark, color: theme.colorScheme.onSurfaceVariant, size: 18),
  onToggle: _onBookmark,
  semanticLabel: 'community.bookmark'.tr(),
),
```

- [ ] **Step 3: Update CommunityCommentTile like button**

Replace comment like section (lines 89-130) with `AnimatedToggleButton`:

```dart
AnimatedToggleButton(
  isActive: comment.isLikedByMe,
  activeIcon: Icon(LucideIcons.heart, color: theme.colorScheme.primary, size: 16, fill: 1),
  inactiveIcon: Icon(LucideIcons.heart, color: theme.colorScheme.onSurfaceVariant, size: 16),
  onToggle: () => ref.read(commentLikeToggleProvider.notifier)
      .toggleCommentLike(commentId: comment.id, postId: comment.postId),
  label: comment.likeCount > 0 ? '${comment.likeCount}' : null,
  labelStyle: theme.textTheme.labelSmall,
  semanticLabel: 'community.like'.tr(),
),
```

Note: `CommunityCommentTile` must become `ConsumerStatefulWidget` or the `AnimatedToggleButton` must be used as a child.  Since `AnimatedToggleButton` manages its own `AnimationController`, `CommunityCommentTile` can remain `ConsumerWidget`.

- [ ] **Step 4: Write tests**

```dart
testWidgets('AnimatedToggleButton triggers scale animation on toggle', (tester) async {
  var toggled = false;
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AnimatedToggleButton(
        isActive: false,
        activeIcon: const Icon(Icons.favorite, color: Colors.red),
        inactiveIcon: const Icon(Icons.favorite_border),
        onToggle: () => toggled = true,
        label: '5',
      ),
    ),
  ));
  await tester.tap(find.byType(AnimatedToggleButton));
  expect(toggled, isTrue);
  // Animation controller should be running
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pumpAndSettle();
});
```

- [ ] **Step 5: Run tests and commit**

Run: `flutter test test/features/community/widgets/animated_toggle_button_test.dart`
Run: `flutter test test/features/community/widgets/community_post_card_test.dart`
Run: `flutter test test/features/community/widgets/community_comment_tile_test.dart`

```bash
git add lib/features/community/widgets/animated_toggle_button.dart \
  lib/features/community/widgets/community_post_actions.dart \
  lib/features/community/widgets/community_comment_tile.dart \
  test/
git commit -m "feat(community): add scale bounce animations for like and bookmark toggles"
```

---

## Task 8: Tab Transition Animations

**Files:**
- Modify: `lib/features/community/screens/community_screen.dart`
- Test: `test/features/community/screens/community_screen_test.dart`

- [ ] **Step 1: Wrap feed body in AnimatedSwitcher**

In `community_screen.dart`, modify `_buildBody()` return or the Expanded child in `build()`:

```dart
Expanded(
  child: AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    transitionBuilder: (child, animation) =>
        FadeTransition(opacity: animation, child: child),
    child: KeyedSubtree(
      key: ValueKey(activeTab),
      child: activeTab == CommunityFeedTab.questions
          ? const MarketplaceTabContent()
          : CommunityFeedList(tab: activeTab),
    ),
  ),
),
```

- [ ] **Step 2: Write test**

```dart
testWidgets('animates between tabs with fade transition', (tester) async {
  await pumpWidget(tester, const CommunityScreen());
  await tester.pumpAndSettle();
  expect(find.byType(AnimatedSwitcher), findsOneWidget);
  expect(find.byType(FadeTransition), findsWidgets);
});
```

- [ ] **Step 3: Run tests and commit**

Run: `flutter test test/features/community/screens/community_screen_test.dart`

```bash
git add lib/features/community/screens/community_screen.dart test/
git commit -m "feat(community): add fade transition animation for tab switches"
```

---

## Task 9: Report Dialog Redesign

**Files:**
- Create: `lib/features/community/widgets/community_report_sheet.dart`
- Modify: `lib/features/community/widgets/community_post_card.dart` (update import)
- Modify: `lib/features/community/widgets/community_comment_tile.dart` (update import)
- Create: `test/features/community/widgets/community_report_sheet_test.dart`

- [ ] **Step 1: Create CommunityReportSheet**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/enums/community_enums.dart';
import '../../../../core/theme/app_spacing.dart';

Future<CommunityReportReason?> showCommunityReportSheet(
  BuildContext context, {
  required String title,
}) async {
  return showModalBottomSheet<CommunityReportReason>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ReportSheetContent(title: title),
  );
}

class _ReportSheetContent extends StatefulWidget {
  const _ReportSheetContent({required this.title});
  final String title;

  @override
  State<_ReportSheetContent> createState() => _ReportSheetContentState();
}

class _ReportSheetContentState extends State<_ReportSheetContent> {
  CommunityReportReason? _selected;
  final _otherController = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  static const _reasons = [
    (CommunityReportReason.spam, LucideIcons.mailWarning, 'community.report_reason_spam', 'community.report_spam_hint'),
    (CommunityReportReason.harassment, LucideIcons.shieldAlert, 'community.report_reason_harassment', 'community.report_harassment_hint'),
    (CommunityReportReason.inappropriate, LucideIcons.eyeOff, 'community.report_reason_inappropriate', 'community.report_inappropriate_hint'),
    (CommunityReportReason.misinformation, LucideIcons.circleAlert, 'community.report_reason_misinformation', 'community.report_misinformation_hint'),
    (CommunityReportReason.other, LucideIcons.messageCircleQuestion, 'community.report_reason_other', 'community.report_other_hint'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ..._reasons.map((r) => _ReasonCard(
              reason: r.$1,
              icon: r.$2,
              title: r.$3.tr(),
              hint: r.$4.tr(),
              isSelected: _selected == r.$1,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selected = r.$1);
              },
            )),
            if (_selected == CommunityReportReason.other) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _otherController,
                maxLength: 200,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'community.report_other_placeholder'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            if (_selected != null) ...[
              const SizedBox(height: AppSpacing.md),
              if (!_confirmed)
                Text(
                  'community.report_confirm_message'.tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(context, _selected);
                },
                child: Text('community.report_confirm'.tr()),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.reason,
    required this.icon,
    required this.title,
    required this.hint,
    required this.isSelected,
    required this.onTap,
  });

  final CommunityReportReason reason;
  final IconData icon;
  final String title;
  final String hint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
                      Text(hint, style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(LucideIcons.checkCircle, size: 18, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update callers to use showCommunityReportSheet**

In `community_post_card.dart` and `community_comment_tile.dart`, replace:
```dart
// Old:
showCommunityReportDialog(context, title: ...)
// New:
showCommunityReportSheet(context, title: ...)
```

Update imports accordingly.

- [ ] **Step 3: Write tests**

```dart
testWidgets('shows all report reasons as cards', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showCommunityReportSheet(context, title: 'Report'),
        child: const Text('Report'),
      ),
    ),
  ));
  await tester.tap(find.text('Report'));
  await tester.pumpAndSettle();
  expect(find.text('community.report_reason_spam'.tr()), findsOneWidget);
  expect(find.text('community.report_reason_other'.tr()), findsOneWidget);
});

testWidgets('shows text field when Other is selected', (tester) async {
  // Open sheet, tap Other reason, verify TextField appears
});
```

- [ ] **Step 4: Run tests and commit**

Run: `flutter test test/features/community/widgets/community_report_sheet_test.dart`

```bash
git add lib/features/community/widgets/community_report_sheet.dart \
  lib/features/community/widgets/community_post_card.dart \
  lib/features/community/widgets/community_comment_tile.dart \
  test/
git commit -m "feat(community): redesign report dialog as card-based bottom sheet"
```

---

## Task 10: Comment Input Enrichment

**Files:**
- Modify: `lib/features/community/widgets/community_comment_input.dart`
- Modify: `lib/features/community/screens/community_post_detail_screen.dart`
- Test: `test/features/community/widgets/community_comment_input_test.dart`

- [ ] **Step 1: Add character counter and focus animation**

Rewrite `_CommunityCommentInputState` to add FocusNode and counter:

```dart
class _CommunityCommentInputState extends ConsumerState<CommunityCommentInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  static const _maxLength = 1000;
  static const _showCounterAt = 800;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > _maxLength) return;
    HapticFeedback.mediumImpact();
    await ref.read(commentFormProvider.notifier).addComment(
      postId: widget.postId,
      content: text,
    );
    if (!mounted) return;
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(commentFormProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: _focusNode.hasFocus
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: _focusNode.hasFocus ? 2 : 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      maxLength: _maxLength,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) {
                        if (currentLength < _showCounterAt) return null;
                        final isNearLimit = currentLength >= 950;
                        return Text(
                          '$currentLength/$maxLength',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isNearLimit
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'community.add_comment'.tr(),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  AnimatedScale(
                    scale: _controller.text.trim().isNotEmpty ? 1.0 : 0.7,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedOpacity(
                      opacity: _controller.text.trim().isNotEmpty ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 150),
                      child: IconButton(
                        onPressed: formState.isLoading ? null : _submit,
                        icon: formState.isLoading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(LucideIcons.send, size: 20,
                                color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

Add `ListenableBuilder` or `ValueListenableBuilder` wrapper for animated send button reactivity (use `_controller.addListener(() => setState(() {}))` in initState for simplicity).

- [ ] **Step 2: Add scroll-to-new-comment in detail screen**

In `community_post_detail_screen.dart`, add ScrollController and listen for comment success:

```dart
// Add a ScrollController to the screen
final _scrollController = ScrollController();

// In ref.listen for commentFormProvider success:
ref.listen(commentFormProvider, (prev, next) {
  if (next.isSuccess && prev?.isSuccess != true) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('community.comment_success'.tr())),
    );
    // Scroll to bottom to show new comment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
});
```

Pass `_scrollController` to the `CustomScrollView`.

- [ ] **Step 3: Write tests**

```dart
testWidgets('shows character counter after 800 chars', (tester) async {
  await pumpWidget(tester, const CommunityCommentInput(postId: 'test'));
  await tester.pumpAndSettle();
  // Type 801 chars
  await tester.enterText(find.byType(TextField), 'a' * 801);
  await tester.pump();
  expect(find.textContaining('801/1000'), findsOneWidget);
});

testWidgets('counter turns red at 950+ chars', (tester) async {
  await pumpWidget(tester, const CommunityCommentInput(postId: 'test'));
  await tester.enterText(find.byType(TextField), 'a' * 960);
  await tester.pump();
  final counterText = tester.widget<Text>(find.textContaining('960/1000'));
  expect(counterText.style?.color, Theme.of(tester.element(find.byType(Scaffold))).colorScheme.error);
});
```

- [ ] **Step 4: Run tests and commit**

Run: `flutter test test/features/community/widgets/community_comment_input_test.dart`
Run: `flutter test test/features/community/screens/community_post_detail_screen_test.dart`

```bash
git add lib/features/community/widgets/community_comment_input.dart \
  lib/features/community/screens/community_post_detail_screen.dart \
  test/
git commit -m "feat(community): enrich comment input with character counter, focus animation, scroll-to-new"
```

---

## Task 11: Scroll-to-Top FAB

**Files:**
- Modify: `lib/features/community/widgets/community_feed_list.dart`
- Test: `test/features/community/widgets/community_feed_list_test.dart`

- [ ] **Step 1: Add scroll-to-top state and FAB**

In `_CommunityFeedListState`, add:

```dart
bool _showScrollToTop = false;
static const _scrollToTopThreshold = 600.0;
```

Update `_onScroll()`:

```dart
void _onScroll() {
  // ... existing infinite scroll logic ...

  // Scroll-to-top visibility
  final shouldShow = _scrollController.offset > _scrollToTopThreshold;
  if (shouldShow != _showScrollToTop) {
    setState(() => _showScrollToTop = shouldShow);
  }
}
```

In `build()`, wrap the existing body in a `Stack` and add the FAB:

```dart
Stack(
  children: [
    // ... existing RefreshIndicator + CustomScrollView ...
    Positioned(
      left: AppSpacing.md,
      bottom: AppSpacing.md,
      child: AnimatedScale(
        scale: _showScrollToTop ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: FloatingActionButton.small(
          heroTag: 'scrollToTop',
          onPressed: () {
            HapticFeedback.lightImpact();
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
          child: const Icon(LucideIcons.arrowUp, size: 18),
        ),
      ),
    ),
  ],
)
```

- [ ] **Step 2: Write test**

```dart
testWidgets('shows scroll-to-top FAB after scrolling 600px', (tester) async {
  // Setup feed with enough items to scroll
  await pumpWidget(tester, CommunityFeedList(tab: CommunityFeedTab.explore));
  await tester.pumpAndSettle();
  // Initially no FAB
  expect(find.byIcon(LucideIcons.arrowUp), findsNothing);
  // Scroll down
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
  await tester.pumpAndSettle();
  expect(find.byIcon(LucideIcons.arrowUp), findsOneWidget);
});
```

- [ ] **Step 3: Run tests and commit**

Run: `flutter test test/features/community/widgets/community_feed_list_test.dart`

```bash
git add lib/features/community/widgets/community_feed_list.dart test/
git commit -m "feat(community): add animated scroll-to-top FAB in feed"
```

---

## Task 12: Empty State Improvements

**Files:**
- Modify: `lib/features/community/widgets/community_feed_states.dart`
- Modify: `lib/features/community/widgets/community_feed_items.dart`
- Test: `test/features/community/widgets/community_feed_states_test.dart`

- [ ] **Step 1: Update FilteredFeedEmptyState with CTA buttons**

In `community_feed_states.dart`, update `FilteredFeedEmptyState.build()` to add contextual CTAs:

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

  Widget? ctaButton;
  String title;
  String hint;

  switch (tab) {
    case CommunityFeedTab.following:
      title = 'community.empty_following_title'.tr();
      hint = 'community.empty_following_hint'.tr();
      ctaButton = OutlinedButton.icon(
        onPressed: onReset,
        icon: const Icon(LucideIcons.compass, size: 16),
        label: Text('community.go_to_explore'.tr()),
      );
    case CommunityFeedTab.guides:
      title = 'community.empty_guides_title'.tr();
      hint = 'community.empty_guides_hint'.tr();
      // CTA only if founder — caller passes onReset as guide creation callback
      if (onReset != null) {
        ctaButton = FilledButton.icon(
          onPressed: onReset,
          icon: const Icon(LucideIcons.penLine, size: 16),
          label: Text('community.write_first_guide'.tr()),
        );
      } else {
        hint = 'community.guides_coming_soon'.tr();
      }
    case CommunityFeedTab.questions:
      title = 'community.empty_questions_title'.tr();
      hint = 'community.empty_questions_hint'.tr();
    default:
      title = 'community.empty_filtered_title'.tr();
      hint = 'community.empty_filtered_hint'.tr();
  }

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ... existing icon ...
          const SizedBox(height: AppSpacing.md),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(hint, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ), textAlign: TextAlign.center),
          if (ctaButton != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ctaButton,
          ],
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Update empty state in bookmarks (via shared widget)**

The shared `CommunityPostListScreen` already shows `emptyHint` — update bookmarks to use the new `bookmark_hint_action` key (already done in Task 6).

- [ ] **Step 3: Write tests**

```dart
testWidgets('following empty state shows Go to Explore CTA', (tester) async {
  await pumpWidget(tester, FilteredFeedEmptyState(
    tab: CommunityFeedTab.following,
    onReset: () {},
  ));
  await tester.pumpAndSettle();
  expect(find.text('community.go_to_explore'.tr()), findsOneWidget);
});

testWidgets('guides empty state shows write guide CTA when onReset provided', (tester) async {
  await pumpWidget(tester, FilteredFeedEmptyState(
    tab: CommunityFeedTab.guides,
    onReset: () {},
  ));
  await tester.pumpAndSettle();
  expect(find.text('community.write_first_guide'.tr()), findsOneWidget);
});

testWidgets('guides empty state shows coming soon when no onReset', (tester) async {
  await pumpWidget(tester, const FilteredFeedEmptyState(
    tab: CommunityFeedTab.guides,
  ));
  await tester.pumpAndSettle();
  expect(find.text('community.guides_coming_soon'.tr()), findsOneWidget);
});
```

- [ ] **Step 4: Run tests and commit**

Run: `flutter test test/features/community/widgets/community_feed_states_test.dart`

```bash
git add lib/features/community/widgets/community_feed_states.dart \
  lib/features/community/widgets/community_feed_items.dart \
  test/
git commit -m "feat(community): add contextual CTA buttons to empty states"
```

---

## Task 13: Skeleton Loading Consistency

**Files:**
- Modify: `lib/features/community/widgets/community_post_list_screen.dart` (already uses skeleton from Task 6)
- Modify: `lib/features/community/screens/community_search_screen.dart`
- Modify: `lib/features/community/screens/community_post_detail_screen.dart` (already uses comment skeleton from Task 4)

- [ ] **Step 1: Replace search results spinner with skeleton**

In `community_search_screen.dart`, in the `_SearchResultsBody.build()`, replace loading spinner:

```dart
// Old: if loading, show CircularProgressIndicator
// New:
if (feedState.isLoading && feedState.posts.isEmpty)
  return const CommunityFeedSkeleton(count: 2);
```

Add import for `CommunityFeedSkeleton` from `community_feed_states.dart`.

- [ ] **Step 2: Verify all loading states use skeletons**

Checklist (all should now use skeleton, not spinner):
- [x] Feed list loading → `CommunityFeedSkeleton` (already exists)
- [x] Bookmarks loading → `CommunityFeedSkeleton` (Task 6 shared widget)
- [x] User posts loading → `CommunityFeedSkeleton` (Task 6 shared widget)
- [x] Search results loading → `CommunityFeedSkeleton` (this step)
- [x] Post detail comments → `CommunityCommentSkeleton` (Task 4)

- [ ] **Step 3: Run tests and commit**

Run: `flutter test test/features/community/screens/community_search_screen_test.dart`

```bash
git add lib/features/community/screens/community_search_screen.dart test/
git commit -m "refactor(community): replace remaining loading spinners with skeleton loaders"
```

---

## Task 14: Haptic Feedback Standardization

**Files:**
- Modify: `lib/features/community/widgets/community_post_actions.dart`
- Modify: `lib/features/community/widgets/community_comment_tile.dart`
- Modify: `lib/features/community/widgets/community_user_header.dart`
- Modify: `lib/features/community/widgets/community_pill_tabs.dart`
- Modify: `lib/features/community/widgets/community_section_bar.dart`
- Modify: `lib/features/community/widgets/community_feed_list.dart`
- Modify: `lib/features/community/screens/community_create_post_screen.dart`

- [ ] **Step 1: Define haptic standard and audit**

Standard from spec:
| Action | Haptic |
|--------|--------|
| Like/bookmark/follow toggle | `HapticFeedback.lightImpact()` |
| Post submit, comment submit | `HapticFeedback.mediumImpact()` |
| Tab switch, filter/sort | `HapticFeedback.selectionClick()` |
| Delete confirmation | `HapticFeedback.heavyImpact()` |
| Report reason selection | `HapticFeedback.selectionClick()` |
| Scroll-to-top tap | `HapticFeedback.lightImpact()` |
| Pull-to-refresh trigger | `HapticFeedback.selectionClick()` |

- [ ] **Step 2: Add haptics to pill tabs**

In `community_pill_tabs.dart`, in `_PillTab` onTap:

```dart
onTap: () {
  HapticFeedback.selectionClick();
  onTap();
},
```

Add `import 'package:flutter/services.dart';`

- [ ] **Step 3: Add haptics to section bar filter chips**

In `community_section_bar.dart`, in `_FilterChip` onTap:

```dart
onTap: () {
  HapticFeedback.selectionClick();
  onTap();
},
```

- [ ] **Step 4: Add haptics to user header follow toggle**

In `community_user_header.dart`, verify follow button has `HapticFeedback.lightImpact()`. If missing, add in onPressed.

- [ ] **Step 5: Add haptics to post actions share**

In `community_post_actions.dart`, in `_onShare()`:

```dart
void _onShare() {
  HapticFeedback.lightImpact();
  // ... existing share logic ...
}
```

- [ ] **Step 6: Add haptic to delete confirmation**

In `community_comment_tile.dart`, in `_showDeleteDialog` confirmed branch:

```dart
if (confirmed == true) {
  HapticFeedback.heavyImpact();
  // ... delete logic ...
}
```

Similarly in post card delete.

- [ ] **Step 7: Add haptic to create post submit**

In `community_create_post_screen.dart`, in `_submit()`:

```dart
Future<void> _submit() async {
  // ... validation ...
  HapticFeedback.mediumImpact();
  // ... submit logic ...
}
```

- [ ] **Step 8: Run tests and commit**

Run: `flutter test test/features/community/`

```bash
git add lib/features/community/widgets/community_pill_tabs.dart \
  lib/features/community/widgets/community_section_bar.dart \
  lib/features/community/widgets/community_user_header.dart \
  lib/features/community/widgets/community_post_actions.dart \
  lib/features/community/widgets/community_comment_tile.dart \
  lib/features/community/screens/community_create_post_screen.dart \
  lib/features/community/widgets/community_feed_list.dart
git commit -m "feat(community): standardize haptic feedback across all interactions"
```

---

## Task 15: Notification Badge in AppBar

**Files:**
- Modify: `lib/features/community/widgets/community_app_bar.dart`
- Test: `test/features/community/widgets/community_app_bar_test.dart`

- [ ] **Step 1: Replace manual bell icon with NotificationBellButton**

In `community_app_bar.dart`, replace the bell `_ActionIcon` with `NotificationBellButton`:

```dart
// Old (approximately lines 60-65):
_ActionIcon(
  icon: LucideIcons.bell,
  tooltip: 'notifications.title'.tr(),
  onPressed: () => context.push('/notifications'),
),

// New:
const NotificationBellButton(),
```

Add import:
```dart
import '../../../notifications/widgets/notification_bell_button.dart';
```

Remove unused `_ActionIcon` for bell if it was only used there (keep if used for search icon too).

- [ ] **Step 2: Write test**

```dart
testWidgets('shows NotificationBellButton in app bar', (tester) async {
  await pumpWidget(tester, const CommunityScreen());
  await tester.pumpAndSettle();
  expect(find.byType(NotificationBellButton), findsOneWidget);
});
```

- [ ] **Step 3: Run tests and commit**

Run: `flutter test test/features/community/widgets/community_app_bar_test.dart`

```bash
git add lib/features/community/widgets/community_app_bar.dart test/
git commit -m "feat(community): replace manual bell icon with NotificationBellButton for unread badge"
```

---

## Final Quality Gates

- [ ] **Step 1: Run all quality checks**

```bash
flutter analyze --no-fatal-infos
python3 scripts/verify_code_quality.py
python3 scripts/check_l10n_sync.py
python3 scripts/verify_rules.py --fix
flutter test
```

All must pass with 0 errors/violations.

- [ ] **Step 2: Update codebase stats if needed**

If `verify_rules.py --fix` changes CLAUDE.md, commit:

```bash
git add CLAUDE.md
git commit -m "chore: update CLAUDE.md stats after community UX polish"
```

- [ ] **Step 3: Final commit summary**

Expected commits from this plan:
1. `feat(l10n): add 24 community UX polish translation keys`
2. `feat(community): add search debounce (400ms) and search history`
3. `feat(community): add draft auto-save with restore dialog and back confirmation`
4. `feat(community): add cursor-based comment pagination with skeleton loading`
5. `fix(community): eliminate search TabBar layout shift with AnimatedOpacity`
6. `refactor(community): extract shared CommunityPostListScreen, dedup bookmarks and user posts`
7. `feat(community): add scale bounce animations for like and bookmark toggles`
8. `feat(community): add fade transition animation for tab switches`
9. `feat(community): redesign report dialog as card-based bottom sheet`
10. `feat(community): enrich comment input with character counter, focus animation, scroll-to-new`
11. `feat(community): add animated scroll-to-top FAB in feed`
12. `feat(community): add contextual CTA buttons to empty states`
13. `refactor(community): replace remaining loading spinners with skeleton loaders`
14. `feat(community): standardize haptic feedback across all interactions`
15. `feat(community): replace manual bell icon with NotificationBellButton for unread badge`
16. `chore: update CLAUDE.md stats after community UX polish` (if needed)
