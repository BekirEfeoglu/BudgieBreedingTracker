/// Represents a detected sync conflict where server data overwrote local data.
class SyncConflict {
  final String table;
  final String recordId;
  final DateTime detectedAt;
  final String description;

  const SyncConflict({
    required this.table,
    required this.recordId,
    required this.detectedAt,
    required this.description,
  });
}
