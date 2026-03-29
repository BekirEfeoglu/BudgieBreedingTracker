# Admin Panel Comprehensive Improvements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve admin panel code quality, performance, accessibility, and add missing features across all layers.

**Architecture:** Layer-based approach — constants/enums first, then providers, then database manager, then UI widgets, then localization and tests. Each phase builds on the previous.

**Tech Stack:** Flutter/Dart, Riverpod 3, Freezed 3, Supabase, Drift, easy_localization

**Spec:** `docs/superpowers/specs/2026-03-29-admin-panel-improvements-design.md`

---

## File Map

### New Files
| File | Responsibility |
|------|---------------|
| `lib/features/admin/constants/admin_constants.dart` | All admin magic numbers centralized |
| `supabase/migrations/20260329180000_add_reset_user_data_rpc.sql` | Transaction-safe user data reset RPC |

### Modified Files — Phase 1 (Constants & Enums)
| File | Changes |
|------|---------|
| `lib/core/enums/admin_enums.dart` | Add `AdminActionType`, `SecurityEventType` enums |
| `lib/features/admin/providers/admin_models.dart` | Update `SecurityEvent` model enum fields, add `AdminSystemSettings`, `AdminUsersQuery`, `FeedbackQuery` |
| `lib/features/admin/providers/admin_providers.dart` | Export new constants file |

### Modified Files — Phase 2 (Providers)
| File | Changes |
|------|---------|
| `lib/features/admin/providers/admin_filter_providers.dart` | Server-side filtering, remove client-side filtered providers |
| `lib/features/admin/providers/admin_data_providers.dart` | Use AdminConstants, AdminUsersQuery family provider |
| `lib/features/admin/providers/admin_dashboard_providers.dart` | Remove silent failures, use AdminConstants |
| `lib/features/admin/providers/admin_auth_utils.dart` | Sentry logging for audit trail failures |
| `lib/features/admin/providers/admin_capacity_providers.dart` | Use AdminConstants for thresholds |
| `lib/features/admin/providers/admin_feedback_providers.dart` | Server-side search, FeedbackQuery, remove silent failure |

### Modified Files — Phase 3 (Database Manager)
| File | Changes |
|------|---------|
| `lib/features/admin/providers/admin_database_manager.dart` | Chunk export, RPC transaction |
| `lib/features/admin/providers/admin_user_manager.dart` | Premium soft-delete |
| `lib/features/admin/providers/admin_actions_provider.dart` | Missing invalidations, CSV export |

### Modified Files — Phase 4 (UI Widgets)
| File | Changes |
|------|---------|
| `lib/features/admin/widgets/admin_audit_content.dart` | Enum-based icons/colors, semantic labels |
| `lib/features/admin/widgets/admin_security_content.dart` | Enum-based severity, semantic labels |
| `lib/features/admin/widgets/admin_security_filter_widgets.dart` | Semantic labels, tooltips |
| `lib/features/admin/widgets/admin_audit_filter_widgets.dart` | Semantic labels, tooltips |
| `lib/features/admin/widgets/admin_monitoring_content.dart` | AdminConstants, semantic labels |
| `lib/features/admin/widgets/admin_monitoring_content_cards.dart` | Semantic labels |
| `lib/features/admin/widgets/admin_sidebar.dart` | Static menu list, semantic labels |
| `lib/features/admin/widgets/admin_settings_content.dart` | AdminSystemSettings typed model |
| `lib/features/admin/widgets/admin_settings_actions.dart` | Use AdminConstants |
| `lib/features/admin/widgets/admin_dashboard_content.dart` | AdminConstants breakpoints, semantic labels |
| `lib/features/admin/widgets/admin_dashboard_content_cards.dart` | Semantic labels |
| `lib/features/admin/widgets/admin_database_content.dart` | CSV export option |
| `lib/features/admin/widgets/admin_database_table_widgets.dart` | CSV export option |
| `lib/features/admin/widgets/admin_user_detail_content.dart` | Semantic labels |
| `lib/features/admin/screens/admin_users_screen.dart` | Debounce disposal, AdminConstants, bulk selection |
| `lib/features/admin/screens/admin_feedback_screen.dart` | Search TextField |
| `lib/features/admin/screens/admin_monitoring_screen.dart` | AdminConstants refresh interval |
| `lib/features/admin/screens/admin_audit_screen.dart` | AdminConstants pagination |

### Modified Files — Phase 5 (L10n & Tests)
| File | Changes |
|------|---------|
| `assets/translations/tr.json` | New admin keys |
| `assets/translations/en.json` | New admin keys |
| `assets/translations/de.json` | New admin keys |
| `test/core/enums/admin_enums_test.dart` | New enum tests |
| `test/features/admin/providers/admin_models_test.dart` | New model tests |
| `test/features/admin/providers/admin_filter_providers_test.dart` | Updated filter tests |
| `test/features/admin/providers/admin_data_providers_test.dart` | Updated provider tests |
| `test/features/admin/providers/admin_actions_provider_test.dart` | Invalidation tests |
| `test/features/admin/providers/admin_database_manager_test.dart` | Chunk export tests |
| `test/features/admin/providers/admin_user_manager_test.dart` | Soft-delete tests |
| `test/features/admin/providers/admin_feedback_providers_test.dart` | Search tests |
| `test/features/admin/widgets/admin_audit_content_test.dart` | Enum-based tests |
| `test/features/admin/widgets/admin_security_content_test.dart` | Enum-based tests |

---

## Task 1: Create AdminConstants

**Files:**
- Create: `lib/features/admin/constants/admin_constants.dart`
- Modify: `lib/features/admin/providers/admin_providers.dart`

- [ ] **Step 1: Create the constants file**

```dart
// lib/features/admin/constants/admin_constants.dart

/// Centralized constants for the admin panel.
/// Replaces magic numbers scattered across admin files.
abstract final class AdminConstants {
  // Pagination
  static const int usersPageSize = 50;
  static const int auditLogsPageSize = 100;
  static const int securityEventsPageSize = 100;
  static const int feedbackPageSize = 50;

  // Export
  static const int exportChunkSize = 500;
  static const int maxExportRows = 50000;

  // Retention
  static const int auditLogRetentionDays = 90;

  // Capacity thresholds
  static const double capacityWarningPercent = 0.9;
  static const int dbSizeLimitBytes = 500 * 1024 * 1024; // 500 MB
  static const double healthyThreshold = 0.7;
  static const double warningThreshold = 0.9;

  // Debounce
  static const Duration searchDebounceDuration = Duration(milliseconds: 350);

  // Auto-refresh
  static const Duration monitoringRefreshInterval = Duration(seconds: 30);

  // Limits
  static const int recentActionsLimit = 5;
  static const int userActivityLogsLimit = 20;
  static const int maxAlertsLimit = 10;

  // Responsive breakpoints
  static const double wideLayoutBreakpoint = 840.0;
  static const double gridColumnBreakpoint = 600.0;

  // UI
  static const double gridAspectRatioWide = 1.4;
  static const double gridAspectRatioNarrow = 1.15;
}
```

- [ ] **Step 2: Add export to barrel file**

In `lib/features/admin/providers/admin_providers.dart`, add the export:

```dart
// Barrel export for all admin providers.
//
// Import this file to access all admin providers, models, and enums.
export '../../../core/enums/admin_enums.dart';
export '../constants/admin_constants.dart';
export 'admin_models.dart';
export 'admin_data_providers.dart';
export 'admin_filter_providers.dart';
export 'admin_dashboard_providers.dart';
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/admin/constants/admin_constants.dart lib/features/admin/providers/admin_providers.dart
git commit -m "feat(admin): add centralized AdminConstants for magic numbers"
```

