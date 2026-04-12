/// Result of a data import operation.
class ImportResult {
  final int totalRows;
  final int importedCount;
  final int skippedCount;
  final List<String> errors;

  const ImportResult({
    required this.totalRows,
    required this.importedCount,
    required this.skippedCount,
    required this.errors,
  });
}
