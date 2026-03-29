# Admin Panel Comprehensive Improvements — Design Spec

**Date:** 2026-03-29
**Approach:** Layer-based (data layer first → providers → UI → new features → tests)
**Scope:** Code quality fixes, performance improvements, new features, test updates

---

## 1. Admin Constants & Enum Enhancements

### 1.1 New File: `lib/features/admin/constants/admin_constants.dart`

Centralize all magic numbers scattered across admin panel files:

```dart
abstract final class AdminConstants {
  // Pagination
  static const usersPageSize = 50;
  static const auditLogsPageSize = 100;
  static const securityEventsPageSize = 100;
  static const feedbackPageSize = 50;

  // Export
  static const exportChunkSize = 500;
  static const maxExportRows = 50000;

  // Retention
  static const auditLogRetentionDays = 90;

  // Capacity thresholds
  static const capacityWarningPercent = 0.9;
  static const dbSizeLimitBytes = 500 * 1024 * 1024; // 500 MB

  // Debounce
  static const searchDebounceDuration = Duration(milliseconds: 350);

  // Auto-refresh
  static const monitoringRefreshInterval = Duration(seconds: 30);

  // Limits
  static const recentActionsLimit = 5;
  static const userActivityLogsLimit = 20;
  static const maxAlertsLimit = 10;

  // Responsive breakpoints
  static const wideLayoutBreakpoint = 840.0;
  static const gridColumnBreakpoint = 600.0;
}
```

### 1.2 Enum Extensions in `lib/core/enums/admin_enums.dart`

Add two new enums to replace string matching patterns:

**AdminActionType:**
- Values: create, update, delete, login, logout, grantPremium, revokePremium, toggleActive, export, reset, clearLogs, dismissEvent, unknown
- Methods: `toJson()`, `fromJson()`, `color(BuildContext)`, `IconData get icon`

**SecurityEventType:**
- Values: failedLogin, suspiciousActivity, rateLimited, bruteForce, unauthorizedAccess, mfaFailure, unknown
- Method: `SecuritySeverityLevel get inferredSeverity` — replaces string pattern matching in widgets

Impact: ~15 string comparison sites across audit/security widgets will become type-safe enum switches.

---

## 2. Data Layer — Provider & Data Fetching Improvements

### 2.1 Server-Side Filtering

Replace client-side filtering with Supabase query parameters:

**Audit Logs:** `adminAuditLogsProvider` applies `filter.searchQuery`, `filter.startDate`, `filter.endDate` directly in Supabase query via `.or()`, `.gte()`, `.lte()`.

**Security Events:** `adminSecurityEventsProvider` applies `filter.searchQuery`, `filter.severityFilter` directly in query.

**Users:** `adminUsersProvider` becomes `FutureProvider.family<List<AdminUser>, AdminUsersQuery>` with server-side search, status filter, sort field, and sort direction.

**Removed providers:** `filteredAuditLogsProvider`, `filteredSecurityEventsProvider` — no longer needed.

### 2.2 New Query Model

```dart
@freezed
abstract class AdminUsersQuery with _$AdminUsersQuery {
  const factory AdminUsersQuery({
    @Default('') String searchTerm,
    @Default(null) UserStatusFilter? statusFilter,
    @Default('created_at') String sortField,
    @Default(false) bool sortAscending,
    @Default(50) int limit,
  }) = _AdminUsersQuery;
}
```

### 2.3 Pagination Consistency

All lists use `AdminConstants` values:
- Users: 50 per page, increment 50
- Audit Logs: 100 per page, increment 100
- Security Events: 100 per page, increment 100
- Feedback: 50 per page, increment 50

### 2.4 Audit Trail Safety

`logAdminAction` in `admin_auth_utils.dart`: stop silently swallowing errors. Log to `AppLogger.error` AND `Sentry.captureException` on failure. Do NOT rethrow — keep it non-blocking for the main operation.

### 2.5 SecurityEvent Model Update

Change `eventType` field from `String` to `SecurityEventType` enum with `@JsonKey(unknownEnumValue: SecurityEventType.unknown)`. Add optional `severity` field of type `SecuritySeverityLevel`. Widget code uses `event.severity` or `event.eventType.inferredSeverity` instead of string pattern matching.