---

## Task 2: Add AdminActionType and SecurityEventType Enums

**Files:**
- Modify: `lib/core/enums/admin_enums.dart`

- [ ] **Step 1: Add AdminActionType enum**

Append after the existing `FeedbackStatus` enum (after line 68) in `lib/core/enums/admin_enums.dart`:

```dart
/// Admin action types for audit log categorization.
/// Replaces string matching like `action.contains('delete')`.
enum AdminActionType {
  create,
  update,
  delete,
  login,
  logout,
  grantPremium,
  revokePremium,
  toggleActive,
  export,
  reset,
  clearLogs,
  dismissEvent,
  unknown;

  String toJson() => name;
  static AdminActionType fromJson(String json) {
    // Handle snake_case action strings from database
    final normalized = json.toLowerCase().replaceAll('_', '');
    for (final value in values) {
      if (value.name.toLowerCase() == normalized) return value;
    }
    // Fallback: check if the action string contains a known keyword
    if (json.contains('delete') || json.contains('remove')) return delete;
    if (json.contains('create') || json.contains('add')) return create;
    if (json.contains('update') || json.contains('edit')) return update;
    if (json.contains('login')) return login;
    if (json.contains('logout')) return logout;
    if (json.contains('grant') && json.contains('premium')) return grantPremium;
    if (json.contains('revoke') && json.contains('premium')) return revokePremium;
    if (json.contains('toggle') && json.contains('active')) return toggleActive;
    if (json.contains('export')) return export;
    if (json.contains('reset')) return reset;
    if (json.contains('clear') && json.contains('log')) return clearLogs;
    if (json.contains('dismiss')) return dismissEvent;
    return unknown;
  }
}

/// Security event types for type-safe severity inference.
/// Replaces string pattern matching like `eventType.contains('suspicious')`.
enum SecurityEventType {
  failedLogin,
  suspiciousActivity,
  rateLimited,
  bruteForce,
  unauthorizedAccess,
  mfaFailure,
  unknown;

  String toJson() => name;
  static SecurityEventType fromJson(String json) {
    final lower = json.toLowerCase().replaceAll('_', '');
    for (final value in values) {
      if (value.name.toLowerCase() == lower) return value;
    }
    // Fallback keyword matching for legacy data
    if (json.contains('failed') && json.contains('login')) return failedLogin;
    if (json.contains('suspicious')) return suspiciousActivity;
    if (json.contains('rate_limit') || json.contains('ratelimit')) return rateLimited;
    if (json.contains('brute')) return bruteForce;
    if (json.contains('unauthorized')) return unauthorizedAccess;
    if (json.contains('mfa')) return mfaFailure;
    return unknown;
  }

  /// Infer severity from event type — replaces fragile string matching in widgets.
  SecuritySeverityLevel get inferredSeverity => switch (this) {
    bruteForce || unauthorizedAccess => SecuritySeverityLevel.high,
    suspiciousActivity || mfaFailure => SecuritySeverityLevel.medium,
    failedLogin || rateLimited => SecuritySeverityLevel.low,
    unknown => SecuritySeverityLevel.unknown,
  };
}
```

- [ ] **Step 2: Verify compilation**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

- [ ] **Step 3: Commit**

```bash
git add lib/core/enums/admin_enums.dart
git commit -m "feat(admin): add AdminActionType and SecurityEventType enums"
```

---

## Task 3: Update Admin Models — SecurityEvent, AdminUsersQuery, FeedbackQuery, AdminSystemSettings

**Files:**
- Modify: `lib/features/admin/providers/admin_models.dart`

- [ ] **Step 1: Update SecurityEvent model**

In `lib/features/admin/providers/admin_models.dart`, replace the `SecurityEvent` class (lines 98-112) with:

```dart
/// Security event entry.
@freezed
abstract class SecurityEvent with _$SecurityEvent {
  const SecurityEvent._();
  const factory SecurityEvent({
    required String id,
    @JsonKey(
      fromJson: SecurityEventType.fromJson,
      toJson: _securityEventTypeToJson,
    )
    @Default(SecurityEventType.unknown)
    SecurityEventType eventType,
    String? userId,
    String? ipAddress,
    @JsonKey(fromJson: _jsonbToString) String? details,
    required DateTime createdAt,
  }) = _SecurityEvent;

  factory SecurityEvent.fromJson(Map<String, dynamic> json) =>
      _$SecurityEventFromJson(json);

  /// Severity derived from event type or overridden by explicit field.
  SecuritySeverityLevel get severity => eventType.inferredSeverity;
}

String _securityEventTypeToJson(SecurityEventType type) => type.toJson();
```

- [ ] **Step 2: Add AdminUsersQuery model**

Append after the `TableCapacity` class (after line 186):

```dart
/// Query parameters for admin users list (server-side filtering).
@freezed
abstract class AdminUsersQuery with _$AdminUsersQuery {
  const AdminUsersQuery._();
  const factory AdminUsersQuery({
    @Default('') String searchTerm,
    @Default(null) bool? isActiveFilter,
    @Default('created_at') String sortField,
    @Default(false) bool sortAscending,
    @Default(50) int limit,
  }) = _AdminUsersQuery;

  factory AdminUsersQuery.fromJson(Map<String, dynamic> json) =>
      _$AdminUsersQueryFromJson(json);
}

/// Query parameters for admin feedback list (server-side filtering).
@freezed
abstract class FeedbackQuery with _$FeedbackQuery {
  const FeedbackQuery._();
  const factory FeedbackQuery({
    @Default(null) FeedbackStatus? statusFilter,
    @Default('') String searchQuery,
    @Default(50) int limit,
  }) = _FeedbackQuery;

  factory FeedbackQuery.fromJson(Map<String, dynamic> json) =>
      _$FeedbackQueryFromJson(json);
}

/// Typed model for admin system settings.
/// Replaces `Map<String, Map<String, dynamic>>` loose typing.
@freezed
abstract class AdminSystemSettings with _$AdminSystemSettings {
  const AdminSystemSettings._();
  const factory AdminSystemSettings({
    @Default(false) bool maintenanceMode,
    @Default(true) bool registrationOpen,
    @Default(true) bool emailVerificationRequired,
    @Default(true) bool premiumEnabled,
    @Default(true) bool rateLimitingEnabled,
    @Default(false) bool twoFactorRequired,
    @Default(false) bool autoBackupEnabled,
    @Default(false) bool autoCleanupEnabled,
    @Default(true) bool globalPushEnabled,
    @Default(true) bool emailAlertsEnabled,
    DateTime? lastUpdated,
  }) = _AdminSystemSettings;

  factory AdminSystemSettings.fromJson(Map<String, dynamic> json) =>
      _$AdminSystemSettingsFromJson(json);

  /// Build from the raw settings map returned by adminSystemSettingsProvider.
  factory AdminSystemSettings.fromSettingsMap(
    Map<String, Map<String, dynamic>> map,
  ) {
    bool _val(String key, bool fallback) {
      final entry = map[key];
      if (entry == null) return fallback;
      final v = entry['value'];
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return fallback;
    }

    DateTime? latestUpdate;
    for (final entry in map.values) {
      final raw = entry['updated_at'] as String?;
      if (raw != null) {
        final dt = DateTime.tryParse(raw);
        if (dt != null && (latestUpdate == null || dt.isAfter(latestUpdate))) {
          latestUpdate = dt;
        }
      }
    }

    return AdminSystemSettings(
      maintenanceMode: _val('maintenance_mode', false),
      registrationOpen: _val('registration_open', true),
      emailVerificationRequired: _val('email_verification_required', true),
      premiumEnabled: _val('premium_enabled', true),
      rateLimitingEnabled: _val('rate_limiting_enabled', true),
      twoFactorRequired: _val('two_factor_required', false),
      autoBackupEnabled: _val('auto_backup_enabled', false),
      autoCleanupEnabled: _val('auto_cleanup_enabled', false),
      globalPushEnabled: _val('global_push_enabled', true),
      emailAlertsEnabled: _val('email_alerts_enabled', true),
      lastUpdated: latestUpdate,
    );
  }
}
```

