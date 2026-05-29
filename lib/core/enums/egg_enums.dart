enum EggStatus {
  unknown,
  laid,
  fertile,
  infertile,
  hatched,
  empty,
  damaged,
  discarded,
  incubating;

  String toJson() => name;
  static EggStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return EggStatus.unknown;
    }
  }

  /// Whether this status is a terminal (end-of-lifecycle) state — the egg has
  /// no further valid transitions (hatched out, or removed from the clutch).
  ///
  /// Single source of truth for terminal-status checks across the breeding/egg
  /// flow (reminder cancellation, incubation auto-complete, active-egg
  /// filtering). Mirrors the no-transition arms of
  /// `IncubationCalculator.getValidStatusTransitions`.
  bool get isTerminal => switch (this) {
    EggStatus.hatched ||
    EggStatus.damaged ||
    EggStatus.discarded ||
    EggStatus.infertile ||
    EggStatus.empty => true,
    EggStatus.unknown ||
    EggStatus.laid ||
    EggStatus.fertile ||
    EggStatus.incubating => false,
  };
}
