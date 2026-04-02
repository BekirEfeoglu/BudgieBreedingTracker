enum MarketplaceListingType {
  sale,
  adoption,
  trade,
  wanted,
  unknown;

  String toJson() => name;

  static MarketplaceListingType fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return MarketplaceListingType.unknown;
    }
  }
}

enum MarketplaceListingStatus {
  active,
  sold,
  reserved,
  closed,
  unknown;

  String toJson() => name;

  static MarketplaceListingStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return MarketplaceListingStatus.unknown;
    }
  }
}