- [ ] **Step 3: Add import for SecurityEventType**

Verify that the import `import '../../../core/enums/admin_enums.dart';` already exists at line 3. It does.

- [ ] **Step 4: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates updated `.freezed.dart` and `.g.dart` files without errors

- [ ] **Step 5: Verify compilation**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

- [ ] **Step 6: Commit**

```bash
git add lib/features/admin/providers/admin_models.dart lib/features/admin/providers/admin_models.freezed.dart lib/features/admin/providers/admin_models.g.dart
git commit -m "feat(admin): add AdminUsersQuery, FeedbackQuery, AdminSystemSettings models and update SecurityEvent"
```

---

## Task 4: Refactor Filter Providers — Server-Side Filtering

**Files:**
- Modify: `lib/features/admin/providers/admin_filter_providers.dart`

- [ ] **Step 1: Replace filteredAuditLogsProvider with server-side filtering**

Replace the entire `filteredAuditLogsProvider` (lines 130-173) and `adminAuditLogsProvider` (lines 94-107) with a single server-side provider. Also replace `filteredSecurityEventsProvider` (lines 176-226) and `adminSecurityEventsProvider` (lines 110-125).

The full updated file content for `lib/features/admin/providers/admin_filter_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/admin_enums.dart';
import '../constants/admin_constants.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// Notifier for audit logs list limit (increases on "load more").
class AdminAuditLimitNotifier extends Notifier<int> {
  @override
  int build() => AdminConstants.auditLogsPageSize;
}

/// Current limit for audit logs list (increases on "load more").
final adminAuditLimitProvider = NotifierProvider<AdminAuditLimitNotifier, int>(
  AdminAuditLimitNotifier.new,
);

/// Notifier for security events list limit.
class AdminSecurityLimitNotifier extends Notifier<int> {
  @override
  int build() => AdminConstants.securityEventsPageSize;
}

/// Current limit for security events list.
final adminSecurityLimitProvider =
    NotifierProvider<AdminSecurityLimitNotifier, int>(
  AdminSecurityLimitNotifier.new,
);

// ─── Filter State Classes ───────────────────────────────────────

/// Audit log filter state.
class AuditLogFilter {
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  const AuditLogFilter({this.searchQuery = '', this.startDate, this.endDate});

  AuditLogFilter copyWith({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) => AuditLogFilter(
    searchQuery: searchQuery ?? this.searchQuery,
    startDate: clearStartDate ? null : (startDate ?? this.startDate),
    endDate: clearEndDate ? null : (endDate ?? this.endDate),
  );

  bool get hasFilter =>
      searchQuery.isNotEmpty || startDate != null || endDate != null;
}

/// Security event filter state.
class SecurityEventFilter {
  final String searchQuery;
  final SecuritySeverityLevel? severity;

  const SecurityEventFilter({this.searchQuery = '', this.severity});

  SecurityEventFilter copyWith({
    String? searchQuery,
    SecuritySeverityLevel? severity,
    bool clearSeverity = false,
  }) => SecurityEventFilter(
    searchQuery: searchQuery ?? this.searchQuery,
    severity: clearSeverity ? null : (severity ?? this.severity),
  );

  bool get hasFilter => searchQuery.isNotEmpty || severity != null;
}

// ─── Filter Notifiers ───────────────────────────────────────────

/// Notifier for audit log filter.
class AuditLogFilterNotifier extends Notifier<AuditLogFilter> {
  @override
  AuditLogFilter build() => const AuditLogFilter();
}

/// Audit log filter provider.
final auditLogFilterProvider =
    NotifierProvider<AuditLogFilterNotifier, AuditLogFilter>(
  AuditLogFilterNotifier.new,
);

/// Notifier for security event filter.
class SecurityEventFilterNotifier extends Notifier<SecurityEventFilter> {
  @override
  SecurityEventFilter build() => const SecurityEventFilter();
}

/// Security event filter provider.
final securityEventFilterProvider =
    NotifierProvider<SecurityEventFilterNotifier, SecurityEventFilter>(
  SecurityEventFilterNotifier.new,
);

// ─── Server-Side Filtered Providers ─────────────────────────────

/// Audit logs with server-side filtering applied.
/// Replaces the old pattern of fetch-all + client-side filter.
final adminAuditLogsProvider =
    FutureProvider.autoDispose<List<AdminLog>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final filter = ref.watch(auditLogFilterProvider);
  final limit = ref.watch(adminAuditLimitProvider);

  var query = client
      .from(SupabaseConstants.adminLogsTable)
      .select();

  // Server-side date filtering
  if (filter.startDate != null) {
    query = query.gte(
      'created_at',
      filter.startDate!.toUtc().toIso8601String(),
    );
  }
  if (filter.endDate != null) {
    final endOfDay = DateTime(
      filter.endDate!.year,
      filter.endDate!.month,
      filter.endDate!.day,
      23, 59, 59,
    );
    query = query.lte('created_at', endOfDay.toUtc().toIso8601String());
  }

  // Server-side text search
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery
        .replaceAll(RegExp(r'[\x00-\x1f]'), '')
        .replaceAll(RegExp(r'[,.()\[\]\\]'), '')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    if (q.isNotEmpty) {
      query = query.or('action.ilike.%$q%,details::text.ilike.%$q%');
    }
  }

  final result = await query
      .order('created_at', ascending: false)
      .limit(limit);

  return (result as List)
      .map((row) => AdminLog.fromJson(row as Map<String, dynamic>))
      .toList();
});

/// Security events with server-side filtering applied.
final adminSecurityEventsProvider =
    FutureProvider.autoDispose<List<SecurityEvent>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final filter = ref.watch(securityEventFilterProvider);
  final limit = ref.watch(adminSecurityLimitProvider);

  var query = client
      .from(SupabaseConstants.securityEventsTable)
      .select();

  // Server-side text search
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery
        .replaceAll(RegExp(r'[\x00-\x1f]'), '')
        .replaceAll(RegExp(r'[,.()\[\]\\]'), '')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    if (q.isNotEmpty) {
      query = query.or(
        'event_type.ilike.%$q%,details::text.ilike.%$q%,ip_address.ilike.%$q%',
      );
    }
  }

  // Server-side severity filtering via event_type patterns
  if (filter.severity != null) {
    query = switch (filter.severity!) {
      SecuritySeverityLevel.high => query.or(
        'event_type.ilike.%suspicious%,event_type.ilike.%attack%,event_type.ilike.%brute%,event_type.ilike.%unauthorized%',
      ),
      SecuritySeverityLevel.medium => query.or(
        'event_type.ilike.%failed%,event_type.ilike.%mfa%',
      ),
      SecuritySeverityLevel.low => query.or(
        'event_type.ilike.%rate_limit%,event_type.ilike.%login%',
      ),
      SecuritySeverityLevel.unknown => query,
    };
  }

  final result = await query
      .order('created_at', ascending: false)
      .limit(limit);

  return (result as List)
      .map((row) => SecurityEvent.fromJson(row as Map<String, dynamic>))
      .toList();
});
```

