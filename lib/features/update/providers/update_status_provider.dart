import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/enums/update_status.dart';
import '../../../data/models/app_version_model.dart';
import '../../../data/remote/api/remote_source_providers.dart';
import '../../../domain/services/update_check/update_check_service.dart';

/// Reads the current app build number from `package_info_plus`.
/// Override in tests with a fixed int.
final currentBuildNumberProvider = FutureProvider<int>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return int.tryParse(info.buildNumber) ?? 0;
});

/// Returns `'ios'` or `'android'`. Override in tests.
final currentPlatformProvider = Provider<String>((ref) {
  if (Platform.isIOS) return 'ios';
  if (Platform.isAndroid) return 'android';
  return 'unknown';
});

/// Holds the fetched [AppVersion] for the current platform.
/// UI uses this for store URL + release notes.
final appVersionInfoProvider = FutureProvider<AppVersion?>((ref) async {
  final platform = ref.watch(currentPlatformProvider);
  if (platform == 'unknown') return null;
  final source = ref.watch(appVersionRemoteSourceProvider);
  return source.fetchForPlatform(platform);
});

/// Resolves the local-vs-remote update status. Fail-open on any error.
final updateStatusProvider = FutureProvider<UpdateStatus>((ref) async {
  try {
    final currentBuild = await ref.watch(currentBuildNumberProvider.future);
    final remote = await ref.watch(appVersionInfoProvider.future);
    return UpdateCheckService.compare(
      currentBuild: currentBuild,
      remote: remote,
    );
  } catch (_) {
    return UpdateStatus.none;
  }
});
