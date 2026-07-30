/// Non-mutating summary of a backup selected for restore.
class BackupPreview {
  final bool success;
  final bool requiresPassword;
  final bool isEncrypted;
  final bool isPortable;
  final int? version;
  final DateTime? createdAt;
  final Map<String, int> entityCounts;
  final int recordCount;
  final String? error;

  const BackupPreview({
    required this.success,
    required this.requiresPassword,
    required this.isEncrypted,
    required this.isPortable,
    required this.entityCounts,
    required this.recordCount,
    this.version,
    this.createdAt,
    this.error,
  });

  factory BackupPreview.ready({
    required bool isEncrypted,
    required bool isPortable,
    required int version,
    required DateTime? createdAt,
    required Map<String, int> entityCounts,
  }) {
    return BackupPreview(
      success: true,
      requiresPassword: false,
      isEncrypted: isEncrypted,
      isPortable: isPortable,
      version: version,
      createdAt: createdAt,
      entityCounts: Map.unmodifiable(entityCounts),
      recordCount: entityCounts.values.fold(0, (sum, count) => sum + count),
    );
  }

  factory BackupPreview.passwordRequired() => const BackupPreview(
    success: false,
    requiresPassword: true,
    isEncrypted: true,
    isPortable: true,
    entityCounts: {},
    recordCount: 0,
  );

  factory BackupPreview.failure(
    String error, {
    bool isEncrypted = false,
    bool isPortable = false,
  }) {
    return BackupPreview(
      success: false,
      requiresPassword: false,
      isEncrypted: isEncrypted,
      isPortable: isPortable,
      entityCounts: const {},
      recordCount: 0,
      error: error,
    );
  }
}