- [ ] **Step 2: Update all references from `filteredAuditLogsProvider` to `adminAuditLogsProvider`**

Search the codebase for `filteredAuditLogsProvider` and `filteredSecurityEventsProvider`. These are used in:
- `lib/features/admin/screens/admin_audit_screen.dart` — change `filteredAuditLogsProvider` to `adminAuditLogsProvider`
- `lib/features/admin/screens/admin_security_screen.dart` — change `filteredSecurityEventsProvider` to `adminSecurityEventsProvider`
- `lib/features/admin/providers/admin_actions_provider.dart` — change invalidation targets

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors (old provider names removed, new ones used everywhere)

- [ ] **Step 4: Commit**

```bash
git add lib/features/admin/providers/admin_filter_providers.dart lib/features/admin/screens/admin_audit_screen.dart lib/features/admin/screens/admin_security_screen.dart lib/features/admin/providers/admin_actions_provider.dart
git commit -m "refactor(admin): move audit/security filtering to server-side queries"
```

---

## Task 5: Refactor Data Providers — AdminUsersQuery, Constants, Silent Failures

**Files:**
- Modify: `lib/features/admin/providers/admin_data_providers.dart`
- Modify: `lib/features/admin/providers/admin_dashboard_providers.dart`
- Modify: `lib/features/admin/providers/admin_capacity_providers.dart`
- Modify: `lib/features/admin/providers/admin_feedback_providers.dart`
- Modify: `lib/features/admin/providers/admin_auth_utils.dart`

- [ ] **Step 1: Update admin_data_providers.dart**

Replace `kAdminPageSize` constant (line 13) and `adminUsersProvider` (lines 123-159):

Replace line 13 `const kAdminPageSize = 50;` with import:
```dart
import '../constants/admin_constants.dart';
```

Change `AdminUsersLimitNotifier.build()` (line 18) to:
```dart
int build() => AdminConstants.usersPageSize;
```

Replace `adminUsersProvider` (lines 123-159) with family provider using `AdminUsersQuery`:

```dart
/// Admin users list provider with server-side query parameters.
final adminUsersProvider =
    FutureProvider.family<List<AdminUser>, AdminUsersQuery>((
  ref,
  query,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  var request = client
      .from(SupabaseConstants.profilesTable)
      .select('id, email, full_name, avatar_url, created_at, is_active');

  if (query.searchTerm.isNotEmpty) {
    final sanitized = query.searchTerm
        .replaceAll(RegExp(r'[\x00-\x1f]'), '')
        .replaceAll(RegExp(r'[,.()\[\]\\]'), '')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    if (sanitized.isNotEmpty) {
      request = request.or(
        'email.ilike.%$sanitized%,full_name.ilike.%$sanitized%',
      );
    }
  }

  // Server-side active/inactive filter
  if (query.isActiveFilter != null) {
    request = request.eq('is_active', query.isActiveFilter!);
  }

  final result = await request
      .order(query.sortField, ascending: query.sortAscending)
      .limit(query.limit);

  return (result as List)
      .map((row) => AdminUser.fromJson(row as Map<String, dynamic>))
      .toList();
});
```

Also update `adminUserDetailProvider` line 191 `.limit(20)` to `.limit(AdminConstants.userActivityLogsLimit)`.

- [ ] **Step 2: Update admin_dashboard_providers.dart — remove silent failures**

In `lib/features/admin/providers/admin_dashboard_providers.dart`:

Remove the `try-catch` blocks that return empty defaults. Let FutureProvider propagate errors:

For `adminSystemAlertsProvider` (lines 10-32): remove `catch (e) { return []; }` — let it throw.

For `adminPendingReviewCountProvider` (lines 35-57): remove `catch (_) { return 0; }` — let it throw.

For `recentAdminActionsProvider` (lines 60-78): remove `catch (e) { return []; }` — let it throw.

Replace hardcoded limits:
- Line 23 `.limit(10)` → `.limit(AdminConstants.maxAlertsLimit)`
- Line 69 `.limit(5)` → `.limit(AdminConstants.recentActionsLimit)`

Add import: `import '../constants/admin_constants.dart';`

- [ ] **Step 3: Update admin_capacity_providers.dart — use constants**

In `lib/features/admin/providers/admin_capacity_providers.dart`:

Replace line 81 `const _capacityCriticalThreshold = 0.9;` with:
```dart
import '../constants/admin_constants.dart';
```
And replace usage `_capacityCriticalThreshold` → `AdminConstants.capacityWarningPercent`.

- [ ] **Step 4: Update admin_feedback_providers.dart — server-side search, remove silent failure**

Replace `adminFeedbackProvider` with a provider that accepts `FeedbackQuery`:

```dart
import '../constants/admin_constants.dart';
import 'admin_models.dart';

/// Notifier for feedback query state.
class FeedbackQueryNotifier extends Notifier<FeedbackQuery> {
  @override
  FeedbackQuery build() => FeedbackQuery(limit: AdminConstants.feedbackPageSize);
}

final feedbackQueryProvider =
    NotifierProvider<FeedbackQueryNotifier, FeedbackQuery>(
  FeedbackQueryNotifier.new,
);

/// Admin feedback provider with server-side filtering.
final adminFeedbackProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final query = ref.watch(feedbackQueryProvider);

  var request = client
      .from(SupabaseConstants.feedbackTable)
      .select()
      .order('created_at', ascending: false)
      .limit(query.limit);

  if (query.statusFilter != null) {
    request = request.eq('status', query.statusFilter!.toJson());
  }
  if (query.searchQuery.isNotEmpty) {
    final q = query.searchQuery
        .replaceAll(RegExp(r'[\x00-\x1f]'), '')
        .replaceAll(RegExp(r'[,.()\[\]\\]'), '')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    if (q.isNotEmpty) {
      request = request.or('message.ilike.%$q%,subject.ilike.%$q%');
    }
  }

  // Let errors propagate — no silent empty list
  final result = await request;
  return List<Map<String, dynamic>>.from(result);
});
```

Remove the old `feedbackStatusFilterProvider` (replaced by `feedbackQueryProvider`).

- [ ] **Step 5: Update admin_auth_utils.dart — Sentry for audit trail**

In `lib/features/admin/providers/admin_auth_utils.dart`, update `logAdminAction` (lines 32-49):

```dart
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../../core/utils/logger.dart';

Future<void> logAdminAction(
  SupabaseClient client, {
  required String action,
  String? targetUserId,
  String? details,
}) async {
  try {
    await client.from(SupabaseConstants.adminLogsTable).insert({
      'action': action,
      'admin_user_id': client.auth.currentUser?.id,
      'target_user_id': targetUserId,
      'details': details,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  } catch (e, st) {
    // Audit trail loss is critical — log AND report to Sentry
    AppLogger.error('admin', 'Failed to log admin action: $action', e, st);
    Sentry.captureException(e, stackTrace: st);
    // Do NOT rethrow — keep non-blocking for the main operation
  }
}
```

- [ ] **Step 6: Verify compilation**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

- [ ] **Step 7: Commit**

```bash
git add lib/features/admin/providers/admin_data_providers.dart lib/features/admin/providers/admin_dashboard_providers.dart lib/features/admin/providers/admin_capacity_providers.dart lib/features/admin/providers/admin_feedback_providers.dart lib/features/admin/providers/admin_auth_utils.dart
git commit -m "refactor(admin): server-side filtering, remove silent failures, add Sentry audit trail"
```

