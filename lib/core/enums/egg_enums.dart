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
}
