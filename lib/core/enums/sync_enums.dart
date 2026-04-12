/// Type of sync conflict detected during pull operations.
enum ConflictType {
  serverWins,
  localOverwritten,
  orphanDeleted,
  unknown;

  String toJson() => name;

  static ConflictType fromJson(String json) {
    return ConflictType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => ConflictType.unknown,
    );
  }
}
