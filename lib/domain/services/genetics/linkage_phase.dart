/// Explicit recombination phase for a father's linked Z-chromosome pair.
/// [auto] preserves the engine's implicit inference (current default behavior).
enum LinkagePhase {
  auto,
  coupling,
  repulsion;

  String toJson() => name;

  static LinkagePhase fromJson(String? json) {
    if (json == null) return LinkagePhase.auto;
    try {
      return values.byName(json);
    } catch (_) {
      return LinkagePhase.auto;
    }
  }
}

/// Canonical key for a linked mutation pair: the two ids sorted + joined,
/// so (id1,id2) and (id2,id1) produce the same key.
String linkagePairKey(String id1, String id2) {
  final sorted = [id1, id2]..sort();
  return '${sorted[0]}|${sorted[1]}';
}
