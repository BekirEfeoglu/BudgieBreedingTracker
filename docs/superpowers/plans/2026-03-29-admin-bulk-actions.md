# Admin Bulk User Actions — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add multi-select and bulk actions (activate/deactivate, premium grant/revoke, export, delete) to the admin users screen.

**Architecture:** New selection provider + bulk action methods in existing notifier + UI changes to users screen and card widget.

**Tech Stack:** Flutter/Dart, Riverpod 3, Supabase, easy_localization

**Spec:** `docs/superpowers/specs/2026-03-29-admin-bulk-actions-design.md`

---

## File Map

### New Files
| File | Responsibility |
|------|---------------|
| `lib/features/admin/providers/admin_user_selection_provider.dart` | Selection state (Set<String> of user IDs) |
| `test/features/admin/providers/admin_user_selection_test.dart` | Selection provider tests |

### Modified Files
| File | Changes |
|------|---------|
| `lib/features/admin/providers/admin_actions_provider.dart` | Add bulk action methods |
| `lib/features/admin/providers/admin_providers.dart` | Export selection provider |
| `lib/features/admin/screens/admin_users_screen.dart` | Selection mode UI, action bar |
| `lib/features/admin/screens/admin_users_screen_card.dart` | Checkbox, selection highlight |
| `assets/translations/tr.json` | 12 new keys |
| `assets/translations/en.json` | 12 new keys |
| `assets/translations/de.json` | 12 new keys |
| `test/features/admin/screens/admin_users_screen_test.dart` | Selection mode tests |

---

## Task 1: Create Selection Provider

**Files:**
- Create: `lib/features/admin/providers/admin_user_selection_provider.dart`
- Modify: `lib/features/admin/providers/admin_providers.dart`

- [ ] **Step 1: Create the selection provider file**

```dart
// lib/features/admin/providers/admin_user_selection_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the set of selected user IDs for bulk actions.
class AdminUserSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Toggle a user in/out of the selection.
  void toggle(String userId) {
    state = state.contains(userId)
        ? (Set<String>.of(state)..remove(userId))
        : (Set<String>.of(state)..add(userId));
  }

  /// Select all provided user IDs.
  void selectAll(List<String> ids) => state = Set<String>.of(ids);

  /// Clear all selections.
  void clear() => state = const {};
}

/// Provider for user selection state.
final adminUserSelectionProvider =
    NotifierProvider<AdminUserSelectionNotifier, Set<String>>(
  AdminUserSelectionNotifier.new,
);

/// Whether any users are currently selected.
final isSelectionActiveProvider = Provider<bool>((ref) {
  return ref.watch(adminUserSelectionProvider).isNotEmpty;
});

/// Count of currently selected users.
final selectedUserCountProvider = Provider<int>((ref) {
  return ref.watch(adminUserSelectionProvider).length;
});
```

- [ ] **Step 2: Add export to barrel file**

In `lib/features/admin/providers/admin_providers.dart`, add:
```dart
export 'admin_user_selection_provider.dart';
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 4: Commit**

```bash
git add lib/features/admin/providers/admin_user_selection_provider.dart lib/features/admin/providers/admin_providers.dart
git commit -m "feat(admin): add user selection provider for bulk actions"
```

---

## Task 2: Add Bulk Action Methods

**Files:**
- Modify: `lib/features/admin/providers/admin_actions_provider.dart`

- [ ] **Step 1: Add bulk action methods to AdminActionsNotifier**

Read the current file first. Add these methods after the existing `clearAuditLogs` method (before `reset()`):

```dart
/// Bulk activate or deactivate users. Skips protected roles.
Future<({int succeeded, int skipped})> bulkToggleActive(
  Set<String> userIds, {
  required bool activate,
}) async {
  var succeeded = 0;
  var skipped = 0;
  state = state.copyWith(isLoading: true, error: null, isSuccess: false);

  try {
    for (final userId in userIds) {
      try {
        await _userManager.toggleUserActive(userId, isActive: activate);
        succeeded++;
      } catch (e) {
        if (e.toString().contains('protected')) {
          skipped++;
        } else {
          rethrow;
        }
      }
    }
    state = state.copyWith(isLoading: false, isSuccess: true);
    ref.invalidate(adminUsersProvider);
    return (succeeded: succeeded, skipped: skipped);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    return (succeeded: succeeded, skipped: skipped);
  }
}

