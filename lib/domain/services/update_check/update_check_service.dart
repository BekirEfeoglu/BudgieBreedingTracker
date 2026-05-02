import '../../../core/enums/update_status.dart';
import '../../../data/models/app_version_model.dart';

/// Pure version-comparison logic. No I/O, no platform calls.
/// Provider layer wires `package_info_plus` + `AppVersionRemoteSource`.
class UpdateCheckService {
  const UpdateCheckService._();

  /// Compares the user's [currentBuild] against [remote] metadata.
  /// Null [remote] (fetch failed / row missing) returns [UpdateStatus.none]
  /// — fail-open so transient outages don't block users.
  static UpdateStatus compare({
    required int currentBuild,
    required AppVersion? remote,
  }) {
    if (remote == null) return UpdateStatus.none;
    if (currentBuild < remote.minSupportedBuild) return UpdateStatus.forced;
    if (currentBuild < remote.latestBuild) return UpdateStatus.optional;
    return UpdateStatus.none;
  }
}
