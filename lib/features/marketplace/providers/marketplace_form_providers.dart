import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/bird_enums.dart';
import '../../../core/enums/marketplace_enums.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../community/providers/community_moderation_providers.dart';
import '../../../domain/services/moderation/content_moderation_service.dart';

class MarketplaceFormState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  const MarketplaceFormState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  MarketplaceFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
  }) =>
      MarketplaceFormState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

class MarketplaceFormNotifier extends Notifier<MarketplaceFormState> {
  @override
  MarketplaceFormState build() => const MarketplaceFormState();

  static const _maxTitleLength = 200;
  static const _maxDescriptionLength = 2000;

  Future<void> createListing({
    required String userId,
    required MarketplaceListingType listingType,
    required String title,
    required String description,
    double? price,
    String? birdId,
    required String species,
    String? mutation,
    required BirdGender gender,
    String? age,
    required List<String> imageUrls,
    required String city,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      // Input length validation
      final trimmedTitle = title.trim();
      final trimmedDesc = description.trim();
      if (trimmedTitle.length > _maxTitleLength ||
          trimmedDesc.length > _maxDescriptionLength) {
        state = state.copyWith(
          isLoading: false,
          error: 'community.content_too_long'.tr(),
        );
        return;
      }

      // Price validation — must be non-negative
      if (price != null && price < 0) {
        state = state.copyWith(
          isLoading: false,
          error: 'validation.invalid_price'.tr(),
        );
        return;
      }

      // Content moderation check (Apple Guideline 1.2)
      final moderationService = ref.read(contentModerationServiceProvider);
      final textToCheck = '$trimmedTitle $trimmedDesc';
      final modResult = await moderationService.checkText(textToCheck);
      if (!modResult.isAllowed) {
        state = state.copyWith(
          isLoading: false,
          error: ContentModerationService.localizedError(
            modResult.rejectionReason,
          ),
        );
        return;
      }

      final repo = ref.read(marketplaceRepositoryProvider);
      // Free tier limit enforced server-side via validate-free-tier-limit Edge Function
      await repo.create({
        'id': const Uuid().v4(),
        'user_id': userId,
        'listing_type': listingType.toJson(),
        'title': trimmedTitle,
        'description': trimmedDesc,
        if (price != null) 'price': price,
        if (birdId != null) 'bird_id': birdId,
        'species': species,
        if (mutation != null) 'mutation': mutation,
        'gender': gender.toJson(),
        if (age != null) 'age': age,
        'image_urls': imageUrls,
        'city': city,
        if (modResult.needsReview) 'needs_review': true,
      });
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateListing({
    required String listingId,
    required MarketplaceListingType listingType,
    required String title,
    required String description,
    double? price,
    String? birdId,
    required String species,
    String? mutation,
    required BirdGender gender,
    String? age,
    required List<String> imageUrls,
    required String city,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final trimmedTitle = title.trim();
      final trimmedDesc = description.trim();
      if (trimmedTitle.length > _maxTitleLength ||
          trimmedDesc.length > _maxDescriptionLength) {
        state = state.copyWith(
          isLoading: false,
          error: 'community.content_too_long'.tr(),
        );
        return;
      }

      if (price != null && price < 0) {
        state = state.copyWith(
          isLoading: false,
          error: 'validation.invalid_price'.tr(),
        );
        return;
      }

      // Content moderation check
      final moderationService = ref.read(contentModerationServiceProvider);
      final textToCheck = '$trimmedTitle $trimmedDesc';
      final modResult = await moderationService.checkText(textToCheck);
      if (!modResult.isAllowed) {
        state = state.copyWith(
          isLoading: false,
          error: ContentModerationService.localizedError(
            modResult.rejectionReason,
          ),
        );
        return;
      }

      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateListing(listingId, {
        'listing_type': listingType.toJson(),
        'title': trimmedTitle,
        'description': trimmedDesc,
        'price': price,
        'bird_id': birdId,
        'species': species,
        'mutation': mutation,
        'gender': gender.toJson(),
        'age': age,
        'image_urls': imageUrls,
        'city': city,
        if (modResult.needsReview) 'needs_review': true,
      });
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteListing(String listingId) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.delete(listingId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus(
    String listingId,
    MarketplaceListingStatus status,
  ) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateStatus(listingId, status.toJson());
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleFavorite({
    required String userId,
    required String listingId,
    required bool isFavorited,
  }) async {
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.toggleFavorite(
        userId: userId,
        listingId: listingId,
        isFavorited: isFavorited,
      );
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
    }
  }

  void reset() => state = const MarketplaceFormState();
}

final marketplaceFormStateProvider =
    NotifierProvider<MarketplaceFormNotifier, MarketplaceFormState>(
  MarketplaceFormNotifier.new,
);