---

## Task 6: Database Manager — Chunk Export, Transaction RPC, Soft Delete

**Files:**
- Modify: `lib/features/admin/providers/admin_database_manager.dart`
- Modify: `lib/features/admin/providers/admin_user_manager.dart`
- Modify: `lib/features/admin/providers/admin_actions_provider.dart`
- Create: `supabase/migrations/20260329180000_add_reset_user_data_rpc.sql`

- [ ] **Step 1: Add chunk-based export to admin_database_manager.dart**

Add import at top of `lib/features/admin/providers/admin_database_manager.dart`:
```dart
import '../constants/admin_constants.dart';
```

Add a new private method after line 280 (before `_formatBytes`):

```dart
/// Fetches table data in chunks to avoid memory issues.
/// Returns rows up to [AdminConstants.maxExportRows].
Future<List<Map<String, dynamic>>> _exportTableChunked(String tableName) async {
  final allRows = <Map<String, dynamic>>[];
  var offset = 0;

  while (true) {
    final chunk = await _client
        .from(tableName)
        .select()
        .range(offset, offset + AdminConstants.exportChunkSize - 1);

    final rows = List<Map<String, dynamic>>.from(chunk);
    allRows.addAll(rows);

    if (rows.length < AdminConstants.exportChunkSize) break;
    offset += AdminConstants.exportChunkSize;

    if (allRows.length >= AdminConstants.maxExportRows) {
      AppLogger.warning(
        'admin',
        'Export truncated at ${AdminConstants.maxExportRows} rows for $tableName',
      );
      break;
    }
  }

  return allRows;
}
```

Then update the fallback in `exportTable()` (line 98) to use `_exportTableChunked` instead of `.limit(10000)`:

Replace:
```dart
final result = await _client.from(tableName).select().limit(10000);
```
With:
```dart
final result = await _exportTableChunked(tableName);
```

And similarly in `exportAllTables()` fallback (line 139):
Replace `.limit(10000)` usage with `_exportTableChunked(tableName)`.

- [ ] **Step 2: Update resetAllUserData to use RPC transaction**

Replace the fallback deletion logic in `resetAllUserData` to prefer RPC:

The RPC call already exists at line 234. Make sure the fallback logs a warning about partial state risk:

After the catch block for the RPC call (around line 238), add:
```dart
AppLogger.warning(
  'admin',
  'RPC reset_user_data unavailable, falling back to sequential deletes (no transaction guarantee)',
);
```

- [ ] **Step 3: Create the Supabase migration for reset RPC**

Create `supabase/migrations/20260329180000_add_reset_user_data_rpc.sql`:

```sql
-- Transaction-safe user data reset function.
-- Deletes all user data in FK-safe order within a single transaction.
-- Profile and auth records are preserved.
CREATE OR REPLACE FUNCTION reset_user_data(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized: admin access required';
  END IF;

  -- Delete in FK-safe order (deepest children first)
  DELETE FROM event_reminders WHERE user_id = target_user_id;
  DELETE FROM growth_measurements WHERE user_id = target_user_id;
  DELETE FROM health_records WHERE user_id = target_user_id;
  DELETE FROM chicks WHERE user_id = target_user_id;
  DELETE FROM eggs WHERE user_id = target_user_id;
  DELETE FROM incubations WHERE user_id = target_user_id;
  DELETE FROM breeding_pairs WHERE user_id = target_user_id;
  DELETE FROM birds WHERE user_id = target_user_id;
  DELETE FROM nests WHERE user_id = target_user_id;
  DELETE FROM events WHERE user_id = target_user_id;
  DELETE FROM notifications WHERE user_id = target_user_id;
  DELETE FROM notification_settings WHERE user_id = target_user_id;
  DELETE FROM photos WHERE user_id = target_user_id;
  DELETE FROM sync_metadata WHERE user_id = target_user_id;
  DELETE FROM genetics_history WHERE user_id = target_user_id;
  -- Profile preserved intentionally
END;
$$;

-- Only admins can call this function
REVOKE ALL ON FUNCTION reset_user_data(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION reset_user_data(uuid) TO authenticated;
```

- [ ] **Step 4: Update premium revoke — soft delete in admin_user_manager.dart**

In `lib/features/admin/providers/admin_user_manager.dart`, find the `revokePremium` method. Replace the DELETE operation (around lines 127-130) with an UPDATE:

Find the line that does:
```dart
.delete()
```
Replace with:
```dart
.update({
  'status': 'revoked',
  'updated_at': DateTime.now().toUtc().toIso8601String(),
})
```

- [ ] **Step 5: Fix missing provider invalidation in admin_actions_provider.dart**

In `lib/features/admin/providers/admin_actions_provider.dart`, find `dismissSecurityEvent` method. After `state = state.copyWith(isLoading: false, isSuccess: true);` add:

```dart
ref.invalidate(adminSecurityEventsProvider);
ref.invalidate(adminSystemAlertsProvider);
```

Add imports at top if missing:
```dart
import 'admin_filter_providers.dart';
import 'admin_dashboard_providers.dart';
```

Also verify that `clearAuditLogs` already invalidates `adminAuditLogsProvider` (the renamed provider).

- [ ] **Step 6: Add CSV export support to admin_actions_provider.dart**

Add an enum and update `exportTable`:

```dart
/// Export format options.
enum ExportFormat { json, csv }
```

Update the `exportTable` and `exportAllTables` method signatures to accept an optional `ExportFormat format` parameter. In the action notifier, after getting JSON data, convert to CSV if requested:

```dart
String _toCsv(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) return '';
  final headers = rows.first.keys.join(',');
  final lines = rows.map(
    (r) => r.values.map((v) => '"${(v ?? '').toString().replaceAll('"', '""')}"').join(','),
  );
  return [headers, ...lines].join('\n');
}
```

- [ ] **Step 7: Verify compilation**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

- [ ] **Step 8: Commit**

```bash
git add lib/features/admin/providers/admin_database_manager.dart lib/features/admin/providers/admin_user_manager.dart lib/features/admin/providers/admin_actions_provider.dart supabase/migrations/20260329180000_add_reset_user_data_rpc.sql
git commit -m "feat(admin): chunk export, transaction RPC, premium soft-delete, CSV support"
```

---

## Task 7: UI Widgets — Enum-Based Colors/Icons, Semantic Labels

**Files:**
- Modify: `lib/features/admin/widgets/admin_audit_content.dart`
- Modify: `lib/features/admin/widgets/admin_security_content.dart`

- [ ] **Step 1: Update admin_audit_content.dart — enum-based action icons**

In `lib/features/admin/widgets/admin_audit_content.dart`:

Add import:
```dart
import '../../../core/enums/admin_enums.dart';
```

Find the `_iconForAction` method (around line 223). Replace the string-matching logic with enum-based:

