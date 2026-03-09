/// Result of a backup operation.
class BackupResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int recordCount;
  final DateTime timestamp;

  const BackupResult({
    required this.success,
    this.filePath,
    this.error,
    this.recordCount = 0,
    required this.timestamp,
  });

  factory BackupResult.success({
    required String filePath,
    required int recordCount,
  }) =>
      BackupResult(
        success: true,
        filePath: filePath,
        recordCount: recordCount,
        timestamp: DateTime.now(),
      );

  factory BackupResult.failure(String error) => BackupResult(
        success: false,
        error: error,
        timestamp: DateTime.now(),
      );
}
