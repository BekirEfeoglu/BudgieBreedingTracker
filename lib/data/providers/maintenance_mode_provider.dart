import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/supabase_constants.dart';
import '../../core/utils/logger.dart';
import '../remote/supabase/supabase_client.dart';

/// Public maintenance mode flag read from Supabase.
///
/// This provider intentionally fails open so offline-first usage is preserved
/// when the status endpoint is unreachable.
final maintenanceModeProvider = FutureProvider<bool>((ref) async {
  try {
    final client = ref.watch(supabaseClientProvider);
    final row = await client
        .from(SupabaseConstants.systemSettingsTable)
        .select('value')
        .eq('key', 'maintenance_mode')
        .maybeSingle();

    if (row == null) return false;
    return parseMaintenanceModeValue(row['value']);
  } catch (e, st) {
    AppLogger.warning(
      '[MaintenanceMode] Check failed, continuing normally: $e',
    );
    AppLogger.error('[MaintenanceMode] Status check error', e, st);
    return false;
  }
});

bool parseMaintenanceModeValue(Object? value) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}
