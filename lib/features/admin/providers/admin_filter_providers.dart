import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/admin_enums.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';
import 'admin_models.dart';

/// Notifier for audit logs list limit (increases on "load more").
class AdminAuditLimitNotifier extends Notifier<int> {
  @override
  int build() => 100;
}

/// Current limit for audit logs list (increases on "load more").
final adminAuditLimitProvider =
    NotifierProvider<AdminAuditLimitNotifier, int>(AdminAuditLimitNotifier.new);

// ─── Filter State Classes ───────────────────────────────────────

/// Audit log filter state.
class AuditLogFilter {
  final String searchQuery;
  final DateTime? startDate;
  final DateTime? endDate;

  const AuditLogFilter({
    this.searchQuery = '',
    this.startDate,
    this.endDate,
  });

  AuditLogFilter copyWith({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) =>
      AuditLogFilter(
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

  const SecurityEventFilter({
    this.searchQuery = '',
    this.severity,
  });

  SecurityEventFilter copyWith({
    String? searchQuery,
    SecuritySeverityLevel? severity,
    bool clearSeverity = false,
  }) =>
      SecurityEventFilter(
        searchQuery: searchQuery ?? this.searchQuery,
        severity: clearSeverity ? null : (severity ?? this.severity),
      );

  bool get hasFilter =>
      searchQuery.isNotEmpty || severity != null;
}

// ─── Filter Notifiers ───────────────────────────────────────────

/// Notifier for audit log filter.
class AuditLogFilterNotifier extends Notifier<AuditLogFilter> {
  @override
  AuditLogFilter build() => const AuditLogFilter();
}

/// Audit log filter provider.
final auditLogFilterProvider =
    NotifierProvider<AuditLogFilterNotifier, AuditLogFilter>(AuditLogFilterNotifier.new);

/// Notifier for security event filter.
class SecurityEventFilterNotifier extends Notifier<SecurityEventFilter> {
  @override
  SecurityEventFilter build() => const SecurityEventFilter();
}

/// Security event filter provider.
final securityEventFilterProvider =
    NotifierProvider<SecurityEventFilterNotifier, SecurityEventFilter>(SecurityEventFilterNotifier.new);

// ─── Raw Data Providers ─────────────────────────────────────────

/// Admin audit logs provider (unfiltered).
final adminAuditLogsProvider =
    FutureProvider<List<AdminLog>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final result = await client
      .from(SupabaseConstants.adminLogsTable)
      .select()
      .order('created_at', ascending: false)
      .limit(100);

  return (result as List)
      .map((row) => AdminLog.fromJson(row as Map<String, dynamic>))
      .toList();
});

/// Security events provider (unfiltered).
final adminSecurityEventsProvider =
    FutureProvider<List<SecurityEvent>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  final result = await client
      .from(SupabaseConstants.securityEventsTable)
      .select()
      .order('created_at', ascending: false)
      .limit(100);

  return (result as List)
      .map((row) => SecurityEvent.fromJson(row as Map<String, dynamic>))
      .toList();
});

// ─── Filtered Providers ─────────────────────────────────────────

/// Filtered audit logs provider.
final filteredAuditLogsProvider =
    FutureProvider<List<AdminLog>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final filter = ref.watch(auditLogFilterProvider);

  var query = client
      .from(SupabaseConstants.adminLogsTable)
      .select();

  if (filter.startDate != null) {
    query = query.gte('created_at', filter.startDate!.toUtc().toIso8601String());
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

  final limit = ref.watch(adminAuditLimitProvider);
  final result = await query
      .order('created_at', ascending: false)
      .limit(limit);
  var logs = (result as List)
      .map((row) => AdminLog.fromJson(row as Map<String, dynamic>))
      .toList();

  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    logs = logs
        .where((log) =>
            log.action.toLowerCase().contains(q) ||
            (log.details?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  return logs;
});

/// Filtered security events provider.
final filteredSecurityEventsProvider =
    FutureProvider<List<SecurityEvent>>((ref) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);
  final filter = ref.watch(securityEventFilterProvider);

  final result = await client
      .from(SupabaseConstants.securityEventsTable)
      .select()
      .order('created_at', ascending: false)
      .limit(100);

  var events = (result as List)
      .map((row) => SecurityEvent.fromJson(row as Map<String, dynamic>))
      .toList();

  // Filter by severity
  if (filter.severity != null) {
    events = events.where((e) {
      final lower = e.eventType.toLowerCase();
      return switch (filter.severity!) {
        SecuritySeverityLevel.high =>
          lower.contains('suspicious') || lower.contains('attack'),
        SecuritySeverityLevel.medium =>
          lower.contains('failed') || lower.contains('rate_limit'),
        SecuritySeverityLevel.low =>
          !lower.contains('suspicious') &&
          !lower.contains('attack') &&
          !lower.contains('failed') &&
          !lower.contains('rate_limit'),
        SecuritySeverityLevel.unknown => true,
      };
    }).toList();
  }

  // Filter by search query
  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery.toLowerCase();
    events = events
        .where((e) =>
            e.eventType.toLowerCase().contains(q) ||
            (e.details?.toLowerCase().contains(q) ?? false) ||
            (e.ipAddress?.contains(q) ?? false))
        .toList();
  }

  return events;
});