```dart
Widget _iconForAction(String action, ColorScheme colorScheme) {
  final type = AdminActionType.fromJson(action);
  final color = switch (type) {
    AdminActionType.delete || AdminActionType.reset || AdminActionType.clearLogs =>
      colorScheme.error,
    AdminActionType.create || AdminActionType.grantPremium =>
      AppColors.budgieGreen,
    AdminActionType.update || AdminActionType.toggleActive =>
      colorScheme.primary,
    AdminActionType.login || AdminActionType.logout =>
      colorScheme.tertiary,
    _ => colorScheme.onSurfaceVariant,
  };
  final icon = switch (type) {
    AdminActionType.delete => LucideIcons.trash2,
    AdminActionType.create => LucideIcons.plus,
    AdminActionType.update => LucideIcons.pencil,
    AdminActionType.login => LucideIcons.logIn,
    AdminActionType.logout => LucideIcons.logOut,
    AdminActionType.grantPremium => LucideIcons.crown,
    AdminActionType.revokePremium => LucideIcons.crownOff,
    AdminActionType.toggleActive => LucideIcons.userCheck,
    AdminActionType.export => LucideIcons.download,
    AdminActionType.reset => LucideIcons.rotateCcw,
    AdminActionType.clearLogs => LucideIcons.eraser,
    AdminActionType.dismissEvent => LucideIcons.checkCircle,
    AdminActionType.unknown => LucideIcons.activity,
  };
  return Icon(icon, size: 18, color: color, semanticsLabel: action);
}
```

Add `semanticsLabel` to other icons in the file:
- Find all `Icon(` and `AppIcon(` calls without `semanticsLabel` and add them.

- [ ] **Step 2: Update admin_security_content.dart — enum-based severity**

In `lib/features/admin/widgets/admin_security_content.dart`:

Replace the `_severityColor`/`_severityIcon` logic that uses string matching (around lines 149-169) with:

```dart
Color _severityColor(SecurityEvent event, ColorScheme colorScheme) {
  return switch (event.severity) {
    SecuritySeverityLevel.high => colorScheme.error,
    SecuritySeverityLevel.medium => AppColors.warning,
    SecuritySeverityLevel.low => colorScheme.primary,
    SecuritySeverityLevel.unknown => colorScheme.onSurfaceVariant,
  };
}

IconData _severityIcon(SecurityEvent event) {
  return switch (event.severity) {
    SecuritySeverityLevel.high => LucideIcons.alertTriangle,
    SecuritySeverityLevel.medium => LucideIcons.alertCircle,
    SecuritySeverityLevel.low => LucideIcons.info,
    SecuritySeverityLevel.unknown => LucideIcons.helpCircle,
  };
}
```

Remove the old string-matching severity inference code. Update the widget to use `event.severity` instead of local inference.

Add `semanticsLabel` to icons:
- `SecurityMetadataRow` icons (globe, clock)
- Dismiss button icon
- Summary card icons

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

- [ ] **Step 4: Commit**

```bash
git add lib/features/admin/widgets/admin_audit_content.dart lib/features/admin/widgets/admin_security_content.dart
git commit -m "refactor(admin): enum-based action/severity colors and semantic labels"
```

---

## Task 8: UI Widgets — Remaining Semantic Labels, Tooltips, Constants

**Files:**
- Modify: `lib/features/admin/widgets/admin_monitoring_content.dart`
- Modify: `lib/features/admin/widgets/admin_monitoring_content_cards.dart`
- Modify: `lib/features/admin/widgets/admin_sidebar.dart`
- Modify: `lib/features/admin/widgets/admin_dashboard_content.dart`
- Modify: `lib/features/admin/widgets/admin_dashboard_content_cards.dart`
- Modify: `lib/features/admin/widgets/admin_audit_filter_widgets.dart`
- Modify: `lib/features/admin/widgets/admin_security_filter_widgets.dart`
- Modify: `lib/features/admin/widgets/admin_user_detail_content.dart`

- [ ] **Step 1: Update admin_monitoring_content.dart — constants and semantic labels**

Add import:
```dart
import '../constants/admin_constants.dart';
```

Replace hardcoded values:
- Line 53: `500 * 1024 * 1024` → `AdminConstants.dbSizeLimitBytes`
- Line 59: `0.7` → `AdminConstants.healthyThreshold`
- Line 62: `0.9` → `AdminConstants.warningThreshold`
- Line 125: `600` → `AdminConstants.gridColumnBreakpoint`

Add `semanticsLabel` to all `Icon` and `AppIcon` calls:
- Line 135: `AppIcon(AppIcons.database)` → add `semanticsLabel: 'admin.database'.tr()`
- Line 142: `Icon(LucideIcons.plug)` → add `semanticsLabel: 'admin.connections'.tr()`
- Line 149: `Icon(LucideIcons.zap)` → add `semanticsLabel: 'admin.cache_hit'.tr()`
- Line 156: `Icon(LucideIcons.list)` → add `semanticsLabel: 'admin.total_rows'.tr()`

- [ ] **Step 2: Update admin_monitoring_content_cards.dart — semantic labels**

Add `semanticsLabel` to `AppIcon(AppIcons.statistics, ...)` (around line 116).

- [ ] **Step 3: Update admin_sidebar.dart — static menu list and semantic labels**

Move the menu items list from `build()` to a static field. Add `semanticsLabel` to:
- Header security icon (line 98-101)
- Back arrow icon (line 210)
- Add `tooltip: 'admin.back_to_app'.tr()` to the back button

- [ ] **Step 4: Update admin_dashboard_content.dart — constants and semantic labels**

Add import and replace:
- Line 167: `600` → `AdminConstants.gridColumnBreakpoint`
- Line 175: `1.4` / `1.15` → `AdminConstants.gridAspectRatioWide` / `AdminConstants.gridAspectRatioNarrow`

Add `semanticsLabel` to:
- Line 46: `AppIcon(AppIcons.settings)`
- Line 54: `AppIcon(AppIcons.users)`
- Line 134: `AppIcon(AppIcons.health, ...)`

- [ ] **Step 5: Update filter widgets — semantic labels and tooltips**

In `admin_audit_filter_widgets.dart`:
- Line 39: `AppIcon(AppIcons.search, size: 18)` → add `semanticsLabel: 'common.search'.tr()`
- Line 42: `Icon(LucideIcons.x, size: 18)` → add `semanticsLabel: 'common.clear'.tr()`
- Line 146: `Icon(LucideIcons.calendar, ...)` → add `semanticsLabel: 'calendar.title'.tr()`

In `admin_security_filter_widgets.dart`:
- Line 40: `AppIcon(AppIcons.search, size: 18)` → add `semanticsLabel: 'common.search'.tr()`
- Line 43: `Icon(LucideIcons.x, size: 18)` → add `semanticsLabel: 'common.clear'.tr()`

- [ ] **Step 6: Update admin_user_detail_content.dart — semantic labels**

Add `semanticsLabel` to avatar fallback icon and subscription icons.

- [ ] **Step 7: Verify compilation**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

- [ ] **Step 8: Commit**

```bash
git add lib/features/admin/widgets/
git commit -m "feat(admin): semantic labels, tooltips, AdminConstants for breakpoints"
```

---

## Task 9: UI Screens — Settings Model, Feedback Search, Debounce Fix, Pagination

**Files:**
- Modify: `lib/features/admin/widgets/admin_settings_content.dart`
- Modify: `lib/features/admin/screens/admin_feedback_screen.dart`
- Modify: `lib/features/admin/screens/admin_users_screen.dart`
- Modify: `lib/features/admin/screens/admin_monitoring_screen.dart`
- Modify: `lib/features/admin/screens/admin_audit_screen.dart`

- [ ] **Step 1: Update admin_settings_content.dart — use AdminSystemSettings model**

In `lib/features/admin/widgets/admin_settings_content.dart`, refactor to use `AdminSystemSettings.fromSettingsMap()` instead of raw map access. Replace `settingDefaults[key] ?? true` pattern with typed model field access.

- [ ] **Step 2: Add search to admin_feedback_screen.dart**

Add a `TextField` with debounce before the feedback list. Wire it to `feedbackQueryProvider`:

