import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/marketplace_enums.dart';
import 'package:budgie_breeding_tracker/data/models/marketplace_listing_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_form_providers.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

void main() {
  late MockMarketplaceRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
    container = ProviderContainer(overrides: [
      marketplaceRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  });

  tearDown(() => container.dispose());

  test('initial state is correct', () {
    final state = container.read(marketplaceFormStateProvider);
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.isSuccess, false);
  });

  test('createListing sets isSuccess on success', () async {
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
          price: 100,
          species: 'Budgerigar',
          gender: BirdGender.male,
          imageUrls: [],
          city: 'Istanbul',
        );

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isSuccess, isTrue);
    expect(state.isLoading, isFalse);
  });

  test('createListing sets error on failure', () async {
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
          imageUrls: [],
          city: 'Istanbul',
        );

    final state = container.read(marketplaceFormStateProvider);
    expect(state.error, isNotNull);
    expect(state.isLoading, isFalse);
  });

  test('deleteListing sets isSuccess on success', () async {
    when(() => mockRepo.delete(any())).thenAnswer((_) async {});

    await container
        .read(marketplaceFormStateProvider.notifier)
        .deleteListing('listing-1');

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isSuccess, isTrue);
  });

  test('reset clears state', () async {
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
          imageUrls: [],
          city: 'Istanbul',
        );

    container.read(marketplaceFormStateProvider.notifier).reset();

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isLoading, false);
    expect(state.error, isNull);
    expect(state.isSuccess, false);
  });

  test('updateStatus sets isSuccess on success', () async {
    when(() => mockRepo.updateStatus(any(), any())).thenAnswer((_) async {});

    await container
        .read(marketplaceFormStateProvider.notifier)
        .updateStatus('listing-1', MarketplaceListingStatus.sold);

    final state = container.read(marketplaceFormStateProvider);
    expect(state.isSuccess, isTrue);
  });
}
