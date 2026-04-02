enum ConversationType {
  direct,
  group,
  unknown;

  String toJson() => name;

  static ConversationType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return ConversationType.unknown;
    }
  }
}

enum MessageType {
  text,
  image,
  birdCard,
  listingCard,
  unknown;

  String toJson() => name;

  static MessageType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return MessageType.unknown;
    }
  }
}

enum ParticipantRole {
  owner,
  admin,
  member,
  unknown;

  String toJson() => name;

  static ParticipantRole fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return ParticipantRole.unknown;
    }
  }
}