### 2.6 Silent Failure Fixes

Remove `catch → return []` patterns from `adminSystemAlertsProvider`, `adminPendingReviewCountProvider`, `adminFeedbackProvider`. Let `FutureProvider` propagate errors to `AsyncValue.error` so UI shows `ErrorState` widget with retry.

---

## 3. Data Layer — Data Integrity & Export

### 3.1 Transaction Support for resetAllUserData

New Supabase migration: `reset_user_data(target_user_id uuid)` RPC function.
- `LANGUAGE plpgsql`, `SECURITY DEFINER`, `SET search_path = public`
- Deletes in FK-safe order within a single transaction
- Preserves profile and auth records

Dart side: `AdminDatabaseManager.resetAllUserData()` calls `client.rpc('reset_user_data')` instead of sequential deletes. Fallback: if RPC unavailable, keep sequential deletes with warning log.

### 3.2 Chunk-Based Export

Replace `.limit(10000)` with chunked fetching:
- Chunk size: `AdminConstants.exportChunkSize` (500)
- Max rows: `AdminConstants.maxExportRows` (50,000)
- Uses `.range(offset, offset + chunkSize - 1)` pagination
- Logs warning when truncated

### 3.3 Premium Revoke — Soft Delete

Change from `DELETE` to `UPDATE` with `status: 'revoked'`, `revoked_at`, `revoked_by` fields. Preserves audit trail.

### 3.4 Missing Provider Invalidation

After `dismissSecurityEvent`: invalidate `adminSecurityEventsProvider` and `adminSystemAlertsProvider`.
Review all other actions for missing invalidations.

### 3.5 Dashboard Parallel Query

Ensure `adminPendingReviewCountProvider` uses `Future.wait` for posts + comments count queries (not sequential).

---

## 4. UI/Widget Improvements

### 4.1 Accessibility — Semantic Labels
Add `semanticsLabel` to 20+ icons across all admin widget files:
- Dashboard stat icons, monitoring capacity icons, sidebar navigation icons
- Security severity icons, audit action type icons, user detail icons

### 4.2 Action Type Coloring — String to Enum
Replace `_actionColor(String)` and `_severityColor(String)` functions with enum-based `actionType.color(context)` and `severity.color(context)`.

### 4.3 Tooltips
Add `tooltip` to ~10-15 icon-only buttons across audit filter, security content, database action buttons.

### 4.4 Responsive Breakpoint Constants
Replace hardcoded `600`, `840`, `1.4`, `1.15` values with `AdminConstants` references.

### 4.5 Monitoring Capacity Limit
Replace `500 * 1024 * 1024` with `AdminConstants.dbSizeLimitBytes`.

### 4.6 Sidebar Static Menu
Move menu item list from `build()` to `static const _menuItems` to avoid rebuild allocations.

### 4.7 AdminSystemSettings Typed Model
Replace `Map<String, Map<String, dynamic>>` with Freezed model:
```dart
@freezed
abstract class AdminSystemSettings with _$AdminSystemSettings {
  const factory AdminSystemSettings({
    @Default(false) bool maintenanceMode,
    @Default(true) bool registrationEnabled,
    @Default(true) bool communityEnabled,
    @Default(true) bool autoBackupEnabled,
    @Default(true) bool autoCleanupEnabled,
    DateTime? lastUpdated,
  }) = _AdminSystemSettings;

  factory AdminSystemSettings.fromSettingsMap(Map<String, Map<String, dynamic>> map) => ...;
}
```

### 4.8 Debounce Timer Disposal
Add `_debounce?.cancel()` in `dispose()` of `AdminUsersScreen`.

---

## 5. New Features

### 5.1 Feedback Search
Add `TextField` with debounce to feedback screen. New `FeedbackQuery` Freezed model with `searchQuery` and `statusFilter`. Server-side search via `.or('message.ilike.%q%,subject.ilike.%q%')`.

### 5.2 Monitoring Refresh Countdown
Small widget showing seconds until next auto-refresh in monitoring screen. Uses existing `Timer.periodic` infrastructure.

### 5.3 CSV Export
Add `ExportFormat` enum (json, csv). `exportTable` accepts format parameter. Simple CSV generation with header row + comma-separated values. UI: dropdown or segmented button on export action.

