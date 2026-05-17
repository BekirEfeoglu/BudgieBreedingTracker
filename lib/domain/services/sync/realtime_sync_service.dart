import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_settings_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_telemetry.dart';

final syncRealtimeAllowlistProvider = Provider<Set<String>>((ref) {
  return const {
    SupabaseConstants.breedingPairsTable,
    SupabaseConstants.clutchesTable,
    SupabaseConstants.eggsTable,
  };
});

/// Remote-configurable kill switch. Defaults to safe/off in local code; server
/// config can override this provider through the app config layer during rollout.
final syncRealtimeServerKillSwitchProvider = Provider<bool>((ref) => false);

/// Remote-configurable rollout percentage for authenticated users.
final syncRealtimeRolloutPercentProvider = Provider<int>((ref) => 100);

final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  final service = RealtimeSyncService(ref, ref.watch(supabaseClientProvider));
  ref.onDispose(service.unsubscribe);
  return service;
});

class RealtimeSyncService {
  RealtimeSyncService(this._ref, this._client);

  static const maxReconnectFailures = 5;
  static const reconcileWindow = Duration(minutes: 5);

  final Ref _ref;
  final SupabaseClient _client;
  final List<RealtimeChannel> _channels = [];
  int _reconnectFailures = 0;
  String? _subscribedUserId;

  bool get isSubscribed => _channels.isNotEmpty;
  int get reconnectFailures => _reconnectFailures;

  Future<void> subscribeIfAllowed() async {
    final enabled = _ref.read(syncRealtimeEnabledProvider);
    final userId = _ref.read(currentUserIdProvider);
    final online = _ref.read(networkStatusProvider).asData?.value ?? true;
    final killSwitchEnabled = _ref.read(syncRealtimeServerKillSwitchProvider);
    final rolloutAllowed =
        !killSwitchEnabled &&
        isUserInRollout(
          userId: userId,
          percent: normalizeRolloutPercent(
            _ref.read(syncRealtimeRolloutPercentProvider),
          ),
        );

    if (!shouldSubscribe(
      enabled: enabled,
      userId: userId,
      online: online,
      rolloutAllowed: rolloutAllowed,
    )) {
      await unsubscribe();
      return;
    }
    if (isSubscribed && _subscribedUserId == userId) return;

    await unsubscribe();
    _subscribedUserId = userId;

    for (final table in _ref.read(syncRealtimeAllowlistProvider)) {
      final channel = _client
          .channel('sync:$table:$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              final recordId = extractRecordId(payload);
              if (recordId == null) return;
              unawaited(reconcileRemoteRecord(table, recordId));
            },
          )
          .subscribe((status, [error]) {
            _handleSubscribeStatus(status, table, error);
          });
      _channels.add(channel);
    }
  }

  Future<void> unsubscribe() async {
    final channels = List<RealtimeChannel>.from(_channels);
    _channels.clear();
    _subscribedUserId = null;
    for (final channel in channels) {
      unawaited(channel.unsubscribe());
    }
  }

  Future<void> reconcileRemoteRecord(String table, String recordId) async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;
    if (!_ref.read(syncRealtimeAllowlistProvider).contains(table)) return;

    AppLogger.debug('[RealtimeSync] $table/$recordId changed; reconciling');
    SyncTelemetry.event('realtime_event_received', data: {'table': table});
    await _ref
        .read(syncOrchestratorProvider)
        .pullChanges(userId, since: DateTime.now().subtract(reconcileWindow));
  }

  void _handleSubscribeStatus(
    RealtimeSubscribeStatus status,
    String table,
    Object? error,
  ) {
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _reconnectFailures = 0;
        AppLogger.debug('[RealtimeSync] Subscribed to $table');
      case RealtimeSubscribeStatus.channelError:
      case RealtimeSubscribeStatus.timedOut:
        _reconnectFailures++;
        AppLogger.warning(
          '[RealtimeSync] Subscription issue for $table: $status $error',
        );
        if (_reconnectFailures >= maxReconnectFailures) {
          AppLogger.warning('[RealtimeSync] Disabled after repeated failures');
          _ref.read(syncRealtimeEnabledProvider.notifier).setEnabled(false);
          unawaited(unsubscribe());
        }
      case RealtimeSubscribeStatus.closed:
        AppLogger.debug('[RealtimeSync] Closed for $table');
    }
  }

  static bool shouldSubscribe({
    required bool enabled,
    required String userId,
    required bool online,
    bool rolloutAllowed = true,
  }) {
    return enabled &&
        online &&
        rolloutAllowed &&
        userId != 'anonymous' &&
        userId.isNotEmpty;
  }

  static int normalizeRolloutPercent(int percent) {
    return percent.clamp(0, 100).toInt();
  }

  static bool isUserInRollout({required String userId, required int percent}) {
    final normalizedPercent = normalizeRolloutPercent(percent);
    if (normalizedPercent <= 0) return false;
    if (userId == 'anonymous' || userId.isEmpty) return false;
    if (normalizedPercent >= 100) return true;
    return rolloutBucket(userId) < normalizedPercent;
  }

  static int rolloutBucket(String userId) {
    var hash = 2166136261;
    for (final codeUnit in userId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash % 100;
  }

  static String? extractRecordId(PostgresChangePayload payload) {
    final raw =
        payload.newRecord[SupabaseConstants.colId] ??
        payload.oldRecord[SupabaseConstants.colId];
    return raw is String && raw.isNotEmpty ? raw : null;
  }
}
