@Tags(['community'])
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';
import 'package:budgie_breeding_tracker/data/models/marketplace_listing_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/content_moderation_service.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_moderation_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_form_providers.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

class MockContentModerationService extends Mock
    implements ContentModerationService {}

void main() {
  late MockMarketplaceRepository mockRepo;
  late MockContentModerationService mockModeration;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
    mockModeration = MockContentModerationService();
    container = ProviderContainer(overrides: [
      marketplaceRepositoryProvider.overrideWithValue(mockRepo),
      contentModerationServiceProvider.overrideWithValue(mockModeration),
      currentUserIdProvider.overrideWithValue('u1'),
    ]);
  });

  tearDown(() => container.dispose());

  test('initial state is correct', () {
    final state = container.read(marketplaceFormStateProvider);
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.isSuccess, false);
  });

  group('createListing', () {
    setUp(() {
      when(() => mockModeration.checkText(any()))
          .thenAnswer((_) async => const ModerationResult.allowed());
      when(() => mockRepo.create(any())).thenAnswer(
        (_) async => const MarketplaceListing(id: 'new', userId: 'u1'),
      );
    });

    test('sets isSuccess on success with moderation', () async {
      await container
          .read(marketplaceFormStateProvider.notifier)
          .createListing(
            userId: 'u1',
            listingType: MarketplaceListingType.sale,
            title: 'Test',
            description: 'Desc',
            price: 100,
            species: 'Budgerigar',
            gender: BirdGender.male,

            city: 'Istanbul',
          );

      verify(() => mockModeration.checkText('Test Desc')).called(1);
      verify(() => mockRepo.create(any())).called(1);
      final state = container.read(marketplaceFormStateProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('rejects listing when moderation fails', () async {
      when(() => mockModeration.checkText(any())).thenAnswer(
        (_) async => const ModerationResult.rejected('content_violation'),
      );

      await container
          .read(marketplaceFormStateProvider.notifier)
          .createListing(
            userId: 'u1',
            listingType: MarketplaceListingType.sale,
            title: 'Forbidden',
            description: 'Bad content',
            species: 'Budgerigar',
            gender: BirdGender.male,

            city: 'Istanbul',
          );

      verifyNever(() => mockRepo.create(any()));
      final state = container.read(marketplaceFormStateProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });

    test('rejects title exceeding max length', () async {
      final longTitle = 'a' * 201;

      await container
          .read(marketplaceFormStateProvider.notifier)
          .createListing(
            userId: 'u1',
            listingType: MarketplaceListingType.sale,
            title: longTitle,
            description: 'Desc',
            species: 'Budgerigar',
            gender: BirdGender.male,

            city: 'Istanbul',
          );

      verifyNever(() => mockModeration.checkText(any()));
      verifyNever(() => mockRepo.create(any()));
      final state = container.read(marketplaceFormStateProvider);
      expect(state.error, isNotNull);
    });

    test('rejects description exceeding max length', () async {
      final longDesc = 'a' * 2001;

      await container
          .read(marketplaceFormStateProvider.notifier)
          .createListing(
            userId: 'u1',
            listingType: MarketplaceListingType.sale,
            title: 'Valid',
            description: longDesc,
            species: 'Budgerigar',
            gender: BirdGender.male,

            city: 'Istanbul',
          );

      verifyNever(() => mockModeration.checkText(any()));
      verifyNever(() => mockRepo.create(any()));
      final state = container.read(marketplaceFormStateProvider);
      expect(state.error, isNotNull);
    });

    test('rejects negative price', () async {
      await container
          .read(marketplaceFormStateProvider.notifier)
          .createListing(
            userId: 'u1',
            listingType: MarketplaceListingType.sale,
            title: 'Test',
            description: 'Desc',
            price: -50,
            species: 'Budgerigar',
            gender: BirdGender.male,

            city: 'Istanbul',
          );

      verifyNever(() => mockModeration.checkText(any()));
      verifyNever(() => mockRepo.create(any()));
      final state = container.read(marketplaceFormStateProvider);
      expect(state.error, isNotNull);
    });

    test('sets error on repository failure', () async {
      when(() => mockRepo.create(any())).thenThrow(Exception('Network error'));

      await container
          .read(marketplaceFormStateProvider.notifier)
          .createListing(
            userId: 'u1',
            listingType: MarketplaceListingType.sale,
            title: 'Test',
            description: 'Desc',
            species: 'Budgerigar',
            gender: BirdGender.male,

            city: 'Istanbul',
          );

      final state = container.read(marketplaceFormStateProvider);
      expect(state.error, isNotNull);
      expect(state.isLoading, isFalse);
    });
  });

  group('updateListing', () {
    setUp(() {
      when(() => mockModeration.checkText(any()))
          .thenAnswer((_) async => const ModerationResult.allowed());
      when(() => mockRepo.updateListing(any(), any(), userId: any(named: 'userId'))).thenAnswer(
        (_) async => const MarketplaceListing(id: 'listing-1', userId: 'u1'),
      );
    });

    test('validates and moderates on update', () async {
      await container
          .read(marketplaceFormStateProvider.notifier)
          .updateListing(
            listingId: 'listing-1',
            listingType: MarketplaceListingType.sale,
            title: 'Updated',
            description: 'New desc',
            species: 'Budgerigar',
            gender: BirdGender.female,

            city: 'Ankara',
          );

      verify(() => mockModeration.checkText('Updated New desc')).called(1);
      verify(() => mockRepo.updateListing('listing-1', any(), userId: 'u1')).called(1);
      final state = container.read(marketplaceFormStateProvider);
      expect(state.isSuccess, isTrue);
    });

    test('rejects update with negative price', () async {
      await container
          .read(marketplaceFormStateProvider.notifier)
          .updateListing(
            listingId: 'listing-1',
            listingType: MarketplaceListingType.sale,
            title: 'Test',
            description: 'Desc',
            price: -10,
            species: 'Budgerigar',
            gender: BirdGender.male,

            city: 'Istanbul',
          );

      verifyNever(() => mockRepo.updateListing(any(), any(), userId: any(named: 'userId')));
      final state = container.read(marketplaceFormStateProvider);
      expect(state.error, isNotNull);
    });
  });

  test('deleteListing sets isSuccess on success', () async {
    when(() => mockRepo.delete(any(), userId: any(named: 'userId'))).thenAnswer((_) async {});

    await container
        .read(marketplaceFormStateProvider.notifier)
        .deleteListing('listing-1');

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isSuccess, isTrue);
  });

  test('reset clears state', () async {
    when(() => mockModeration.checkText(any()))
        .thenAnswer((_) async => const ModerationResult.allowed());
    when(() => mockRepo.create(any())).thenAnswer(
      (_) async => const MarketplaceListing(id: 'new', userId: 'u1'),
    );

    await container
        .read(marketplaceFormStateProvider.notifier)
        .createListing(
          userId: 'u1',
          listingType: MarketplaceListingType.sale,
          title: 'Test',
          description: 'Desc',
          species: 'Budgerigar',
          gender: BirdGender.male,

          city: 'Istanbul',
        );

    container.read(marketplaceFormStateProvider.notifier).reset();

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.isSuccess, false);
  });

  test('updateStatus sets isSuccess on success', () async {
    when(() => mockRepo.updateStatus(any(), any(), userId: any(named: 'userId'))).thenAnswer((_) async {});

    await container
        .read(marketplaceFormStateProvider.notifier)
        .updateStatus('listing-1', MarketplaceListingStatus.sold);

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isSuccess, isTrue);
  });
}
