# Admin Bulk User Actions — Design Spec

**Date:** 2026-03-29
**Scope:** Add multi-select and bulk actions to admin users screen
**Depends on:** Admin panel improvements (completed 2026-03-29)

---

## 1. State Management

### Selection Provider

New file: `lib/features/admin/providers/admin_user_selection_provider.dart`

```dart
class AdminUserSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String userId) {
    state = state.contains(userId)
        ? (Set.of(state)..remove(userId))
        : (Set.of(state)..add(userId));
  }

  void selectAll(List<String> ids) => state = Set.of(ids);
  void clear() => state = {};
}

final adminUserSelectionProvider =
    NotifierProvider<AdminUserSelectionNotifier, Set<String>>(
  AdminUserSelectionNotifier.new,
);
```

Derived providers:
- `isSelectionActiveProvider` — `Provider<bool>` watching selection set `.isNotEmpty`
- `selectedCountProvider` — `Provider<int>` watching selection set `.length`

---

## 2. Bulk Actions

### Action Methods in AdminActionsNotifier

Add bulk methods to existing `admin_actions_provider.dart`:

```dart
Future<void> bulkToggleActive(Set<String> userIds, {required bool activate}) async { ... }
Future<void> bulkGrantPremium(Set<String> userIds) async { ... }
Future<void> bulkRevokePremium(Set<String> userIds) async { ... }
Future<String> bulkExport(Set<String> userIds, {ExportFormat format = ExportFormat.json}) async { ... }
Future<void> bulkDelete(Set<String> userIds) async { ... }
```

Each method:
1. Checks `requireAdmin()`
2. Filters out protected roles (founder, admin) — collects skipped user IDs
3. Performs action on remaining users sequentially (not parallel — avoid rate limiting)
4. Logs admin action for each user via `logAdminAction()`
5. Returns result with count of succeeded/skipped/failed
6. Invalidates `adminUsersProvider` after completion

### Protected Role Handling

Before any destructive bulk action:
1. Fetch role for each selected user
2. Skip users with `founder` or `admin` role
3. If any were skipped, show SnackBar: "X protected user(s) skipped"
4. Proceed with remaining users

### Bulk Delete

- **Founder-only**: check `isFounderProvider` before allowing
- **Double confirmation dialog**: first "Are you sure?", then type user count to confirm
- Uses `resetAllUserData` RPC per user (existing Task 6 implementation)
- Does NOT delete profiles — only user data (birds, breeding, etc.)

### Bulk Export

- Fetches full profile + bird count + subscription data for each selected user
- Outputs as JSON array or CSV
- Uses `share_plus` for file sharing (same pattern as existing export)

---

## 3. UI Changes

### Admin Users Screen (`admin_users_screen.dart`)

**Selection Mode Toggle:**
- Long-press on any user card enters selection mode
- AppBar changes: title shows selected count, actions show "Select All" / "Clear"
- Tap on card toggles selection (when in selection mode)
- Back button or "Clear" exits selection mode

**Bulk Action Bar:**
- `BottomAppBar` appears when selection is active
- Shows selected count label
- Row of action buttons: Activate, Deactivate, Premium+, Premium-, Export, Delete
- Delete button only visible if user is founder
- Each button has icon + short label

**Layout:**
```
┌─────────────────────────────┐
│ AppBar: "3 selected"  [All] [✕] │
├─────────────────────────────┤
│ [✓] User Card 1                 │
│ [ ] User Card 2                 │
│ [✓] User Card 3                 │
│ [✓] User Card 4                 │
│ [ ] User Card 5                 │
├─────────────────────────────┤
│ BottomAppBar:                    │
│ [Activate] [Deactivate] [P+]    │
│ [P-] [Export] [Delete]           │
└─────────────────────────────┘
```

### User Card (`admin_users_screen_card.dart`)

- Add leading `Checkbox` when selection mode is active
- Card tap behavior: normal mode → navigate to detail, selection mode → toggle selection
- Selected cards get subtle highlight (primary color with low alpha)

---

## 4. Confirmation Dialogs

| Action | Dialog Type | Content |
|--------|------------|---------|
| Bulk Activate | Single confirm | "Activate X users?" |
| Bulk Deactivate | Single confirm | "Deactivate X users?" |
| Bulk Grant Premium | Single confirm | "Grant premium to X users?" |
| Bulk Revoke Premium | Single confirm | "Revoke premium from X users?" |
| Bulk Export | No dialog | Direct download |
| Bulk Delete | Double confirm | 1st: "Delete all data for X users?", 2nd: Type count to confirm |

---

## 5. Localization Keys (~12 keys)

```json
{
  "admin": {
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
    "bulk_delete_confirm": "Type {} to confirm deletion",
    "protected_users_skipped": "{} protected user(s) skipped"
  }
}
```

---

## 6. Test Strategy

### Unit Tests
- `AdminUserSelectionNotifier`: toggle, selectAll, clear
- Bulk action methods: protected role filtering, success/skip counting

### Widget Tests
- Selection mode activation (long press)
- Checkbox visibility in selection mode
- AppBar title change with selected count
- BottomAppBar visibility when selection active
- Delete button visibility for founder vs non-founder

---

## 7. Files Summary

### New Files
| File | Responsibility |
|------|---------------|
| `lib/features/admin/providers/admin_user_selection_provider.dart` | Selection state management |

### Modified Files
| File | Changes |
|------|---------|
| `lib/features/admin/providers/admin_actions_provider.dart` | Bulk action methods |
| `lib/features/admin/screens/admin_users_screen.dart` | Selection mode UI, action bar |
| `lib/features/admin/screens/admin_users_screen_card.dart` | Checkbox, selection highlight |
| `assets/translations/tr.json` | 12 new keys |
| `assets/translations/en.json` | 12 new keys |
| `assets/translations/de.json` | 12 new keys |
| `test/features/admin/providers/admin_user_selection_test.dart` | New test file |
| `test/features/admin/screens/admin_users_screen_test.dart` | Updated tests |

---

## Design Decisions & Trade-offs

1. **Sequential vs parallel execution:** Sequential chosen to avoid Supabase rate limiting. Trade-off: slower for large batches, but safer.

2. **Delete scope:** Deletes user DATA only (via existing `reset_user_data` RPC), not profile/auth. Users can still log in but will have empty data. Full account deletion is a separate feature.

3. **Founder-only delete:** Destructive operations restricted to founder role. Moderators can activate/deactivate and manage premium but cannot delete data.

4. **Selection state in Riverpod (not local):** Selection persists across rebuilds and can be accessed by the action bar which is a separate widget. Local `setState` would be lost on provider-triggered rebuilds.

5. **No bulk user creation:** Out of scope — users self-register. Bulk actions are management operations only.
