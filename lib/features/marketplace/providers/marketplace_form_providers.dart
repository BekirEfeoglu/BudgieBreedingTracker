import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/enums/bird_enums.dart';
import '../../../core/enums/marketplace_enums.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/repository_providers.dart';

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
      final repo = ref.read(marketplaceRepositoryProvider);
      // Free tier limit enforced server-side via validate-free-tier-limit Edge Function
      await repo.create({
        'id': const Uuid().v4(),
        'user_id': userId,
        'listing_type': listingType.toJson(),
        'title': title,
        'description': description,
        if (price != null) 'price': price,
        if (birdId != null) 'bird_id': birdId,
        'species': species,
        if (mutation != null) 'mutation': mutation,
        'gender': gender.toJson(),
        if (age != null) 'age': age,
        'image_urls': imageUrls,
        'city': city,
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
      final repo = ref.read(marketplaceRepositoryProvider);
      await repo.updateListing(listingId, {
        'listing_type': listingType.toJson(),
        'title': title,
        'description': description,
        'price': price,
        'bird_id': birdId,
        'species': species,
        'mutation': mutation,
        'gender': gender.toJson(),
        'age': age,
        'image_urls': imageUrls,
        'city': city,
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