/// Bulk grant premium to users. Skips protected roles.
Future<({int succeeded, int skipped})> bulkGrantPremium(
  Set<String> userIds,
) async {
  var succeeded = 0;
  var skipped = 0;
  state = state.copyWith(isLoading: true, error: null, isSuccess: false);

  try {
    for (final userId in userIds) {
      try {
        await _userManager.grantPremium(userId);
        succeeded++;
      } catch (e) {
        if (e.toString().contains('protected')) {
          skipped++;
        } else {
          rethrow;
        }
      }
    }
    state = state.copyWith(isLoading: false, isSuccess: true);
    ref.invalidate(adminUsersProvider);
    return (succeeded: succeeded, skipped: skipped);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    return (succeeded: succeeded, skipped: skipped);
  }
}

/// Bulk revoke premium from users. Skips protected roles.
Future<({int succeeded, int skipped})> bulkRevokePremium(
  Set<String> userIds,
) async {
  var succeeded = 0;
  var skipped = 0;
  state = state.copyWith(isLoading: true, error: null, isSuccess: false);

  try {
    for (final userId in userIds) {
      try {
        await _userManager.revokePremium(userId);
        succeeded++;
      } catch (e) {
        if (e.toString().contains('protected')) {
          skipped++;
        } else {
          rethrow;
        }
      }
    }
    state = state.copyWith(isLoading: false, isSuccess: true);
    ref.invalidate(adminUsersProvider);
    return (succeeded: succeeded, skipped: skipped);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    return (succeeded: succeeded, skipped: skipped);
  }
}

/// Bulk export selected users' data.
Future<String> bulkExport(
  Set<String> userIds, {
  ExportFormat format = ExportFormat.json,
}) async {
  state = state.copyWith(isLoading: true, error: null, isSuccess: false);
  try {
    final client = ref.read(supabaseClientProvider);
    final rows = await client
        .from(SupabaseConstants.profilesTable)
        .select('id, email, full_name, avatar_url, created_at, is_active')
        .inFilter('id', userIds.toList());
    state = state.copyWith(isLoading: false, isSuccess: true);
    final data = List<Map<String, dynamic>>.from(rows);
    return format == ExportFormat.csv ? _toCsv(data) : jsonEncode(data);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    return '';
  }
}

/// Bulk delete all data for selected users. Founder-only.
/// Uses reset_user_data RPC per user. Skips protected roles.
Future<({int succeeded, int skipped})> bulkDeleteUserData(
  Set<String> userIds,
) async {
  var succeeded = 0;
  var skipped = 0;
  state = state.copyWith(isLoading: true, error: null, isSuccess: false);

  try {
    for (final userId in userIds) {
      try {
        await _databaseManager.resetAllUserData(userId);
        succeeded++;
      } catch (e) {
        if (e.toString().contains('protected')) {
          skipped++;
        } else {
          AppLogger.error('admin', 'Bulk delete failed for $userId', e);
          skipped++;
        }
      }
    }
    state = state.copyWith(isLoading: false, isSuccess: true);
    ref.invalidate(adminUsersProvider);
    return (succeeded: succeeded, skipped: skipped);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
    return (succeeded: succeeded, skipped: skipped);
  }
}
```

Also add missing imports at the top if needed:
```dart
import 'dart:convert';
import '../../../core/constants/supabase_constants.dart';
import '../../auth/providers/auth_providers.dart';
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 3: Commit**

```bash
git add lib/features/admin/providers/admin_actions_provider.dart
git commit -m "feat(admin): add bulk action methods for user management"
```

---

## Task 3: Add Localization Keys

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add keys to tr.json**

In the `"admin"` section, add:
```json
"bulk_actions": "Toplu Islemler",
"selected_count": "{} secildi",
"select_all": "Tumunu Sec",
"clear_selection": "Secimi Temizle",
"bulk_activate": "Aktif Et",
"bulk_deactivate": "Deaktif Et",
"bulk_grant_premium": "Premium Ver",
"bulk_revoke_premium": "Premium Kaldir",
"bulk_export": "Disa Aktar",
"bulk_delete": "Verileri Sil",
"bulk_delete_confirm": "Silmek icin {} yazin",
"protected_users_skipped": "{} korunmus kullanici atlandi"
```

- [ ] **Step 2: Add keys to en.json**

