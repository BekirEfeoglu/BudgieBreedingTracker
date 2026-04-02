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
      AppLogger.error(
        'admin',
        'bulkDeleteUserData called for ${userIds.length} users',
        StackTrace.current,
      );
      final ok = await _databaseManager.resetAllUserData();
      if (ok) {
        succeeded = userIds.length;
      } else {
        skipped = userIds.length;
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
