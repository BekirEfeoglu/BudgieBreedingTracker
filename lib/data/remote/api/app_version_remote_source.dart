import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../models/app_version_model.dart';

/// Online-only remote source for the `app_versions` table.
///
/// No local Drift mirror by design — version metadata changes server-side and
/// is read once per app session at startup. Fail-open on errors so offline
/// usage is preserved.
class AppVersionRemoteSource {
  final SupabaseClient _client;

  AppVersionRemoteSource(this._client);

  /// Fetches the version row for [platform] (`'ios'` or `'android'`).
  /// Returns null on missing row or transient error.
  Future<AppVersion?> fetchForPlatform(String platform) async {
    try {
      final row = await _client
          .from(SupabaseConstants.appVersionsTable)
          .select()
          .eq(SupabaseConstants.appVersionColPlatform, platform)
          .maybeSingle();

      if (row == null) return null;
      return AppVersion.fromJson(row);
    } catch (e, st) {
      AppLogger.warning('[AppVersionRemoteSource] fetch failed: $e');
      AppLogger.error('AppVersionRemoteSource', e, st);
      return null;
    }
  }
}
