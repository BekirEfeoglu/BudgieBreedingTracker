import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../data/remote/supabase/supabase_client.dart';
import 'app_store_lookup_service.dart';
import 'app_update_info.dart';

final appUpdateStatusProvider = FutureProvider<AppUpdateStatus?>((ref) async {
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
    final platform = Platform.isIOS ? 'ios' : 'android';
    final defaultStoreUrl = Platform.isIOS
        ? AppConstants.appStoreProductUrl
        : AppConstants.playStoreUrl;

    final client = ref.watch(supabaseClientProvider);
    final row = await client
        .from(SupabaseConstants.systemSettingsTable)
        .select('value')
        .eq('key', 'app_version')
        .maybeSingle();

    final appStoreListing = Platform.isIOS
        ? await const AppStoreLookupService().fetchLatest()
        : null;
    final info = resolveAppUpdateInfo(
      settingValue: row?['value'],
      appStoreListing: appStoreListing,
      platform: platform,
      defaultStoreUrl: defaultStoreUrl,
    );
    if (info == null) return null;

    final status = info.evaluate(
      currentVersion: packageInfo.version,
      currentBuild: currentBuild,
    );
    return status.isUpdateAvailable ? status : null;
  } catch (e, st) {
    AppLogger.warning('[AppUpdate] Check failed, continuing normally: $e');
    AppLogger.error('[AppUpdate] Version check error', e, st);
    return null;
  }
});
