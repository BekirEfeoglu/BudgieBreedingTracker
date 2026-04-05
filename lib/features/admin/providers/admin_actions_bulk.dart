part of 'admin_actions_provider.dart';

extension AdminBulkActions on AdminActionsNotifier {
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
          await _userManager.toggleUserActive(userId, activate);
          succeeded++;
        } catch (e) {
          if (e.toString().contains('protected') || e.toString().contains('Protected')) {
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
          if (e.toString().contains('protected') || e.toString().contains('Protected')) {
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
          if (e.toString().contains('protected') || e.toString().contains('Protected')) {
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

  Future<String> bulkExport(
    Set<String> userIds, {
    ExportFormat format = ExportFormat.json,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      await requireAdmin(ref);
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

  Future<({int succeeded, int skipped})> bulkDeleteUserData(
    Set<String> userIds,
  ) async {
    var succeeded = 0;
    var skipped = 0;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      await requireAdmin(ref);
      final client = ref.read(supabaseClientProvider);

      AppLogger.info(
        '[admin] bulkDeleteUserData called for ${userIds.length} users',
      );

      // Delete data for each user individually using soft-deletable tables.
      // FK-safe order: children first, parents last.
      const deletionOrder = [
        'event_reminders',
        'growth_measurements',
        'health_records',
        'photos',
        'events',
        'incubations',
        'chicks',
        'eggs',
        'clutches',
        'breeding_pairs',
        'nests',
        'notifications',
        'notification_settings',
        'notification_schedules',
        'birds',
      ];

      for (final userId in userIds) {
        try {
          for (final table in deletionOrder) {
            try {
              await client
                  .from(table)
                  .delete()
                  .eq('user_id', userId);
            } catch (_) {
              // Some tables may not have user_id column — skip silently.
            }
          }
          succeeded++;
        } catch (e) {
          AppLogger.warning(
            'admin: bulkDeleteUserData failed for $userId: $e',
          );
          skipped++;
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
}
