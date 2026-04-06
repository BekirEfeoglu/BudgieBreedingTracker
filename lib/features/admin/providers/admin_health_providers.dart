import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import 'admin_data_providers.dart';

/// System health via Edge Function.
/// Returns 'ok' status when Edge Function is not deployed (404).
/// Auto-refreshes every 5 minutes; manual refresh via ref.invalidate().
final systemHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Keep alive so the timer and alert listener survive tab switches
  ref.keepAlive();
  final client = ref.watch(edgeFunctionClientProvider);

  // Auto-refresh after 5 minutes
  final timer = Timer(const Duration(minutes: 5), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  final result = await client.checkSystemHealth();
  if (result.success) return result.data ?? {};
  final errorStr = result.error ?? '';
  // Edge Function not deployed → treat as unavailable, not as error
  if (errorStr.contains('404') || errorStr.contains('NOT_FOUND')) {
    return {'status': 'unavailable'};
  }
  // Auth error → session issue, not a system health problem
  if (errorStr.contains('401') || errorStr.contains('No authenticated session')) {
    return {'status': 'unavailable'};
  }
  return {'status': 'error', 'message': result.error};
});

/// Sends a push notification to all admin users when system health
/// transitions to degraded or error state. Tracks the last alerted status
/// to avoid duplicate notifications on repeated polls.
///
/// Activated by watching systemHealthProvider in the dashboard screen.
final systemHealthAlertProvider = Provider<void>((ref) {
  String? lastAlertedStatus;

  ref.listen<AsyncValue<Map<String, dynamic>>>(
    systemHealthProvider,
    fireImmediately: true,
    (previous, next) {
      next.whenData((data) {
        final status = data['status'] as String?;
        if (status == null || status == 'unavailable') return;

        if (status == 'ok') {
          // Was previously degraded/error → send recovery notification
          if (lastAlertedStatus != null) {
            _sendHealthAlertToAdmins(
              ref,
              title: 'admin.system_recovered_title',
              body: 'admin.system_recovered_body',
            );
          }
          lastAlertedStatus = null;
          return;
        }

        // Already alerted for this status — skip duplicate
        if (status == lastAlertedStatus) return;
        lastAlertedStatus = status;

        final degradedServices = <String>[];
        final checks = data['checks'] as Map<String, dynamic>?;
        if (checks != null) {
          for (final entry in checks.entries) {
            if (entry.value != 'ok') {
              degradedServices.add(entry.key);
            }
          }
        }

        final alertBody = degradedServices.isNotEmpty
            ? 'Sorunlu servisler: ${degradedServices.join(', ')}'
            : data['message'] as String? ?? 'Sistem durumu: $status';

        _sendHealthAlertToAdmins(
          ref,
          title: 'admin.system_alert_title',
          body: alertBody,
        );
      });
    },
  );
});

Future<void> _sendHealthAlertToAdmins(
  Ref ref, {
  required String title,
  required String body,
}) async {
  try {
    final client = ref.read(supabaseClientProvider);
    final adminsResult = await client
        .from(SupabaseConstants.adminUsersTable)
        .select('user_id');
    final adminIds = (adminsResult as List)
        .map((row) => row['user_id'] as String)
        .toList();

    if (adminIds.isEmpty) return;

    final edgeClient = ref.read(edgeFunctionClientProvider);
    await edgeClient.sendPush(
      userIds: adminIds,
      title: title,
      body: body,
      data: {'type': 'system_health_alert'},
    );
    AppLogger.info('[systemHealthAlert] Push sent to ${adminIds.length} admins');
  } catch (e, st) {
    AppLogger.error('[systemHealthAlert] $e', e, st);
  }
}
