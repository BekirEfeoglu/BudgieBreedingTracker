enum ChickHealthStatus {
  healthy,
  sick,
  deceased,
  unknown;

  String toJson() => name;
  static ChickHealthStatus fromJson(String json) => values.byName(json);
}

enum DevelopmentStage {
  newborn,
  nestling,
  fledgling,
  juvenile,
  unknown;

  String toJson() => name;
  static DevelopmentStage fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return unknown;
    }
  }
}
