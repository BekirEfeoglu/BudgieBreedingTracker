/// Represents a detected sync conflict where server data overwrote local data.
class SyncConflict {
  final String table;
  final String recordId;
  final DateTime detectedAt;
  final String description;
  final String? historyId;
  final bool hasLocalSnapshot;
  final DateTime? resolvedAt;

  const SyncConflict({
    required this.table,
    required this.recordId,
    required this.detectedAt,
    required this.description,
    this.historyId,
    this.hasLocalSnapshot = false,
    this.resolvedAt,
  });

  bool get canRetryLocal => hasLocalSnapshot && resolvedAt == null;
}
