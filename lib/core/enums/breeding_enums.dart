enum BreedingStatus {
  unknown,
  active,
  ongoing,
  completed,
  cancelled;

  String toJson() => name;
  static BreedingStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return BreedingStatus.unknown;
    }
  }
}

enum NestStatus {
  unknown,
  available,
  occupied,
  maintenance;

  String toJson() => name;
  static NestStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return NestStatus.unknown;
    }
  }
}

enum IncubationStatus {
  unknown,
  active,
  completed,
  cancelled;

  String toJson() => name;
  static IncubationStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return IncubationStatus.unknown;
    }
  }
}
