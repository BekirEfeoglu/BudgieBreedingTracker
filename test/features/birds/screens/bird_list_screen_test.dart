import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/screens/bird_list_screen.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_card.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_grid_card.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('BirdListScreen', () {
    late GoRouter router;

    setUp(() {
      router = GoRouter(
        initialLocation: '/birds',
        routes: [
          GoRoute(
            path: '/birds',
            builder: (_, __) => const BirdListScreen(),
            routes: [
              GoRoute(
                path: 'form',
                builder: (_, __) => const Scaffold(body: Text('Form')),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) => Scaffold(
                  body: Text('Detail: ${state.pathParameters['id']}'),
                ),
              ),
            ],
          ),
        ],
      );
    });

    Widget createSubject({
      required Stream<List<Bird>> birdsStream,
      AdService? adService,
      bool isPremium = false,
    }) {
      return ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          currentUserProvider.overrideWith((_) => null),
          userProfileProvider.overrideWith((_) => Stream.value(null)),
          unreadNotificationsProvider(
            'test-user',
          ).overrideWith((_) => Stream.value([])),
          birdsStreamProvider('test-user').overrideWith((_) => birdsStream),
          adServiceProvider.overrideWithValue(adService ?? MockAdService()),
          isPremiumProvider.overrideWithValue(isPremium),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      // Use a StreamController to control when data arrives
      final controller = StreamController<List<Bird>>();
      addTearDown(controller.close);

      await tester.pumpWidget(createSubject(birdsStream: controller.stream));

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when no birds', (tester) async {
      await tester.pumpWidget(createSubject(birdsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows bird cards when data is available', (tester) async {
      final birds = [
        createTestBird(id: 'b1', name: 'Mavi', gender: BirdGender.male),
        createTestBird(id: 'b2', name: 'Sari', gender: BirdGender.female),
      ];

      await tester.pumpWidget(createSubject(birdsStream: Stream.value(birds)));

      await tester.pumpAndSettle();

      expect(find.byType(BirdCard), findsNWidgets(2));
      expect(find.text('Mavi'), findsAtLeastNWidgets(1));
      expect(find.text('Sari'), findsAtLeastNWidgets(1));
    });

    testWidgets('switches between list and photo grid view', (tester) async {
      final birds = [
        createTestBird(id: 'b1', name: 'Mavi', gender: BirdGender.male),
        createTestBird(id: 'b2', name: 'Sari', gender: BirdGender.female),
      ];

      await tester.pumpWidget(createSubject(birdsStream: Stream.value(birds)));
      await tester.pumpAndSettle();

      // The screen uses CustomScrollView slivers: SliverList in list mode,
      // SliverGrid in grid mode.
      expect(find.byType(SliverList), findsWidgets);
      expect(find.byType(SliverGrid), findsNothing);

      await tester.tap(find.byTooltip(l10n('birds.grid_view')));
      await tester.pumpAndSettle();

      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.text('Mavi'), findsAtLeastNWidgets(1));
      expect(find.text('Sari'), findsAtLeastNWidgets(1));

      await tester.tap(find.byTooltip(l10n('birds.list_view')));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets(
      'list-mode selection checkbox meets the 48dp touch target minimum',
      (tester) async {
        final birds = [
          createTestBird(id: 'b1', name: 'Mavi', gender: BirdGender.male),
        ];

        await tester.pumpWidget(
          createSubject(birdsStream: Stream.value(birds)),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(BirdCard).first);
        await tester.pumpAndSettle();

        expect(find.byType(Checkbox), findsOneWidget);
        final size = tester.getSize(find.byType(Checkbox));
        expect(
          size.width,
          greaterThanOrEqualTo(48),
          reason: 'checkbox width must meet WCAG 2.5.5 / accessibility.md',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(48),
          reason: 'checkbox height must meet WCAG 2.5.5 / accessibility.md',
        );
      },
    );

    testWidgets(
      'grid-mode selection checkbox meets the 48dp touch target minimum',
      (tester) async {
        final birds = [
          createTestBird(id: 'b1', name: 'Mavi', gender: BirdGender.male),
        ];

        await tester.pumpWidget(
          createSubject(birdsStream: Stream.value(birds)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip(l10n('birds.grid_view')));
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(BirdGridCard).first);
        await tester.pumpAndSettle();

        expect(find.byType(Checkbox), findsOneWidget);
        final size = tester.getSize(find.byType(Checkbox));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      },
    );

    testWidgets(
      'bulk-selection overflow menu has a localized tooltip',
      (tester) async {
        final birds = [
          createTestBird(id: 'b1', name: 'Mavi', gender: BirdGender.male),
        ];

        await tester.pumpWidget(
          createSubject(birdsStream: Stream.value(birds)),
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.byType(BirdCard).first);
        await tester.pumpAndSettle();

        expect(find.byTooltip(l10n('common.more')), findsOneWidget);
      },
    );

    testWidgets(
      'rapid double-tap on a bird card only requests one interstitial ad',
      (tester) async {
        final birds = [
          createTestBird(id: 'b1', name: 'Mavi', gender: BirdGender.male),
        ];
        final adService = MockAdService();
        when(
          () => adService.showInterstitialAd(
            onAdClosed: any(named: 'onAdClosed'),
          ),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(
          createSubject(
            birdsStream: Stream.value(birds),
            adService: adService,
          ),
        );
        await tester.pumpAndSettle();

        // Two taps fired back-to-back before either has a chance to
        // complete, simulating a fast double-tap.
        await tester.tap(find.byType(BirdCard).first);
        await tester.tap(find.byType(BirdCard).first);
        await tester.pumpAndSettle();

        verify(
          () => adService.showInterstitialAd(
            onAdClosed: any(named: 'onAdClosed'),
          ),
        ).called(1);
      },
    );

    testWidgets('opens cage ledger from app bar action', (tester) async {
      final birds = [
        createTestBird(id: 'b1', name: 'Mavi', cageNumber: 'K1'),
        createTestBird(id: 'b2', name: 'Sari', cageNumber: 'K1'),
      ];

      await tester.pumpWidget(createSubject(birdsStream: Stream.value(birds)));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(l10n('birds.cage_ledger')));
      await tester.pumpAndSettle();

      expect(find.text(l10n('birds.cage_ledger')), findsOneWidget);
      expect(find.text('K1'), findsOneWidget);
      expect(find.text('Mavi'), findsAtLeastNWidgets(1));
      expect(find.text('Sari'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(birdsStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('has floating action button', (tester) async {
      await tester.pumpWidget(createSubject(birdsStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
