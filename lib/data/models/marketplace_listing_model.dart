import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

part 'marketplace_listing_model.freezed.dart';
part 'marketplace_listing_model.g.dart';

@freezed
abstract class MarketplaceListing with _$MarketplaceListing {
  const MarketplaceListing._();

  const factory MarketplaceListing({
    required String id,
    required String userId,
    @Default('') String username,
    String? avatarUrl,
    @JsonKey(unknownEnumValue: MarketplaceListingType.unknown)
    @Default(MarketplaceListingType.sale)
    MarketplaceListingType listingType,
    @Default('') String title,
    @Default('') String description,
    double? price,
    @Default('TRY') String currency,
    String? birdId,
    @Default('') String species,
    String? mutation,
    @JsonKey(unknownEnumValue: BirdGender.unknown)
    @Default(BirdGender.unknown)
    BirdGender gender,
    String? age,
    @Default([]) List<String> imageUrls,
    @Default('') String city,
    @JsonKey(unknownEnumValue: MarketplaceListingStatus.unknown)
    @Default(MarketplaceListingStatus.active)
    MarketplaceListingStatus status,
    @Default(0) int viewCount,
    @Default(0) int messageCount,
    @Default(false) bool isVerifiedBreeder,
    @Default(false) bool isDeleted,
    @Default(false) bool needsReview,
    @JsonKey(includeFromJson: false) @Default(false) bool isFavoritedByMe,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _MarketplaceListing;

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceListingFromJson(json);
}

extension MarketplaceListingX on MarketplaceListing {
  String? get primaryImageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : null;

  bool get hasBirdLinked => birdId != null && birdId!.isNotEmpty;

  String get priceDisplay {
    if (price == null) return '';
    return '${price!.toStringAsFixed(0)} $currency';
  }
}
