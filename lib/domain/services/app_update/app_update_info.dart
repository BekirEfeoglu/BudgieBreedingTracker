class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuild,
    required this.minSupportedBuild,
    required this.storeUrl,
    this.releaseNotesTr,
    this.releaseNotesEn,
    this.releaseNotesDe,
  });

  final String latestVersion;
  final int latestBuild;
  final int minSupportedBuild;
  final String storeUrl;
  final String? releaseNotesTr;
  final String? releaseNotesEn;
  final String? releaseNotesDe;

  static AppUpdateInfo? fromSettingValue(
    Object? value, {
    required String platform,
    String? defaultStoreUrl,
  }) {
    if (value is String) {
      final version = value.trim();
      if (version.isEmpty) return null;
      final storeUrl = defaultStoreUrl;
      if (storeUrl == null || storeUrl.isEmpty) return null;
      return AppUpdateInfo(
        latestVersion: version,
        latestBuild: 0,
        minSupportedBuild: 0,
        storeUrl: storeUrl,
      );
    }

    if (value is! Map) return null;
    final platformValue = value[platform];
    final source = platformValue is Map ? platformValue : value;

    final latestVersion = _readString(source, const [
      'latest_version',
      'latestVersion',
      'version',
    ]);
    final latestBuild = _readInt(source, const ['latest_build', 'latestBuild']);
    final minSupportedBuild = _readInt(source, const [
      'min_supported_build',
      'minSupportedBuild',
      'minimum_build',
    ]);
    final storeUrl =
        _readString(source, const ['store_url', 'storeUrl']) ?? defaultStoreUrl;

    if (latestVersion == null || storeUrl == null || storeUrl.isEmpty) {
      return null;
    }

    return AppUpdateInfo(
      latestVersion: latestVersion,
      latestBuild: latestBuild ?? 0,
      minSupportedBuild: minSupportedBuild ?? 0,
      storeUrl: storeUrl,
      releaseNotesTr: _readString(source, const [
        'release_notes_tr',
        'releaseNotesTr',
      ]),
      releaseNotesEn: _readString(source, const [
        'release_notes_en',
        'releaseNotesEn',
      ]),
      releaseNotesDe: _readString(source, const [
        'release_notes_de',
        'releaseNotesDe',
      ]),
    );
  }

  AppUpdateStatus evaluate({
    required String currentVersion,
    required int currentBuild,
  }) {
    final hasBuildUpdate = latestBuild > 0 && latestBuild > currentBuild;
    final hasVersionUpdate =
        latestBuild == 0 &&
        compareVersionNames(latestVersion, currentVersion) > 0;
    final isRequired =
        minSupportedBuild > 0 && currentBuild < minSupportedBuild;

    return AppUpdateStatus(
      info: this,
      isUpdateAvailable: hasBuildUpdate || hasVersionUpdate || isRequired,
      isRequired: isRequired,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
    );
  }
}

class AppStoreListing {
  const AppStoreListing({required this.version, required this.storeUrl});

  final String version;
  final String storeUrl;

  static AppStoreListing? fromLookupJson(Map<String, dynamic> json) {
    final results = json['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map) return null;

    final version = first['version'];
    final storeUrl = first['trackViewUrl'];
    if (version is! String || version.trim().isEmpty) return null;
    if (storeUrl is! String || storeUrl.trim().isEmpty) return null;

    return AppStoreListing(version: version.trim(), storeUrl: storeUrl.trim());
  }
}

AppUpdateInfo? resolveAppUpdateInfo({
  required Object? settingValue,
  required AppStoreListing? appStoreListing,
  required String platform,
  required String defaultStoreUrl,
}) {
  final configured = AppUpdateInfo.fromSettingValue(
    settingValue,
    platform: platform,
    defaultStoreUrl: defaultStoreUrl,
  );

  if (appStoreListing == null) return configured;
  if (configured == null ||
      compareVersionNames(appStoreListing.version, configured.latestVersion) >
          0) {
    return AppUpdateInfo(
      latestVersion: appStoreListing.version,
      latestBuild: 0,
      minSupportedBuild: configured?.minSupportedBuild ?? 0,
      storeUrl: appStoreListing.storeUrl,
      releaseNotesTr: configured?.releaseNotesTr,
      releaseNotesEn: configured?.releaseNotesEn,
      releaseNotesDe: configured?.releaseNotesDe,
    );
  }

  return configured;
}

class AppUpdateStatus {
  const AppUpdateStatus({
    required this.info,
    required this.isUpdateAvailable,
    required this.isRequired,
    required this.currentVersion,
    required this.currentBuild,
  });

  final AppUpdateInfo info;
  final bool isUpdateAvailable;
  final bool isRequired;
  final String currentVersion;
  final int currentBuild;
}

int compareVersionNames(String left, String right) {
  final leftParts = _versionParts(left);
  final rightParts = _versionParts(right);
  final length = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;

  for (var i = 0; i < length; i++) {
    final leftPart = i < leftParts.length ? leftParts[i] : 0;
    final rightPart = i < rightParts.length ? rightParts[i] : 0;
    if (leftPart != rightPart) return leftPart.compareTo(rightPart);
  }
  return 0;
}

List<int> _versionParts(String value) {
  return value
      .split(RegExp(r'[^0-9]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => int.tryParse(part) ?? 0)
      .toList();
}

String? _readString(Map<dynamic, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

int? _readInt(Map<dynamic, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}
