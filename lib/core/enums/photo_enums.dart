enum PhotoEntityType {
  unknown,
  bird,
  chick,
  egg,
  nest;

  String toJson() => name;
  static PhotoEntityType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return PhotoEntityType.unknown;
    }
  }
}
