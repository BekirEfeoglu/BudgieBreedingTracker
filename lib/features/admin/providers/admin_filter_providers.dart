import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/admin_enums.dart';
import '../../auth/providers/auth_providers.dart';
import '../constants/admin_constants.dart';
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

/// Notifier for security events list limit (increases on "load more").
class AdminSecurityLimitNotifier extends Notifier<int> {
  @override
  int build() => AdminConstants.securityEventsPageSize;
}

/// Current limit for security events list (increases on "load more").
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

// ─── Sanitization Helpers ───────────────────────────────────────

/// Sanitizes a search query for safe use in PostgREST `.or()` / `.ilike()` filters.
///
/// - Removes ASCII control characters (0x00–0x1F, 0x7F)
/// - Removes PostgREST special characters that could break the filter syntax
/// - Escapes SQL wildcard characters so they are treated as literals
String _sanitizeSearchQuery(String query) {
  // Remove control characters
  var sanitized = query.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  // Remove PostgREST special chars: parentheses, comma, dot, colon, pipe
  sanitized = sanitized.replaceAll(RegExp(r'[(),.:|]'), '');
  // Escape SQL wildcards so they are treated as literal characters
  sanitized = sanitized.replaceAll('%', r'\%').replaceAll('_', r'\_');
  return sanitized.trim();
}

// ─── Server-Side Filtered Providers ────────────────────────────

/// Audit logs provider — applies date and text filters server-side.
final adminAuditLogsProvider =
    FutureProvider.autoDispose<List<AdminLog>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final filter = ref.watch(auditLogFilterProvider);
  final limit = ref.watch(adminAuditLimitProvider);

  var query = client.from(SupabaseConstants.adminLogsTable).select();

  // Date range filters
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
      23,
      59,
      59,
    );
    query = query.lte('created_at', endOfDay.toUtc().toIso8601String());
  }

  // Text search — server-side via PostgREST .or()
  final rawQuery = filter.searchQuery.trim();
  if (rawQuery.isNotEmpty) {
    final q = _sanitizeSearchQuery(rawQuery);
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

/// Security events provider — applies text and severity filters server-side.
final adminSecurityEventsProvider =
    FutureProvider.autoDispose<List<SecurityEvent>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final filter = ref.watch(securityEventFilterProvider);
  final limit = ref.watch(adminSecurityLimitProvider);

  var query = client.from(SupabaseConstants.securityEventsTable).select();

  // Severity filter — match event_type patterns associated with the severity level
  if (filter.severity != null) {
    final patterns = filter.severity!.eventTypePatterns;
    if (patterns.isNotEmpty) {
      final orClause = patterns
          .map((p) => 'event_type.ilike.$p')
          .join(',');
      query = query.or(orClause);
    }
  }

  // Text search — server-side via PostgREST .or()
  final rawQuery = filter.searchQuery.trim();
  if (rawQuery.isNotEmpty) {
    final q = _sanitizeSearchQuery(rawQuery);
    if (q.isNotEmpty) {
      query = query.or(
        'event_type.ilike.%$q%,details::text.ilike.%$q%,ip_address.ilike.%$q%',
      );
    }
  }

  final result = await query
      .order('created_at', ascending: false)
      .limit(limit);

  return (result as List)
      .map((row) => SecurityEvent.fromJson(row as Map<String, dynamic>))
      .toList();
});
