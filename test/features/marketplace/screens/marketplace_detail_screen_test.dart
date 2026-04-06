@Tags(['community'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_form_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/screens/marketplace_detail_screen.dart';
import 'package:budgie_breeding_tracker/features/messaging/providers/messaging_form_providers.dart';

import '../../../helpers/test_localization.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

const _testUserId = 'test-user';
const _testListingId = 'listing-1';
const _testParams = (id: _testListingId, userId: _testUserId);

const _sampleListing = MarketplaceListing(
  id: _testListingId,
  userId: 'other-user',
  title: 'Beautiful Budgie',
  description: 'A lovely blue budgie for sale',
  species: 'Budgerigar',
  city: 'Istanbul',
  price: 500,
  gender: BirdGender.male,
  listingType: MarketplaceListingType.sale,
);

const _ownListing = MarketplaceListing(
  id: _testListingId,
  userId: _testUserId,
  title: 'My Budgie',
  description: 'My own listing',
  species: 'Budgerigar',
  city: 'Ankara',
  gender: BirdGender.female,
);

void main() {
  late MockMarketplaceRepository mockRepo;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
  });

  Widget buildSubject({
    required AsyncValue<MarketplaceListing?> listingAsync,
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(_testUserId),
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        marketplaceListingByIdProvider(_testParams).overrideWith(
          (_) => switch (listingAsync) {
            AsyncData(:final value) => Future.value(value),
            AsyncError(:final error) => Future.error(error),
            _ => Completer<MarketplaceListing?>().future,
          },
        ),
        marketplaceFormStateProvider
            .overrideWith(() => MarketplaceFormNotifier()),
        messagingFormStateProvider
            .overrideWith(() => MessagingFormNotifier()),
      ],
      child: const MaterialApp(
        home: MarketplaceDetailScreen(listingId: _testListingId),
      ),
    );
  }

  group('MarketplaceDetailScreen', () {
    testWidgets('loading state shows CircularProgressIndicator',
        (tester) async {
      final completer = Completer<MarketplaceListing?>();

      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [
            currentUserIdProvider.overrideWithValue(_testUserId),
            marketplaceRepositoryProvider.overrideWithValue(mockRepo),
            marketplaceListingByIdProvider(_testParams).overrideWith(
              (_) => completer.future,
            ),
            marketplaceFormStateProvider
                .overrideWith(() => MarketplaceFormNotifier()),
            messagingFormStateProvider
                .overrideWith(() => MessagingFormNotifier()),
          ],
          child: const MaterialApp(
            home: MarketplaceDetailScreen(listingId: _testListingId),
          ),
        ),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(null);
    });

    testWidgets('error state shows ErrorState widget', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          listingAsync: AsyncError(Exception('Network error'), StackTrace.empty),
        ),
      );

      expect(find.byType(app.ErrorState), findsOneWidget);
    });

    testWidgets('null listing shows not found ErrorState', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingAsync: const AsyncData(null)),
      );

      expect(find.byType(app.ErrorState), findsOneWidget);
    });

    testWidgets('data state shows listing details', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingAsync: const AsyncData(_sampleListing)),
      );

      expect(find.text('Beautiful Budgie'), findsOneWidget);
      expect(find.text('500 TRY'), findsOneWidget);
      expect(find.text('A lovely blue budgie for sale'), findsOneWidget);
      expect(find.text('Budgerigar'), findsOneWidget);
      expect(find.text('Istanbul'), findsOneWidget);
    });

    testWidgets('non-owner sees message seller button', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingAsync: const AsyncData(_sampleListing)),
      );

      // Should find the message seller button (key text)
      expect(find.text('marketplace.message_seller'), findsOneWidget);
      // Should NOT find edit/delete buttons
      expect(find.text('marketplace.edit_listing'), findsNothing);
    });

    testWidgets('owner sees edit and delete buttons', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(listingAsync: const AsyncData(_ownListing)),
      );

      expect(find.text('marketplace.edit_listing'), findsOneWidget);
      expect(find.text('common.delete'), findsOneWidget);
      // Should NOT find message seller button
      expect(find.text('marketplace.message_seller'), findsNothing);
    });
  });
}