```json
"bulk_actions": "Bulk Actions",
"selected_count": "{} selected",
"select_all": "Select All",
"clear_selection": "Clear Selection",
"bulk_activate": "Activate",
"bulk_deactivate": "Deactivate",
"bulk_grant_premium": "Grant Premium",
"bulk_revoke_premium": "Revoke Premium",
"bulk_export": "Export",
"bulk_delete": "Delete Data",
"bulk_delete_confirm": "Type {} to confirm",
"protected_users_skipped": "{} protected user(s) skipped"
```

- [ ] **Step 3: Add keys to de.json**

```json
"bulk_actions": "Massenaktionen",
"selected_count": "{} ausgewaehlt",
"select_all": "Alle auswaehlen",
"clear_selection": "Auswahl aufheben",
"bulk_activate": "Aktivieren",
"bulk_deactivate": "Deaktivieren",
"bulk_grant_premium": "Premium gewaehren",
"bulk_revoke_premium": "Premium entziehen",
"bulk_export": "Exportieren",
"bulk_delete": "Daten loeschen",
"bulk_delete_confirm": "Geben Sie {} ein um zu bestaetigen",
"protected_users_skipped": "{} geschuetzte Benutzer uebersprungen"
```

- [ ] **Step 4: Verify sync**

Run: `python scripts/check_l10n_sync.py`

- [ ] **Step 5: Commit**

```bash
git add assets/translations/
git commit -m "feat(l10n): add bulk action translation keys for tr/en/de"
```

---

## Task 4: Update User Card — Selection Support

**Files:**
- Modify: `lib/features/admin/screens/admin_users_screen_card.dart`

This is a `part of` file — it shares imports with `admin_users_screen.dart`.

- [ ] **Step 1: Update _UserCard to support selection mode**

Read the current file. Modify the `_UserCard` widget:

1. Add parameters: `bool isSelected`, `bool isSelectionMode`, `VoidCallback? onSelectionToggle`
2. Wrap the existing content in a Row with an optional Checkbox
3. Change InkWell.onTap: in selection mode → toggle selection, normal mode → navigate to detail
4. Add long-press to enter selection mode: `onLongPress: onSelectionToggle`
5. Add selection highlight: when `isSelected`, add a subtle primary color background

The updated class:

```dart
part of 'admin_users_screen.dart';

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onSelectionToggle;

  const _UserCard({
    required this.user,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = user.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final fullName = user.fullName?.trim();
    final displayName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : user.email;
    final showEmail = displayName.toLowerCase() != user.email.toLowerCase();

    return Card(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: isSelectionMode
            ? onSelectionToggle
            : () => context.push(
                  AppRoutes.adminUserDetail.replaceFirst(':userId', user.id),
                ),
        onLongPress: onSelectionToggle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelectionToggle?.call(),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: hasAvatar
                    ? CachedNetworkImageProvider(
                        avatarUrl,
                        maxWidth: 88,
                        maxHeight: 88,
                      )
                    : null,
                child: !hasAvatar
                    ? AppIcon(
                        AppIcons.users,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!user.isActive) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              'admin.inactive'.tr(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (showEmail) ...[
                      const SizedBox(height: AppSpacing.xs / 2),
                      Text(
                        user.email,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${'admin.joined'.tr()}: ${_formatDate(context, user.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!isSelectionMode) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy', locale).format(date);
  }
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 3: Commit**

```bash
git add lib/features/admin/screens/admin_users_screen_card.dart
git commit -m "feat(admin): add selection mode support to user card"
```

---

## Task 5: Update Users Screen — Selection Mode and Action Bar

**Files:**
- Modify: `lib/features/admin/screens/admin_users_screen.dart`

This is the most complex task. Read the current file first.

- [ ] **Step 1: Add selection mode state and methods to _AdminUsersScreenState**

Add after existing state variables (around line 43):

```dart
bool get _isSelectionMode => ref.read(isSelectionActiveProvider);

void _toggleSelection(String userId) {
  ref.read(adminUserSelectionProvider.notifier).toggle(userId);
}

void _selectAllVisible(List<AdminUser> users) {
  ref.read(adminUserSelectionProvider.notifier)
      .selectAll(users.map((u) => u.id).toList());
}

