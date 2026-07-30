import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/safe_cast.dart';
import '../../../shared/providers/auth.dart';
import '../constants/admin_constants.dart';
import 'admin_auth_utils.dart';

class BuildAdoptionEntry {
  const BuildAdoptionEntry({
    required this.appVersion,
    required this.userCount,
    required this.adoptionPercent,
    this.lastSeenAt,
  });

  final String appVersion;
  final int userCount;
  final double adoptionPercent;
  final DateTime? lastSeenAt;

  factory BuildAdoptionEntry.fromJson(Map<String, dynamic> json) {
    final appVersion = safeString(json, 'app_version');
    final userCount = (json['user_count'] as num?)?.toInt();
    final adoptionPercent = (json['adoption_percent'] as num?)?.toDouble();
    if (appVersion == null ||
        userCount == null ||
        userCount < 0 ||
        adoptionPercent == null ||
        adoptionPercent < 0 ||
        adoptionPercent > 100) {
      throw const ValidationException(
        'errors.unknown_error',
        code: 'build_adoption_entry_invalid',
      );
    }

    return BuildAdoptionEntry(
      appVersion: appVersion,
      userCount: userCount,
      adoptionPercent: adoptionPercent,
      lastSeenAt: DateTime.tryParse(
        json['last_seen_at']?.toString() ?? '',
      )?.toUtc(),
    );
  }
}

class PlatformBuildDistribution {
  const PlatformBuildDistribution({
    required this.platform,
    required this.totalUsers,
    required this.versionedUsers,
    required this.coveragePercent,
    this.builds = const [],
  });

  final String platform;
  final int totalUsers;
  final int versionedUsers;
  final double coveragePercent;
  final List<BuildAdoptionEntry> builds;

  factory PlatformBuildDistribution.fromJson(Map<String, dynamic> json) {
    final platform = safeString(json, 'platform');
    final totalUsers = (json['total_users'] as num?)?.toInt();
    final versionedUsers = (json['versioned_users'] as num?)?.toInt();
    final coveragePercent = (json['coverage_percent'] as num?)?.toDouble();
    if (platform == null ||
        !const {'ios', 'android'}.contains(platform) ||
        totalUsers == null ||
        totalUsers < 0 ||
        versionedUsers == null ||
        versionedUsers < 0 ||
        versionedUsers > totalUsers ||
        coveragePercent == null ||
        coveragePercent < 0 ||
        coveragePercent > 100) {
      throw const ValidationException(
        'errors.unknown_error',
        code: 'platform_build_distribution_invalid',
      );
    }

    return PlatformBuildDistribution(
      platform: platform,
      totalUsers: totalUsers,
      versionedUsers: versionedUsers,
      coveragePercent: coveragePercent,
      builds: safeList(json, 'builds')
          .map(asStringMap)
          .whereType<Map<String, dynamic>>()
          .map(BuildAdoptionEntry.fromJson)
          .toList(growable: false),
    );
  }
}

class BuildDistribution {
  const BuildDistribution({
    required this.windowDays,
    this.generatedAt,
    this.platforms = const [],
  });

  final int windowDays;
  final DateTime? generatedAt;
  final List<PlatformBuildDistribution> platforms;

  factory BuildDistribution.fromJson(Map<String, dynamic> json) {
    final windowDays = (json['window_days'] as num?)?.toInt();
    if (windowDays == null || windowDays < 1 || windowDays > 90) {
      throw const ValidationException(
        'errors.unknown_error',
        code: 'build_distribution_window_invalid',
      );
    }

    return BuildDistribution(
      windowDays: windowDays,
      generatedAt: DateTime.tryParse(
        json['generated_at']?.toString() ?? '',
      )?.toUtc(),
      platforms: safeList(json, 'platforms')
          .map(asStringMap)
          .whereType<Map<String, dynamic>>()
          .map(PlatformBuildDistribution.fromJson)
          .toList(growable: false),
    );
  }
}

final adminBuildDistributionProvider = FutureProvider<BuildDistribution>((
  ref,
) async {
  await requireAdmin(ref);
  final client = ref.watch(supabaseClientProvider);

  try {
    final result = await client.rpc(
      SupabaseConstants.adminGetBuildDistributionRpc,
      params: {'p_days': AdminConstants.buildAdoptionWindowDays},
    );
    final payload = asStringMap(result);
    if (payload == null) {
      throw const ValidationException(
        'errors.unknown_error',
        code: 'build_distribution_payload_invalid',
      );
    }
    return BuildDistribution.fromJson(payload);
  } catch (e, st) {
    AppLogger.error('[AdminBuildDistribution] load failed', e, st);
    rethrow;
  }
});
