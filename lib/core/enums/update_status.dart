/// Result of comparing local app build against remote `app_versions` row.
enum UpdateStatus {
  /// Local build >= latest build. No prompt shown.
  none,

  /// Local build < latest_build but >= min_supported_build.
  /// User sees dismissible bottom sheet.
  optional,

  /// Local build < min_supported_build. User sees full-screen blocker.
  forced;

  bool get isUpdateAvailable => this != UpdateStatus.none;
  bool get isBlocking => this == UpdateStatus.forced;
}