void _clearSelection() {
  ref.read(adminUserSelectionProvider.notifier).clear();
}
```

- [ ] **Step 2: Update build method — add selection-aware AppBar and BottomAppBar**

In the `build()` method, watch the selection provider:

```dart
final selectedIds = ref.watch(adminUserSelectionProvider);
final isSelectionMode = selectedIds.isNotEmpty;
final selectedCount = selectedIds.length;
```

Wrap the existing `Scaffold` to conditionally show:
- When selection mode: AppBar title shows `"$selectedCount ${'admin.selected_count'.tr()}"`, actions show "Select All" and "Clear" buttons
- A `bottomNavigationBar` with the bulk action buttons when selection is active

The `bottomNavigationBar` widget:

```dart
bottomNavigationBar: isSelectionMode
    ? _BulkActionBar(
        selectedIds: selectedIds,
        onClearSelection: _clearSelection,
      )
    : null,
```

- [ ] **Step 3: Update _UsersList to pass selection state to _UserCard**

In the `_UsersList` part file (or in the build method where `_UserCard` is created), update the card instantiation:

```dart
_UserCard(
  user: user,
  isSelected: selectedIds.contains(user.id),
  isSelectionMode: isSelectionMode,
  onSelectionToggle: () => _toggleSelection(user.id),
)
```

- [ ] **Step 4: Create _BulkActionBar widget**

Add at the bottom of `admin_users_screen.dart` (or in a part file):

```dart
class _BulkActionBar extends ConsumerWidget {
  final Set<String> selectedIds;
  final VoidCallback onClearSelection;

  const _BulkActionBar({
    required this.selectedIds,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFounder = ref.watch(isFounderProvider).valueOrNull ?? false;
    final actionState = ref.watch(adminActionsProvider);

    return BottomAppBar(
      child: actionState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                children: [
                  _BulkActionChip(
                    icon: LucideIcons.userCheck,
                    label: 'admin.bulk_activate'.tr(),
                    onPressed: () => _confirmAndRun(
                      context, ref,
                      title: 'admin.bulk_activate'.tr(),
                      message: 'admin.selected_count'.tr(args: ['${selectedIds.length}']),
                      action: () async {
                        final result = await ref
                            .read(adminActionsProvider.notifier)
                            .bulkToggleActive(selectedIds, activate: true);
                        _showResult(context, result);
                        onClearSelection();
                      },
                    ),
                  ),
                  _BulkActionChip(
                    icon: LucideIcons.userX,
                    label: 'admin.bulk_deactivate'.tr(),
                    onPressed: () => _confirmAndRun(
                      context, ref,
                      title: 'admin.bulk_deactivate'.tr(),
                      message: 'admin.selected_count'.tr(args: ['${selectedIds.length}']),
                      action: () async {
                        final result = await ref
                            .read(adminActionsProvider.notifier)
                            .bulkToggleActive(selectedIds, activate: false);
                        _showResult(context, result);
                        onClearSelection();
                      },
                    ),
                  ),
                  _BulkActionChip(
                    icon: LucideIcons.crown,
                    label: 'admin.bulk_grant_premium'.tr(),
                    onPressed: () => _confirmAndRun(
                      context, ref,
                      title: 'admin.bulk_grant_premium'.tr(),
                      message: 'admin.selected_count'.tr(args: ['${selectedIds.length}']),
                      action: () async {
                        final result = await ref
                            .read(adminActionsProvider.notifier)
                            .bulkGrantPremium(selectedIds);
                        _showResult(context, result);
                        onClearSelection();
                      },
                    ),
                  ),
                  _BulkActionChip(
                    icon: LucideIcons.crownOff,
                    label: 'admin.bulk_revoke_premium'.tr(),
                    onPressed: () => _confirmAndRun(
                      context, ref,
                      title: 'admin.bulk_revoke_premium'.tr(),
                      message: 'admin.selected_count'.tr(args: ['${selectedIds.length}']),
                      action: () async {
                        final result = await ref
                            .read(adminActionsProvider.notifier)
                            .bulkRevokePremium(selectedIds);
                        _showResult(context, result);
                        onClearSelection();
                      },
                    ),
                  ),
                  _BulkActionChip(
                    icon: LucideIcons.download,
                    label: 'admin.bulk_export'.tr(),
                    onPressed: () async {
                      final data = await ref
                          .read(adminActionsProvider.notifier)
                          .bulkExport(selectedIds);
                      if (data.isNotEmpty && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('admin.bulk_export'.tr())),
                        );
                      }
                      onClearSelection();
                    },
                  ),
                  if (isFounder)
                    _BulkActionChip(
                      icon: LucideIcons.trash2,
                      label: 'admin.bulk_delete'.tr(),
                      isDestructive: true,
                      onPressed: () => _confirmDelete(context, ref),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmAndRun(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final confirmed = await showConfirmDialog(
      context,
      title: title,
      message: message,
    );
    if (confirmed == true) await action();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final count = selectedIds.length;
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.bulk_delete'.tr(),
      message: 'admin.bulk_delete_confirm'.tr(args: ['$count']),
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(adminActionsProvider.notifier)
        .bulkDeleteUserData(selectedIds);
    if (context.mounted) _showResult(context, result);
    onClearSelection();
  }

  void _showResult(BuildContext context, ({int succeeded, int skipped}) result) {
    final message = StringBuffer();
    message.write('${result.succeeded} OK');
    if (result.skipped > 0) {
      message.write(', ');
      message.write('admin.protected_users_skipped'.tr(args: ['${result.skipped}']));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.toString())),
    );
  }
}

class _BulkActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  const _BulkActionChip({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 12)),
        onPressed: onPressed,
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
    );
  }
}
```

- [ ] **Step 5: Update AppBar for selection mode**

In the build method, modify the Scaffold's AppBar section. When `isSelectionMode`:
- Title: `Text('admin.selected_count'.tr(args: ['$selectedCount']))`
- Leading: Close button that calls `_clearSelection()`
- Actions: "Select All" button

```dart
appBar: isSelectionMode
    ? AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          tooltip: 'admin.clear_selection'.tr(),
          onPressed: _clearSelection,
        ),
        title: Text('admin.selected_count'.tr(args: ['$selectedCount'])),
        actions: [
          TextButton(
            onPressed: () => _selectAllVisible(filteredUsers),
            child: Text('admin.select_all'.tr()),
          ),
        ],
      )
    : null,  // Keep existing null (screen inherits AppBar from AdminShell)
