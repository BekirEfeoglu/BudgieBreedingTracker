enum CommunityPostType {
  photo,
  question,
  guide,
  tip,
  showcase,
  general,
  unknown;

  String toJson() => name;

  static CommunityPostType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return CommunityPostType.unknown;
    }
  }
}

enum CommunityPostStatus {
  active,
  deleted,
  reported,
  hidden,
  unknown;

  String toJson() => name;

  static CommunityPostStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return CommunityPostStatus.unknown;
    }
  }
}

enum CommunityReportReason {
  spam,
  harassment,
  inappropriate,
  misinformation,
  other,
  unknown;

  String toJson() => name;

  static CommunityReportReason fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return CommunityReportReason.unknown;
    }
  }
}