```dart
// Add to the screen, before the list
Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  child: TextField(
    decoration: InputDecoration(
      hintText: 'admin.search_feedback'.tr(),
      prefixIcon: AppIcon(AppIcons.search, size: 18, semanticsLabel: 'common.search'.tr()),
      suffixIcon: _searchQuery.isNotEmpty
          ? IconButton(
              icon: Icon(LucideIcons.x, size: 18, semanticsLabel: 'common.clear'.tr()),
              tooltip: 'common.clear'.tr(),
              onPressed: () {
                _searchController.clear();
                ref.read(feedbackQueryProvider.notifier).state =
                    ref.read(feedbackQueryProvider).copyWith(searchQuery: '');
              },
            )
          : null,
    ),
    onChanged: (value) {
      _debounce?.cancel();
      _debounce = Timer(AdminConstants.searchDebounceDuration, () {
        ref.read(feedbackQueryProvider.notifier).state =
            ref.read(feedbackQueryProvider).copyWith(searchQuery: value);
      });
    },
  ),
),
```

Convert `AdminFeedbackScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` for debounce timer and search controller. Add disposal:

```dart
@override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  super.dispose();
}
```

Update status filter to use `feedbackQueryProvider` instead of `feedbackStatusFilterProvider`.

- [ ] **Step 3: Fix debounce disposal in admin_users_screen.dart**

In `lib/features/admin/screens/admin_users_screen.dart`:

Add to `dispose()` method (around line 79):
```dart
_debounce?.cancel();
```

Replace hardcoded `Duration(milliseconds: 350)` (line 37) with:
```dart
AdminConstants.searchDebounceDuration
```

Add import: `import '../constants/admin_constants.dart';`

Update the users provider call to use `AdminUsersQuery` instead of string family:
```dart
final usersAsync = ref.watch(adminUsersProvider(AdminUsersQuery(
  searchTerm: _searchQuery,
  isActiveFilter: _statusFilter == _UserStatusFilter.active ? true
      : _statusFilter == _UserStatusFilter.inactive ? false : null,
  sortField: _sortField,
  sortAscending: _sortAscending,
  limit: ref.watch(adminUsersLimitProvider),
)));
```

Remove client-side `_applyFiltersAndSort()` method — filtering now server-side.

- [ ] **Step 4: Update admin_monitoring_screen.dart — use constant**

Replace line 13:
```dart
const _autoRefreshInterval = Duration(seconds: 30);
```
With:
```dart
import '../constants/admin_constants.dart';
```
And use `AdminConstants.monitoringRefreshInterval` in the `Timer.periodic` call.

- [ ] **Step 5: Update admin_audit_screen.dart — use constant**

Replace line 82 `+= 100` with `+= AdminConstants.auditLogsPageSize`.
Add import for AdminConstants.

- [ ] **Step 6: Verify compilation**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors

- [ ] **Step 7: Commit**

```bash
git add lib/features/admin/widgets/admin_settings_content.dart lib/features/admin/screens/
git commit -m "feat(admin): settings typed model, feedback search, debounce fixes, constant pagination"
```

---

## Task 10: Localization — New Admin Keys

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add new keys to tr.json**

In the `"admin"` section of `assets/translations/tr.json`, add:

```json
"export_format": "Disa Aktarma Formati",
"export_csv": "CSV",
"export_json": "JSON",
"search_feedback": "Geri bildirimlerde ara...",
"export_truncated": "Disa aktarma {} satirda kesildi",
"reset_transaction_failed": "Sifirlama islemi basarisiz oldu",
"back_to_app": "Uygulamaya Don",
"connections": "Baglantilar",
"cache_hit": "Onbellek Isabet Orani",
"total_rows": "Toplam Satir"
```

- [ ] **Step 2: Add same keys to en.json**

```json
"export_format": "Export Format",
"export_csv": "CSV",
"export_json": "JSON",
"search_feedback": "Search feedback...",
"export_truncated": "Export truncated at {} rows",
"reset_transaction_failed": "Reset operation failed, changes rolled back",
"back_to_app": "Back to App",
"connections": "Connections",
"cache_hit": "Cache Hit Ratio",
"total_rows": "Total Rows"
```

- [ ] **Step 3: Add same keys to de.json**

```json
"export_format": "Exportformat",
"export_csv": "CSV",
"export_json": "JSON",
"search_feedback": "Feedback durchsuchen...",
"export_truncated": "Export bei {} Zeilen abgeschnitten",
"reset_transaction_failed": "Zuruecksetzung fehlgeschlagen, Aenderungen rueckgaengig gemacht",
"back_to_app": "Zurueck zur App",
"connections": "Verbindungen",
"cache_hit": "Cache-Trefferquote",
"total_rows": "Gesamtzeilen"
```

- [ ] **Step 4: Verify l10n sync**

Run: `python scripts/check_l10n_sync.py`
Expected: All 3 files in sync, no missing keys

- [ ] **Step 5: Commit**

```bash
git add assets/translations/
git commit -m "feat(l10n): add new admin panel translation keys for tr/en/de"
```

---

## Task 11: Tests — Enum, Model, and Provider Tests

**Files:**
- Modify: `test/core/enums/admin_enums_test.dart`
- Modify: `test/features/admin/providers/admin_models_test.dart`
- Modify: `test/features/admin/providers/admin_filter_providers_test.dart`
- Modify: `test/features/admin/providers/admin_feedback_providers_test.dart`

- [ ] **Step 1: Add AdminActionType and SecurityEventType tests**

In `test/core/enums/admin_enums_test.dart`, add test groups:

```dart
group('AdminActionType', () {
  test('toJson/fromJson round-trip for all values', () {
    for (final value in AdminActionType.values) {
      if (value == AdminActionType.unknown) continue;
      expect(AdminActionType.fromJson(value.toJson()), value);
    }
  });

  test('fromJson falls back to unknown on invalid input', () {
    expect(AdminActionType.fromJson('nonexistent_action'), AdminActionType.unknown);
  });

  test('fromJson handles snake_case action strings', () {
    expect(AdminActionType.fromJson('delete_user'), AdminActionType.delete);
    expect(AdminActionType.fromJson('create_bird'), AdminActionType.create);
    expect(AdminActionType.fromJson('grant_premium'), AdminActionType.grantPremium);
    expect(AdminActionType.fromJson('toggle_active'), AdminActionType.toggleActive);
  });
});

group('SecurityEventType', () {
  test('toJson/fromJson round-trip for all values', () {
    for (final value in SecurityEventType.values) {
      if (value == SecurityEventType.unknown) continue;
      expect(SecurityEventType.fromJson(value.toJson()), value);
    }
  });

  test('fromJson falls back to unknown on invalid input', () {
    expect(SecurityEventType.fromJson('xyz'), SecurityEventType.unknown);
  });

  test('fromJson handles keyword matching', () {
    expect(SecurityEventType.fromJson('login_failed'), SecurityEventType.failedLogin);
    expect(SecurityEventType.fromJson('suspicious_activity'), SecurityEventType.suspiciousActivity);
    expect(SecurityEventType.fromJson('rate_limited'), SecurityEventType.rateLimited);
  });

  test('inferredSeverity returns correct levels', () {
    expect(SecurityEventType.bruteForce.inferredSeverity, SecuritySeverityLevel.high);
    expect(SecurityEventType.unauthorizedAccess.inferredSeverity, SecuritySeverityLevel.high);
    expect(SecurityEventType.suspiciousActivity.inferredSeverity, SecuritySeverityLevel.medium);
    expect(SecurityEventType.failedLogin.inferredSeverity, SecuritySeverityLevel.low);
    expect(SecurityEventType.unknown.inferredSeverity, SecuritySeverityLevel.unknown);
  });
});
```

