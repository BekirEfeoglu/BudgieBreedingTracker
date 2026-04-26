import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_auth_utils.dart';
import 'admin_dashboard_providers.dart';
import 'admin_database_providers.dart';
import 'admin_feedback_providers.dart';
import 'admin_health_providers.dart';

/// Operational health rollup for the admin dashboard.
class AdminSystemHealthOverview {
  const AdminSystemHealthOverview({
    required this.status,
    required this.degradedServices,
    required this.pendingSyncCount,
    required this.errorSyncCount,
    required this.openFeedbackCount,
    required this.securityEvents24h,
    required this.activeAlertCount,
    required this.storageBytes,
  });

  final String status;
  final List<String> degradedServices;
  final int pendingSyncCount;
  final int errorSyncCount;
  final int openFeedbackCount;
  final int securityEvents24h;
  final int activeAlertCount;
  final int storageBytes;

  bool get hasWarnings =>
      status != 'ok' ||
      degradedServices.isNotEmpty ||
      errorSyncCount > 0 ||
      securityEvents24h > 0 ||
      activeAlertCount > 0;
}

final adminSystemHealthOverviewProvider =
    FutureProvider<AdminSystemHealthOverview>((ref) async {
      await requireAdmin(ref);

      final health = await ref.watch(systemHealthProvider.future);
      final sync = await ref.watch(syncStatusSummaryProvider.future);
      final feedbackCount = await ref.watch(
        adminOpenFeedbackCountProvider.future,
      );
      final security = await ref.watch(recentErrorsSummaryProvider.future);
      final alerts = await ref.watch(adminSystemAlertsProvider.future);
      final storage = await ref.watch(storageUsageProvider.future);

      final checks = health['checks'] as Map<String, dynamic>?;
      final degradedServices = <String>[];
      if (checks != null) {
        for (final entry in checks.entries) {
          if (entry.value != 'ok') degradedServices.add(entry.key);
        }
      }

      return AdminSystemHealthOverview(
        status: health['status'] as String? ?? 'unavailable',
        degradedServices: degradedServices,
        pendingSyncCount: sync.pendingCount,
        errorSyncCount: sync.errorCount,
        openFeedbackCount: feedbackCount,
        securityEvents24h: security.totalErrors,
        activeAlertCount: alerts.length,
        storageBytes: storage.fold<int>(
          0,
          (sum, bucket) => sum + bucket.totalSizeBytes,
        ),
      );
    });

/// Notification item surfaced in the admin dashboard notification center.
class AdminNotificationItem {
  const AdminNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String severity;
  final DateTime createdAt;
}

