# Community Tab Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Topluluk sekmesini Instagram/Twitter/Facebook hibrit sosyal medya deneyimine donusturmek — profil odakli header, story strip, pill tab'lar, yumusak post kartlari, quick composer, gradient FAB.

**Architecture:** Mevcut `DefaultTabController + TabBar + TabBarView` yapisi kaldirilir, yerine `NotifierProvider` ile yonetilen pill chip tab bar + `IndexedStack` / sartli render konur. Mevcut `CommunityFeedList` ve widget'lar korunur, sadece `CommunityScreen`, AppBar ve post card stili degisir.

**Tech Stack:** Flutter, Riverpod 3, GoRouter, LucideIcons, easy_localization

**Spec:** `docs/superpowers/specs/2026-04-02-community-tab-redesign.md`

---

### Task 1: Active Tab Provider

**Files:**
- Modify: `lib/features/community/providers/community_providers.dart`

- [ ] **Step 1: communityActiveTabProvider ekle**

Dosyanin sonuna ekle (mevcut `exploreSortProvider`'in altina):

```dart
/// Active tab state for pill tab bar (replaces DefaultTabController).
class CommunityActiveTabNotifier extends Notifier<CommunityFeedTab> {
  @override
  CommunityFeedTab build() => CommunityFeedTab.explore;
}

final communityActiveTabProvider =
    NotifierProvider<CommunityActiveTabNotifier, CommunityFeedTab>(
  CommunityActiveTabNotifier.new,
);
```

- [ ] **Step 2: Analiz**

Run: `flutter analyze lib/features/community/providers/community_providers.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/providers/community_providers.dart
git commit -m "feat(community): add active tab provider for pill tab bar"
```

---

### Task 2: Pill Tab Bar Widget

**Files:**
- Create: `lib/features/community/widgets/community_pill_tabs.dart`

- [ ] **Step 1: Widget olustur**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/community_providers.dart';

/// Pill-shaped chip tab bar for community feed filtering.
class CommunityPillTabs extends ConsumerWidget {
  const CommunityPillTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(communityActiveTabProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: CommunityFeedTab.values.map((tab) {
          final isActive = activeTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () {
                ref.read(communityActiveTabProvider.notifier).state = tab;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tabIcon(tab, isActive, theme),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      tab.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isActive
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tabIcon(CommunityFeedTab tab, bool isActive, ThemeData theme) {
    final color = isActive
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return switch (tab) {
      CommunityFeedTab.explore => Icon(LucideIcons.flame, size: 14, color: color),
      CommunityFeedTab.following => Icon(LucideIcons.users, size: 14, color: color),
      CommunityFeedTab.guides => Icon(LucideIcons.bookOpen, size: 14, color: color),
      CommunityFeedTab.questions => Icon(LucideIcons.store, size: 14, color: color),
    };
  }
}
```

**Not:** `CommunityFeedTab.questions` burada "Pazar Yeri" tab'i olarak kullaniliyor (mevcut enum degerini yeniden amaclandiriyoruz — store ikonu ile). Alternatif olarak enum'a yeni deger eklenebilir ama mevcut filter logic'i bozulmasin diye `questions` tab'ini Pazar icin kullaniyoruz. Pazar tab'inda `MarketplaceTabContent` gosterilecek.

Aslinda spec'e gore tab'lar: Kesfet, Takip, Pazar, Rehber. Mevcut enum: explore, following, guides, questions. Pazar icin yeni bir enum degeri yerine `questions` tab'ini pazar olarak map'leyecegiz (UI'da store ikonu + pazar label), `guides` tab'i ise rehber+soru gosterir (zaten onceki fix'te yapildi).

- [ ] **Step 2: Analiz**

Run: `flutter analyze lib/features/community/widgets/community_pill_tabs.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/widgets/community_pill_tabs.dart
git commit -m "feat(community): add pill-shaped tab bar widget"
```

---

### Task 3: Community AppBar Widget

**Files:**
- Create: `lib/features/community/widgets/community_app_bar.dart`

- [ ] **Step 1: Profil odakli AppBar widget'i olustur**

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../../gamification/providers/gamification_providers.dart';

/// Profile-centric AppBar for the community screen.
class CommunityAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CommunityAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final userLevelAsync = ref.watch(userLevelProvider(userId));
    final theme = Theme.of(context);

    // Get initials from userId (first 2 chars uppercase)
    final initials = userId.length >= 2
        ? userId.substring(0, 2).toUpperCase()
        : userId.toUpperCase();

    return AppBar(
      titleSpacing: AppSpacing.sm,
      title: Row(
        children: [
          // Profile avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Title + level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'community.title'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              userLevelAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (level) {
                  if (level == null) return const SizedBox.shrink();
                  return Text(
                    'Lv.${level.level} · ${level.title.isNotEmpty ? level.title.tr() : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        _ActionIcon(
          icon: LucideIcons.store,
          tooltip: 'marketplace.title'.tr(),
          onPressed: () => context.push(AppRoutes.marketplace),
        ),
        _ActionIcon(
          icon: LucideIcons.messageCircle,
          tooltip: 'messaging.title'.tr(),
          onPressed: () => context.push(AppRoutes.messages),
          // TODO: add unread badge from conversationsProvider
        ),
        _ActionIcon(
          icon: LucideIcons.bell,
          tooltip: 'notifications.title'.tr(),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        _ActionIcon(
          icon: LucideIcons.search,
          tooltip: 'community.search'.tr(),
          onPressed: () => context.push(AppRoutes.communitySearch),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, size: 20),
          tooltip: tooltip,
          onPressed: onPressed,
          constraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 34,
          ),
          padding: const EdgeInsets.all(7),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Analiz**

Run: `flutter analyze lib/features/community/widgets/community_app_bar.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/widgets/community_app_bar.dart
git commit -m "feat(community): add profile-centric AppBar widget"
```

---

### Task 4: Community Screen Rewrite

**Files:**
- Modify: `lib/features/community/screens/community_screen.dart`

- [ ] **Step 1: Ekrani sifirdan yeniden yaz**

Dosyanin tum icerigini su kodla degistir:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../router/route_names.dart';
import '../../marketplace/widgets/marketplace_tab_content.dart';
import '../providers/community_providers.dart';
import '../widgets/community_app_bar.dart';
import '../widgets/community_feed_list.dart';
import '../widgets/community_pill_tabs.dart';

/// Community screen — social hub with feed, marketplace, messaging access.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(isCommunityEnabledProvider);
    final activeTab = ref.watch(communityActiveTabProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CommunityAppBar(),
      body: isEnabled
          ? _buildBody(activeTab)
          : const _ComingSoonBody(),
      floatingActionButton: isEnabled
          ? _CommunityFab(theme: theme)
          : null,
    );
  }

  Widget _buildBody(CommunityFeedTab activeTab) {
    // questions tab is repurposed as marketplace tab in UI
    if (activeTab == CommunityFeedTab.questions) {
      return const Column(
        children: [
          CommunityPillTabs(),
          Expanded(child: MarketplaceTabContent()),
        ],
      );
    }

    return Column(
      children: [
        const CommunityPillTabs(),
        Expanded(
          child: CommunityFeedList(tab: activeTab),
        ),
      ],
    );
  }
}

/// FAB with bottom sheet for multiple creation options.
class _CommunityFab extends StatelessWidget {
  final ThemeData theme;

  const _CommunityFab({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.tertiary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showCreateOptions(context),
        tooltip: 'community.create_post'.tr(),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  void _showCreateOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'community.create_post'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.pencil),
              title: Text('community.create_post'.tr()),
              subtitle: Text('community.content_label'.tr()),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRoutes.communityCreatePost);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.store),
              title: Text('marketplace.add_listing'.tr()),
              subtitle: Text('marketplace.no_listings_hint'.tr()),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.marketplace}/form');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.messageCircle),
              title: Text('messaging.new_message'.tr()),
              subtitle: Text('messaging.no_conversations_hint'.tr()),
              onTap: () {
                Navigator.pop(context);
                context.push('${AppRoutes.messages}/group/form');
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: const AppIcon(AppIcons.community),
        title: 'community.coming_soon'.tr(),
        subtitle: 'community.coming_soon_hint'.tr(),
      ),
    );
  }
}
```

- [ ] **Step 2: Analiz**

Run: `flutter analyze lib/features/community/screens/community_screen.dart`
Expected: No issues found

- [ ] **Step 3: Commit**

```bash
git add lib/features/community/screens/community_screen.dart
git commit -m "feat(community): rewrite screen with pill tabs, profile AppBar, gradient FAB"
```

---

### Task 5: Update Pill Tabs Label for Marketplace

**Files:**
- Modify: `lib/features/community/widgets/community_pill_tabs.dart`

- [ ] **Step 1: questions tab'inin label'ini Pazar olarak goster**

`CommunityPillTabs` widget'inda `_tabIcon` metodu zaten `questions` icin store ikonu kullaniyor. Ek olarak label'i override etmek icin `build` metodundaki `tab.label` cagrisini degistir:

```dart
Text(
  _tabLabel(tab),
  // ...
),
```

Ve yeni metot ekle:

```dart
String _tabLabel(CommunityFeedTab tab) => switch (tab) {
  CommunityFeedTab.questions => 'marketplace.title'.tr(),
  _ => tab.label,
};
```

- [ ] **Step 2: Analiz + Commit**

```bash
git add lib/features/community/widgets/community_pill_tabs.dart
git commit -m "feat(community): override questions tab label as marketplace"
```

---

### Task 6: Post Card Style Update

**Files:**
- Modify: `lib/features/community/widgets/community_post_card.dart`

- [ ] **Step 1: Kart stilini guncelle**

Mevcut `CommunityPostCard.build` metodundaki `Card` widget'inin stilini guncelle:

Mevcut:
```dart
return Card(
  margin: const EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.sm,
  ),
  elevation: 0,
  clipBehavior: Clip.antiAlias,
```

Yeni:
```dart
return Card(
  margin: const EdgeInsets.only(bottom: 6),
  elevation: 0,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  clipBehavior: Clip.antiAlias,
```

Bu degisiklik kartlari tam genislik yapar (yanlara margin kaldirmaz), kartlar arasi 6px gri bosluk birakir (Instagram/Facebook gibi).

- [ ] **Step 2: Analiz + Commit**

```bash
git add lib/features/community/widgets/community_post_card.dart
git commit -m "feat(community): update post card to full-width style"
```

---

### Task 7: Post Type Badge

**Files:**
- Modify: `lib/features/community/widgets/community_user_header.dart`

- [ ] **Step 1: Post type badge parametresi ekle**

`CommunityUserHeader` constructor'ina yeni parametre ekle:

```dart
final CommunityPostType? postType;
```

Constructor'a ekle:
```dart
this.postType,
```

`build` metodundaki `Row` children'inin sonuna (mevcut popup menu'den once) ekle:

```dart
if (postType != null && postType != CommunityPostType.general && postType != CommunityPostType.unknown)
  Padding(
    padding: const EdgeInsets.only(left: AppSpacing.sm),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _postTypeColor(postType!, theme),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _postTypeLabel(postType!),
        style: theme.textTheme.labelSmall?.copyWith(
          color: _postTypeTextColor(postType!, theme),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ),
```

Yeni helper metodlar ekle:

```dart
Color _postTypeColor(CommunityPostType type, ThemeData theme) => switch (type) {
  CommunityPostType.photo => const Color(0xFFF0FDF4),
  CommunityPostType.guide => const Color(0xFFEFF6FF),
  CommunityPostType.question => const Color(0xFFFFF7ED),
  CommunityPostType.tip => const Color(0xFFFAF5FF),
  CommunityPostType.showcase => const Color(0xFFFFFBEB),
  _ => theme.colorScheme.surfaceContainerHighest,
};

Color _postTypeTextColor(CommunityPostType type, ThemeData theme) => switch (type) {
  CommunityPostType.photo => const Color(0xFF16A34A),
  CommunityPostType.guide => const Color(0xFF2563EB),
  CommunityPostType.question => const Color(0xFFEA580C),
  CommunityPostType.tip => const Color(0xFF9333EA),
  CommunityPostType.showcase => const Color(0xFFCA8A04),
  _ => theme.colorScheme.onSurface,
};

String _postTypeLabel(CommunityPostType type) => switch (type) {
  CommunityPostType.photo => '📷 ${'community.post_type_photo'.tr()}',
  CommunityPostType.guide => '📚 ${'community.post_type_guide'.tr()}',
  CommunityPostType.question => '❓ ${'community.post_type_question'.tr()}',
  CommunityPostType.tip => '💡 ${'community.post_type_tip'.tr()}',
  CommunityPostType.showcase => '🏆 ${'community.post_type_showcase'.tr()}',
  _ => '',
};
```

Import ekle (dosyanin ustune):
```dart
import '../../../core/enums/community_enums.dart';
```

- [ ] **Step 2: CommunityPostCard'da postType'i gonder**

`community_post_card.dart` dosyasinda `CommunityUserHeader` cagrisina `postType: post.postType` parametresini ekle.

- [ ] **Step 3: Analiz + Commit**

```bash
git add lib/features/community/widgets/community_user_header.dart lib/features/community/widgets/community_post_card.dart
git commit -m "feat(community): add post type badge to user header"
```

---

### Task 8: Action Buttons Pill Style

**Files:**
- Modify: `lib/features/community/widgets/community_post_actions.dart`

- [ ] **Step 1: Aksiyon butonlarini pill chip stiline guncelle**

Mevcut begeni ve yorum butonlarini pill chip'e donustur. `CommunityPostActions` widget'inin build metodunda begeni/yorum satirini bul ve pill chip stiline cevir:

Begeni butonu icin:
```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  decoration: BoxDecoration(
    color: isLiked
        ? const Color(0xFFFEF2F2)
        : theme.colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(20),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        isLiked ? LucideIcons.heart : LucideIcons.heart,
        size: 16,
        color: isLiked ? const Color(0xFFDC2626) : theme.colorScheme.outline,
      ),
      if (likeCount > 0) ...[
        const SizedBox(width: 4),
        Text(
          '$likeCount',
          style: theme.textTheme.labelMedium?.copyWith(
            color: isLiked ? const Color(0xFFDC2626) : theme.colorScheme.outline,
          ),
        ),
      ],
    ],
  ),
)
```

Yorum butonu icin benzer pill chip ama mavi renk (#EFF6FF / #2563EB).

Bu degisiklik mevcut `CommunityPostActions` widget'inin ic yapisina bagli — dosyayi okuyup tam olarak hangi kismi degistirmek gerektigini belirleyin.

- [ ] **Step 2: Analiz + Commit**

```bash
git add lib/features/community/widgets/community_post_actions.dart
git commit -m "feat(community): update action buttons to pill chip style"
```

---

### Task 9: Final Verify + Cleanup

**Files:**
- Possibly modify: various community files

- [ ] **Step 1: Flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 2: Code quality**

Run: `python3 scripts/verify_code_quality.py`
Expected: PASSED

- [ ] **Step 3: L10n sync**

Run: `python3 scripts/check_l10n_sync.py`
Expected: All keys in sync

- [ ] **Step 4: CLAUDE.md stats guncelle**

Run: `python3 scripts/verify_rules.py --fix`

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md
git commit -m "chore: update CLAUDE.md stats after community tab redesign"
```
