enum BadgeCategory {
  breeding,
  community,
  marketplace,
  health,
  milestone,
  special,
  unknown;

  String toJson() => name;

  static BadgeCategory fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return BadgeCategory.unknown;
    }
  }
}

enum BadgeTier {
  bronze,
  silver,
  gold,
  platinum,
  unknown;

  String toJson() => name;

  static BadgeTier fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return BadgeTier.unknown;
    }
  }
}

enum XpAction {
  dailyLogin,
  addBird,
  createBreeding,
  recordChick,
  addHealthRecord,
  completeProfile,
  sharePost,
  addComment,
  receiveLike,
  createListing,
  sendMessage,
  unlockBadge,
  unknown;

  String toJson() => name;

  static XpAction fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return XpAction.unknown;
    }
  }
}