- [ ] **Step 2: Add model tests for new Freezed models**

In `test/features/admin/providers/admin_models_test.dart`, add:

```dart
group('AdminUsersQuery', () {
  test('defaults are correct', () {
    const query = AdminUsersQuery();
    expect(query.searchTerm, '');
    expect(query.isActiveFilter, isNull);
    expect(query.sortField, 'created_at');
    expect(query.sortAscending, isFalse);
    expect(query.limit, 50);
  });

  test('copyWith works', () {
    const query = AdminUsersQuery();
    final updated = query.copyWith(searchTerm: 'test', isActiveFilter: true);
    expect(updated.searchTerm, 'test');
    expect(updated.isActiveFilter, isTrue);
  });

  test('toJson/fromJson round-trip', () {
    const query = AdminUsersQuery(searchTerm: 'hello', limit: 100);
    final json = query.toJson();
    final restored = AdminUsersQuery.fromJson(json);
    expect(restored.searchTerm, 'hello');
    expect(restored.limit, 100);
  });
});

group('FeedbackQuery', () {
  test('defaults are correct', () {
    const query = FeedbackQuery();
    expect(query.statusFilter, isNull);
    expect(query.searchQuery, '');
    expect(query.limit, 50);
  });

  test('toJson/fromJson round-trip', () {
    const query = FeedbackQuery(
      statusFilter: FeedbackStatus.open,
      searchQuery: 'bug',
      limit: 25,
    );
    final json = query.toJson();
    final restored = FeedbackQuery.fromJson(json);
    expect(restored.statusFilter, FeedbackStatus.open);
    expect(restored.searchQuery, 'bug');
  });
});

group('AdminSystemSettings', () {
  test('defaults are correct', () {
    const settings = AdminSystemSettings();
    expect(settings.maintenanceMode, isFalse);
    expect(settings.registrationOpen, isTrue);
    expect(settings.premiumEnabled, isTrue);
    expect(settings.autoBackupEnabled, isFalse);
    expect(settings.lastUpdated, isNull);
  });

  test('fromSettingsMap parses correctly', () {
    final map = {
      'maintenance_mode': {'value': true, 'updated_at': '2026-01-15T10:00:00Z'},
      'registration_open': {'value': false, 'updated_at': '2026-01-14T10:00:00Z'},
      'auto_backup_enabled': {'value': 'true', 'updated_at': null},
    };
    final settings = AdminSystemSettings.fromSettingsMap(map);
    expect(settings.maintenanceMode, isTrue);
    expect(settings.registrationOpen, isFalse);
    expect(settings.autoBackupEnabled, isTrue);
    expect(settings.lastUpdated, DateTime.utc(2026, 1, 15, 10));
  });
});

group('SecurityEvent', () {
  test('severity is derived from eventType', () {
    const event = SecurityEvent(
      id: 'e1',
      eventType: SecurityEventType.bruteForce,
      createdAt: DateTime(2024),
    );
    expect(event.severity, SecuritySeverityLevel.high);
  });

  test('fromJson handles string eventType', () {
    final json = {
      'id': 'e1',
      'event_type': 'suspicious_activity',
      'created_at': '2024-01-15T10:00:00Z',
    };
    final event = SecurityEvent.fromJson(json);
    expect(event.eventType, SecurityEventType.suspiciousActivity);
    expect(event.severity, SecuritySeverityLevel.medium);
  });

  test('fromJson defaults unknown eventType', () {
    final json = {
      'id': 'e2',
      'event_type': 'never_seen_before',
      'created_at': '2024-01-15T10:00:00Z',
    };
    final event = SecurityEvent.fromJson(json);
    expect(event.eventType, SecurityEventType.unknown);
  });
});
```

- [ ] **Step 3: Update filter provider tests**

In `test/features/admin/providers/admin_filter_providers_test.dart`, update tests that reference `filteredAuditLogsProvider` and `filteredSecurityEventsProvider` to use `adminAuditLogsProvider` and `adminSecurityEventsProvider`.

Update the `AdminAuditLimitNotifier` default test to expect `AdminConstants.auditLogsPageSize` (100) instead of hardcoded 100.

Add test for `AdminSecurityLimitNotifier`:

```dart
group('AdminSecurityLimitNotifier', () {
  test('initial value is securityEventsPageSize', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      container.read(adminSecurityLimitProvider),
      AdminConstants.securityEventsPageSize,
    );
  });
});
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/core/enums/ test/features/admin/providers/`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add test/core/enums/admin_enums_test.dart test/features/admin/providers/
git commit -m "test(admin): add enum, model, and provider tests for admin improvements"
```

---

## Task 12: Tests — Widget Tests Update

**Files:**
- Modify: `test/features/admin/widgets/admin_audit_content_test.dart`
- Modify: `test/features/admin/widgets/admin_security_content_test.dart`

- [ ] **Step 1: Update admin_audit_content_test.dart**

Update test log fixtures to verify enum-based icon rendering:

```dart
// Add test for enum-based action icon
testWidgets('renders correct icon for delete action', (tester) async {
  final deleteLog = AdminLog(
    id: 'log-del',
    action: 'delete_user',
    createdAt: DateTime(2024, 1, 15),
  );
  await tester.pumpWidget(_wrap(AuditContent(
    logs: [deleteLog],
    onLoadMore: null,
  )));
  await tester.pump();

  // Verify trash icon is rendered for delete action
  expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
});

testWidgets('renders correct icon for create action', (tester) async {
  final createLog = AdminLog(
    id: 'log-crt',
    action: 'create_bird',
    createdAt: DateTime(2024, 1, 15),
  );
  await tester.pumpWidget(_wrap(AuditContent(
    logs: [createLog],
    onLoadMore: null,
  )));
  await tester.pump();

  expect(find.byIcon(LucideIcons.plus), findsOneWidget);
});
```

- [ ] **Step 2: Update admin_security_content_test.dart**

Update security event fixtures to use `SecurityEventType` enum:

```dart
final _highSeverityEvent = SecurityEvent(
  id: 'evt-1',
  eventType: SecurityEventType.bruteForce,
  createdAt: DateTime(2024, 1, 15),
  ipAddress: '192.168.1.100',
);

testWidgets('renders high severity icon for brute force event', (tester) async {
  await tester.pumpWidget(_wrap(ProviderScope(
    child: SecurityContent(events: [_highSeverityEvent]),
  )));
  await tester.pump();

  expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);
});
```

- [ ] **Step 3: Run all admin widget tests**

Run: `flutter test test/features/admin/widgets/`
Expected: All tests pass

- [ ] **Step 4: Commit**

```bash
git add test/features/admin/widgets/
git commit -m "test(admin): update widget tests for enum-based icons and severity"
```

---

## Task 13: Final Verification

**Files:** None (verification only)

- [ ] **Step 1: Run full analysis**

Run: `flutter analyze --no-fatal-infos`
Expected: No new errors or warnings

- [ ] **Step 2: Run all admin tests**

Run: `flutter test test/features/admin/ test/core/enums/admin_enums_test.dart`
Expected: All tests pass

- [ ] **Step 3: Run l10n sync check**

Run: `python scripts/check_l10n_sync.py`
Expected: All 3 files in sync

- [ ] **Step 4: Run code quality check**

Run: `python scripts/verify_code_quality.py`
Expected: No new violations

- [ ] **Step 5: Final commit if any remaining changes**

```bash
git status
# If any remaining unstaged changes:
git add -A && git commit -m "chore(admin): final cleanup after admin panel improvements"
```