final adminNotificationCenterProvider =
    FutureProvider<List<AdminNotificationItem>>((ref) async {
      await requireAdmin(ref);

      final alerts = await ref.watch(adminSystemAlertsProvider.future);
      final feedbackCount = await ref.watch(
        adminOpenFeedbackCountProvider.future,
      );
      final sync = await ref.watch(syncStatusSummaryProvider.future);
      final security = await ref.watch(recentErrorsSummaryProvider.future);

      final items = <AdminNotificationItem>[
        for (final alert in alerts)
          AdminNotificationItem(
            id: alert.id,
            title: alert.title.isNotEmpty ? alert.title : alert.alertType,
            message: alert.message,
            severity: alert.severity.name,
            createdAt: alert.createdAt,
          ),
      ];

      final now = DateTime.now();
      if (feedbackCount > 0) {
        items.add(
          AdminNotificationItem(
            id: 'open_feedback',
            title: 'open_feedback',
            message: '$feedbackCount',
            severity: 'info',
            createdAt: now,
          ),
        );
      }
      if (sync.errorCount > 0) {
        items.add(
          AdminNotificationItem(
            id: 'sync_errors',
            title: 'sync_errors',
            message: '${sync.errorCount}',
            severity: 'warning',
            createdAt: now,
          ),
        );
      }
      if (security.highSeverity > 0) {
        items.add(
          AdminNotificationItem(
            id: 'security_high',
            title: 'security_high',
            message: '${security.highSeverity}',
            severity: 'critical',
            createdAt: now,
          ),
        );
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items.take(8).toList();
    });

/// Risk signals shown on the admin user detail screen.
class AdminUserRiskProfile {
  const AdminUserRiskProfile({
    required this.score,
    required this.securityEvents,
    required this.openFeedback,
    required this.syncErrors,
    required this.adminActions,
    required this.signals,
  });

  final int score;
  final int securityEvents;
  final int openFeedback;
  final int syncErrors;
  final int adminActions;
  final List<String> signals;

  String get level {
    if (score >= 70) return 'high';
    if (score >= 35) return 'medium';
    return 'low';
  }
}

final adminUserRiskProfileProvider =
    FutureProvider.family<AdminUserRiskProfile, String>((ref, userId) async {
      await requireAdmin(ref);
      final client = ref.watch(supabaseClientProvider);
      final since = DateTime.now()
          .subtract(const Duration(days: 30))
          .toUtc()
          .toIso8601String();

      Future<int> safeCount(
        String table, {
        required String column,
        required Object value,
        String? sinceColumn,
      }) async {
        try {
          var query = client.from(table).count().eq(column, value);
          if (sinceColumn != null) {
            query = query.gte(sinceColumn, since);
          }
          return await query;
        } catch (e, st) {
          AppLogger.warning('adminUserRiskProfile count failed for $table: $e');
          AppLogger.debug(st.toString());
          return 0;
        }
      }

      final (securityEvents, openFeedback, syncErrors, adminActions) = await (
        safeCount(
          SupabaseConstants.securityEventsTable,
          column: SupabaseConstants.colUserId,
          value: userId,
          sinceColumn: SupabaseConstants.colCreatedAt,
        ),
        safeCount(
          SupabaseConstants.feedbackTable,
          column: SupabaseConstants.feedbackColUserId,
          value: userId,
        ),
        safeCount(
          SupabaseConstants.syncMetadataTable,
          column: SupabaseConstants.colUserId,
          value: userId,
        ),
        safeCount(
          SupabaseConstants.adminLogsTable,
          column: 'target_user_id',
          value: userId,
          sinceColumn: SupabaseConstants.colCreatedAt,
        ),
      ).wait;

      final signals = <String>[];
      if (securityEvents > 0) signals.add('security_events');
      if (openFeedback > 2) signals.add('frequent_feedback');
      if (syncErrors > 0) signals.add('sync_errors');
      if (adminActions > 2) signals.add('admin_attention');

      final score =
          (securityEvents * 25 +
                  openFeedback * 8 +
                  syncErrors * 15 +
                  adminActions * 10)
              .clamp(0, 100);

      return AdminUserRiskProfile(
        score: score,
        securityEvents: securityEvents,
        openFeedback: openFeedback,
        syncErrors: syncErrors,
        adminActions: adminActions,
        signals: signals,
      );
    });

/// Impact preview used before destructive bulk user operations.
class BulkDeletePreview {
  const BulkDeletePreview({
    required this.userCount,
    required this.birdsCount,
    required this.pairsCount,
    required this.eggsCount,
    required this.chicksCount,
    required this.healthRecordsCount,
    required this.eventsCount,
    required this.photosCount,
  });

  final int userCount;
  final int birdsCount;
  final int pairsCount;
  final int eggsCount;
  final int chicksCount;
  final int healthRecordsCount;
  final int eventsCount;
  final int photosCount;

  int get totalRecords =>
      birdsCount +
      pairsCount +
      eggsCount +
      chicksCount +
      healthRecordsCount +
      eventsCount +
      photosCount;
}

final bulkDeletePreviewProvider =
    FutureProvider.family<BulkDeletePreview, Set<String>>((ref, userIds) async {
      await requireAdmin(ref);
      final client = ref.watch(supabaseClientProvider);
      final ids = userIds.toList();

      Future<int> countByUser(String table) async {
        if (ids.isEmpty) return 0;
        try {
          return await client
              .from(table)
              .count()
              .inFilter(SupabaseConstants.colUserId, ids);
        } catch (e, st) {
          AppLogger.warning('bulkDeletePreview count failed for $table: $e');
          AppLogger.debug(st.toString());
          return 0;
        }
      }

      final (
        birds,
        pairs,
        eggs,
        chicks,
        healthRecords,
        events,
        photos,
      ) = await (
        countByUser(SupabaseConstants.birdsTable),
        countByUser(SupabaseConstants.breedingPairsTable),
        countByUser(SupabaseConstants.eggsTable),
        countByUser(SupabaseConstants.chicksTable),
        countByUser(SupabaseConstants.healthRecordsTable),
        countByUser(SupabaseConstants.eventsTable),
        countByUser(SupabaseConstants.photosTable),
      ).wait;

      return BulkDeletePreview(
        userCount: ids.length,
        birdsCount: birds,
        pairsCount: pairs,
        eggsCount: eggs,
        chicksCount: chicks,
        healthRecordsCount: healthRecords,
        eventsCount: events,
        photosCount: photos,
      );
    });

/// Role matrix rendered in settings so admin-only actions are explicit.
final adminRolePermissionMatrixProvider =
    Provider<List<({String role, List<String> permissions})>>((ref) {
      return const [
        (
          role: 'support_admin',
          permissions: ['feedback', 'users_read', 'notifications'],
        ),
        (
          role: 'moderator',
          permissions: ['feedback', 'audit', 'security_events'],
        ),
        (
          role: 'admin',
          permissions: ['users_write', 'monitoring', 'database_read'],
        ),
        (
          role: 'founder',
          permissions: [
            'destructive_actions',
            'role_management',
            'database_reset',
          ],
        ),
      ];
    });