### 5.4 Bulk User Actions
`AdminUserSelectionNotifier` manages `Set<String>` of selected user IDs. UI: checkbox on each user card, action bar appears when selection is non-empty. Actions: bulk activate/deactivate, bulk grant/revoke premium. Protected role checks preserved per user.

### 5.5 New L10n Keys
~12 new keys across admin section in tr.json, en.json, de.json:
- export_format, export_csv, export_json
- bulk_actions, selected_count, bulk_activate, bulk_deactivate
- next_refresh, search_feedback
- reset_transaction_failed, export_truncated

---

## 6. Test Strategy

### Unit Tests (new + updated)
- `admin_constants_test.dart` — new
- `admin_enums_test.dart` — updated (new enum values, color/icon/severity methods)
- `admin_filter_providers_test.dart` — updated (server-side filter params)
- `admin_data_providers_test.dart` — updated (AdminUsersQuery model)
- `admin_actions_provider_test.dart` — updated (provider invalidation after actions)
- `admin_database_manager_test.dart` — updated (chunk export, RPC transaction)
- `admin_user_manager_test.dart` — updated (premium soft-delete)
- `admin_feedback_providers_test.dart` — updated (FeedbackQuery, search)
- `admin_models_test.dart` — updated (AdminSystemSettings, SecurityEvent enum fields)

### Widget Tests (updated)
- `admin_audit_content_test.dart` — enum action colors, semantic labels
- `admin_security_content_test.dart` — enum severity, dismiss invalidation
- `admin_security_filter_widgets_test.dart` — severity filter → server query
- `admin_monitoring_content_test.dart` — capacity from AdminConstants
- `admin_settings_widgets_test.dart` — typed AdminSystemSettings
- `admin_sidebar_test.dart` — static menu, semantic labels
- `admin_database_content_test.dart` — CSV export option
- `admin_users_screen_test.dart` — bulk selection, debounce disposal
- `admin_feedback_screen_test.dart` — search TextField

### Not in scope
- Golden tests (platform font differences)
- New E2E tests (existing admin_flow_test.dart sufficient)
- Supabase RPC integration tests

---

## 7. Implementation Phases

| Phase | Content | Est. Files |
|-------|---------|-----------|
| 1 | Admin constants + enum extensions + new Freezed models (AdminUsersQuery, FeedbackQuery, AdminSystemSettings) | ~6 |
| 2 | Provider refactor — server-side filtering, pagination consistency, silent error fixes, audit trail safety | ~8 |
| 3 | Database manager — chunk export, transaction RPC, premium soft-delete, missing invalidations | ~5 + 1 migration |
| 4 | Widget improvements — semantic labels, tooltips, enum-based colors, responsive constants, sidebar, settings model, feedback search UI, debounce disposal, CSV export UI, bulk actions UI, refresh countdown | ~18 |
| 5 | L10n (3 files) + test updates (~18 test files) + code generation | ~21 |

**Total:** ~58 files touched (edits + few new files)

**New files:**
- `lib/features/admin/constants/admin_constants.dart`
- `supabase/migrations/YYYYMMDD_add_reset_user_data_rpc.sql`

**Removed providers:**
- `filteredAuditLogsProvider`
- `filteredSecurityEventsProvider`

---

## Design Decisions & Trade-offs

1. **Server-side filtering vs client-side:** Server-side chosen for scalability. Trade-off: slightly more complex provider code, but eliminates memory issues with large datasets.

2. **RPC for transaction vs sequential deletes:** RPC provides atomicity. Fallback to sequential deletes kept for environments without the migration applied.

3. **Chunk export (500) vs streaming:** Chunking is simpler than true streaming and sufficient for admin export use cases. 500-row chunks balance memory usage and request count.

4. **Bulk actions scope:** Limited to activate/deactivate and premium grant/revoke. More dangerous bulk operations (delete, reset) intentionally excluded — require per-user confirmation.

5. **AdminSystemSettings Freezed model:** Adds a code generation dependency but eliminates runtime type casting errors. Worth the trade-off for type safety.

6. **SecurityEventType enum in Dart (not DB):** Severity inference stays in Dart via `inferredSeverity` getter rather than adding a DB column. Avoids migration complexity; if DB severity field exists, it takes precedence via the `severity` field on the model.
