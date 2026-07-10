import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/bird_enums.dart';
import '../../../core/enums/gamification_enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/services/gamification/gamification_action_recorder.dart';
import 'package:budgie_breeding_tracker/shared/providers/breeding.dart';
import '../../../domain/services/moderation/moderation_providers.dart';
import '../../../domain/services/moderation/content_moderation_service.dart';
import '../../../domain/services/premium/free_tier_limit_providers.dart';
import '../../../domain/services/premium/premium_providers.dart';
import 'marketplace_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

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
  }) => MarketplaceFormState(
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
    List<String> localImagePaths = const [],
    required String city,
  }) async {
    if (state.isLoading) return;
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

      // Client-side gate lives in canCreateListingProvider (local active-
      // listing count). This is the authoritative server-side check via the
      // validate-free-tier-limit Edge Function — without it a stale local
      // count or a direct repository call could bypass the limit entirely.
      final isPremium = ref.read(effectivePremiumProvider);
      if (!isPremium) {
        await ref
            .read(freeTierLimitServiceProvider)
            .guardMarketplaceListingLimit();
      }

      final repo = ref.read(marketplaceRepositoryProvider);
      final listingId = const Uuid().v7();

      List<String> imageUrls = const [];
      if (localImagePaths.isNotEmpty) {
        imageUrls = await repo.uploadImages(
          userId: userId,
          listingId: listingId,
          localPaths: localImagePaths,
        );
      }

      await repo.create({
        'id': listingId,
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
      });
      recordGamificationAction(
        ref,
        userId: userId,
        action: XpAction.createListing,
        referenceId: listingId,
      );
      // Invalidate the feed + owner-scoped list providers so the form
      // screen pops to fresh data instead of stale cache. Audit M2.
      ref.invalidate(marketplaceFeedProvider(userId));
      ref.invalidate(myMarketplaceListingsProvider(userId));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on FreeTierLimitException {
      state = state.copyWith(
        isLoading: false,
        error: 'marketplace.free_tier_limit'.tr(
          args: ['$marketplaceFreeTierMaxListings'],
        ),
      );
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
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
    List<String> localImagePaths = const [],
    required String city,
  }) async {
    if (state.isLoading) return;
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
      final userId = ref.read(currentUserIdProvider);

      List<String> imageUrls = const [];
      if (localImagePaths.isNotEmpty) {
        imageUrls = await repo.uploadImages(
          userId: userId,
          listingId: listingId,
          localPaths: localImagePaths,
        );
      }

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
      }, userId: userId);
      ref.invalidate(marketplaceFeedProvider(userId));
      ref.invalidate(myMarketplaceListingsProvider(userId));
      ref.invalidate(
        marketplaceListingByIdProvider((id: listingId, userId: userId)),
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  Future<void> deleteListing(String listingId) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      await repo.delete(listingId, userId: userId);
      ref.invalidate(marketplaceFeedProvider(userId));
      ref.invalidate(myMarketplaceListingsProvider(userId));
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
    }
  }

  Future<void> updateStatus(
    String listingId,
    MarketplaceListingStatus status,
  ) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repo = ref.read(marketplaceRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      await repo.updateStatus(listingId, status.toJson(), userId: userId);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppLogger.error('marketplace', e, st);
      state = state.copyWith(isLoading: false, error: 'errors.unknown'.tr());
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
      // The heart is non-optimistic — it renders from listing.isFavoritedByMe,
      // which comes from these list providers. Without a refresh the tap
      // appears to do nothing on the feed even on success. Invalidating here
      // (after the awaited write) updates the heart at every call site and
      // also fixes the favorites screen's prior microtask race, where the
      // invalidate could fire before the toggle completed.
      ref.invalidate(marketplaceFeedProvider(userId));
      ref.invalidate(marketplaceFavoritesProvider(userId));
    } catch (e, st) {
      AppLogger.error('marketplace.toggleFavorite', e, st);
      // Audit M7: the catch previously claimed the "form listener emits a
      // snackbar", but the feed/tab/favorites screens that actually call this
      // never listened — the failure was silent (gaslighting) there. Surface
      // via state.error; those screens now listen and show a snackbar.
      state = state.copyWith(error: 'marketplace.favorite_failed'.tr());
    }
  }

  void reset() => state = const MarketplaceFormState();
}

final marketplaceFormStateProvider =
    NotifierProvider<MarketplaceFormNotifier, MarketplaceFormState>(
      MarketplaceFormNotifier.new,
    );