```

Note: The screen may not have its own AppBar (it's inside AdminShell). In that case, show the selection bar as an overlay or prepend a selection header row before the toolbar. Read the current code to determine the correct placement.

- [ ] **Step 6: Verify compilation**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 7: Commit**

```bash
git add lib/features/admin/screens/
git commit -m "feat(admin): add bulk action UI with selection mode and action bar"
```

---

## Task 6: Tests

**Files:**
- Create: `test/features/admin/providers/admin_user_selection_test.dart`
- Modify: `test/features/admin/screens/admin_users_screen_test.dart`

- [ ] **Step 1: Create selection provider tests**

```dart
// test/features/admin/providers/admin_user_selection_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_user_selection_provider.dart';

void main() {
  group('AdminUserSelectionNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty set', () {
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('toggle adds user to selection', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(adminUserSelectionProvider), {'user-1'});
    });

    test('toggle removes user from selection', () {
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('selectAll replaces selection', () {
      container.read(adminUserSelectionProvider.notifier).toggle('old');
      container.read(adminUserSelectionProvider.notifier)
          .selectAll(['a', 'b', 'c']);
      expect(container.read(adminUserSelectionProvider), {'a', 'b', 'c'});
    });

    test('clear empties selection', () {
      container.read(adminUserSelectionProvider.notifier)
          .selectAll(['a', 'b']);
      container.read(adminUserSelectionProvider.notifier).clear();
      expect(container.read(adminUserSelectionProvider), isEmpty);
    });

    test('isSelectionActiveProvider reflects state', () {
      expect(container.read(isSelectionActiveProvider), isFalse);
      container.read(adminUserSelectionProvider.notifier).toggle('user-1');
      expect(container.read(isSelectionActiveProvider), isTrue);
    });

    test('selectedUserCountProvider reflects count', () {
      expect(container.read(selectedUserCountProvider), 0);
      container.read(adminUserSelectionProvider.notifier)
          .selectAll(['a', 'b', 'c']);
      expect(container.read(selectedUserCountProvider), 3);
    });
  });
}
```

- [ ] **Step 2: Run tests**

```bash
flutter test test/features/admin/providers/admin_user_selection_test.dart
```

- [ ] **Step 3: Commit**

```bash
git add test/features/admin/providers/admin_user_selection_test.dart
git commit -m "test(admin): add selection provider tests for bulk actions"
```

---

## Task 7: Final Verification

- [ ] **Step 1: Run analysis**

Run: `flutter analyze --no-fatal-infos`

- [ ] **Step 2: Run all admin tests**

Run: `flutter test test/features/admin/`

- [ ] **Step 3: Run l10n sync**

Run: `python scripts/check_l10n_sync.py`

- [ ] **Step 4: Commit if needed**

```bash
git status
```
