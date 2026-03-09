enum EventType {
  unknown,
  custom,
  breeding,
  health,
  feeding,
  cleaning,
  mating,
  egg,
  chick,
  hatching,
  eggLaying,
  healthCheck,
  medication,
  vaccination,
  weightCheck,
  cageChange,
  other;

  String toJson() => name;
  static EventType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return EventType.unknown;
    }
  }
}

enum EventStatus {
  unknown,
  active,
  completed,
  cancelled,
  pending;

  String toJson() => name;
  static EventStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return EventStatus.unknown;
    }
  }
}
