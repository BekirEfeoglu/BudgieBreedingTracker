@Tags(['community'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/primary_button.dart';
import 'package:budgie_breeding_tracker/data/repositories/marketplace_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/providers/marketplace_form_providers.dart';
import 'package:budgie_breeding_tracker/features/marketplace/screens/marketplace_form_screen.dart';

import '../../../helpers/test_localization.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {}

const _testUserId = 'test-user';

void main() {
  late MockMarketplaceRepository mockRepo;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
  });

  Widget buildSubject({
    String? editListingId,
    MarketplaceFormState formState = const MarketplaceFormState(),
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(_testUserId),
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        marketplaceFormStateProvider
            .overrideWith(() => MarketplaceFormNotifier()),
      ],
      child: MaterialApp(
        home: MarketplaceFormScreen(editListingId: editListingId),
      ),
    );
  }

  group('MarketplaceFormScreen', () {
    testWidgets('renders new listing form title when no editId',
        (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      // AppBar title should show "new listing" key
      expect(find.text('marketplace.new_listing'), findsOneWidget);
    });

    testWidgets('renders edit listing form title when editId provided',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(editListingId: 'edit-1'),
      );

      expect(find.text('marketplace.edit_listing'), findsOneWidget);
    });

    testWidgets('renders all form fields', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      // Check key form field labels are present
      expect(find.text('marketplace.listing_type_label'), findsOneWidget);
      expect(find.text('marketplace.title_label'), findsOneWidget);
      expect(find.text('marketplace.description_label'), findsOneWidget);
      expect(find.text('marketplace.species_label'), findsOneWidget);
      expect(find.text('marketplace.mutation_label'), findsOneWidget);
      expect(find.text('marketplace.gender_label'), findsOneWidget);
      expect(find.text('marketplace.age_label'), findsOneWidget);
      expect(find.text('marketplace.city_label'), findsOneWidget);
    });

    testWidgets('shows price field when listing type is sale',
        (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      // Default listing type is sale, so price field should be visible
      expect(find.text('marketplace.price_label'), findsOneWidget);
    });

    testWidgets('renders PrimaryButton with save label', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text('common.save'), findsOneWidget);
    });

    testWidgets('renders PrimaryButton with update label in edit mode',
        (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(editListingId: 'edit-1'),
      );

      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text('common.update'), findsOneWidget);
    });

    testWidgets('validates required title field on submit', (tester) async {
      // Use a tall surface to fit all form fields
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLocalizedApp(tester, buildSubject());

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('marketplace.title_required'), findsOneWidget);
    });

    testWidgets('validates required description field on submit',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLocalizedApp(tester, buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'marketplace.title_label'),
        'Test Title',
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('marketplace.description_required'), findsOneWidget);
    });

    testWidgets('validates required species field on submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLocalizedApp(tester, buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'marketplace.title_label'),
        'Test Title',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'marketplace.description_label'),
        'Test Description',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'marketplace.price_label'),
        '100',
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('marketplace.species_required'), findsOneWidget);
    });

    testWidgets('validates required city field on submit', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpLocalizedApp(tester, buildSubject());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'marketplace.title_label'),
        'Test Title',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'marketplace.description_label'),
        'Test Description',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'marketplace.price_label'),
        '100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'marketplace.species_label'),
        'Budgerigar',
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(find.text('marketplace.city_required'), findsOneWidget);
    });
  });
}
