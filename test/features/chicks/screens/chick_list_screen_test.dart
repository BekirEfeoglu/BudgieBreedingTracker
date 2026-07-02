import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/screens/chick_list_screen.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_card.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import '../../../helpers/mocks.dart';

/// Stub [AdService] that never calls Google Mobile Ads.
class _FakeAdService extends AdService {
  @override
  Future<void> loadAd() async {}

  @override
  Future<void> showInterstitialAd({required VoidCallback onAdClosed}) async {
    onAdClosed();
  }
}

Chick _createTestChick({
  required String id,
  String name = 'Baby',
  String userId = 'test-user',
  String? eggId,
}) {
  return Chick(
    id: id,
    userId: userId,
    gender: BirdGender.unknown,
    healthStatus: ChickHealthStatus.healthy,
    name: name,
    eggId: eggId,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('ChickListScreen', () {
    late GoRouter router;
    late MockNotificationScheduler mockScheduler;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockScheduler = MockNotificationScheduler();
      when(
        () => mockScheduler.cancelChickCareReminders(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockScheduler.cancelBandingReminders(any()),
      ).thenAnswer((_) async {});
      router = GoRouter(
        initialLocation: '/chicks',
        routes: [
          GoRoute(
            path: '/more',
            builder: (_, __) => const Scaffold(body: Text('More')),
          ),
          GoRoute(
            path: '/chicks',
            builder: (_, __) => const ChickListScreen(),
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
      required Stream<List<Chick>> chicksStream,
      ChickParentsInfo? fallbackParents,
      ChickRepository? chickRepository,
    }) {
      return ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          currentUserProvider.overrideWith((_) => null),
          userProfileProvider.overrideWith((_) => Stream.value(null)),
          unreadNotificationsProvider(
            'test-user',
          ).overrideWith((_) => Stream.value([])),
          chicksStreamProvider('test-user').overrideWith((_) => chicksStream),
          chickParentsByEggProvider(
            'test-user',
          ).overrideWith((_) => Stream.value({})),
          chickParentsProvider.overrideWith((_, _) async => fallbackParents),
          adServiceProvider.overrideWithValue(_FakeAdService()),
          isPremiumProvider.overrideWithValue(true),
          notificationSchedulerProvider.overrideWithValue(mockScheduler),
          if (chickRepository != null)
            chickRepositoryProvider.overrideWithValue(chickRepository),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('shows loading indicator while data is loading', (
      tester,
    ) async {
      final controller = StreamController<List<Chick>>();

      await tester.pumpWidget(createSubject(chicksStream: controller.stream));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.close();
    });

    testWidgets('shows empty state when no chicks', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('shows chick cards when data is available', (tester) async {
      final chicks = [
        _createTestChick(id: 'c1', name: 'Baby'),
        _createTestChick(id: 'c2', name: 'Tweety'),
      ];

      await tester.pumpWidget(
        createSubject(chicksStream: Stream.value(chicks)),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ChickCard), findsNWidgets(2));
    });

    testWidgets(
      'falls back to per-card parent lookup when batch map is empty',
      (tester) async {
        final chick = _createTestChick(id: 'c1', name: 'Baby', eggId: 'egg-1');

        await tester.pumpWidget(
          createSubject(
            chicksStream: Stream.value([chick]),
            fallbackParents: (
              maleName: 'Test Erkek 1',
              femaleName: 'Test Dişi 1',
              maleId: 'male-1',
              femaleId: 'female-1',
              cageNumber: '1',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('1'), findsWidgets);
        expect(find.text('Test Erkek 1'), findsOneWidget);
        expect(find.text('Test Dişi 1'), findsOneWidget);
      },
    );

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(chicksStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('has floating action button', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows search text field', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('shows sort icon button', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.arrowUpDown), findsOneWidget);
    });

    testWidgets('shows back button and navigates to more', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.arrowLeft));
      await tester.pumpAndSettle();

      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('shows chick filter bar', (tester) async {
      await tester.pumpWidget(createSubject(chicksStream: Stream.value([])));

      await tester.pumpAndSettle();

      // ChickFilterBar is always rendered in the screen column
      expect(find.byType(ChickFilterBar), findsOneWidget);
    });

    testWidgets('shows no results state when search yields nothing', (
      tester,
    ) async {
      final chick = _createTestChick(id: 'c1', name: 'Lemon');

      await tester.pumpWidget(
        createSubject(chicksStream: Stream.value([chick])),
      );
      await tester.pumpAndSettle();

      // Type a query that matches nothing. The search field debounces query
      // updates by 300ms, so advance past it before asserting.
      await tester.enterText(find.byType(TextField).first, 'ZZZNOTFOUND');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Should show no results empty state
      expect(find.byType(EmptyState), findsAtLeastNWidgets(1));
    });

    testWidgets(
      'bulk mark-as-deceased surfaces partial failure and keeps the '
      'failed chick selected instead of reporting a blanket success',
      (tester) async {
        final okChick = _createTestChick(id: 'c-ok', name: 'Ok Chick');
        final failChick = _createTestChick(id: 'c-fail', name: 'Fail Chick');
        final chickRepo = MockChickRepository();
        registerFallbackValue(okChick);
        when(() => chickRepo.getById('c-ok')).thenAnswer((_) async => okChick);
        when(() => chickRepo.getById('c-fail')).thenThrow(Exception('boom'));
        when(() => chickRepo.save(any())).thenAnswer((_) async {});

        await tester.pumpWidget(
          createSubject(
            chicksStream: Stream.value([okChick, failChick]),
            chickRepository: chickRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Long-press enters selection mode and selects the first card; a
        // plain tap on the second card selects it too while already in
        // selection mode (mirrors _SelectableChickCard/_toggleSelection).
        await tester.longPress(find.byKey(const ValueKey('c-ok')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('c-fail')));
        await tester.pumpAndSettle();
        // SliverAppBar.large renders its title in both the pinned and
        // expanded layout simultaneously, so this can legitimately match
        // more than one Text widget — assert presence, not an exact count.
        expect(
          find.text(l10n('common.selection_count')),
          findsAtLeastNWidgets(1),
        );

        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n('chicks.mark_dead')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(TextButton, l10n('common.confirm')),
        );
        await tester.pumpAndSettle();

        // ChickFormNotifier.markAsDeceased catches its own exceptions and
        // reports failure via state.error instead of throwing, so before the
        // fix _runBulkAction's try/catch never saw the 'c-fail' failure and
        // always reported chicks.bulk_action_success for both items.
        expect(
          find.text(l10n('chicks.bulk_action_partial')),
          findsOneWidget,
        );
        expect(find.text(l10n('chicks.bulk_action_success')), findsNothing);

        // The succeeded chick drops out of the selection; the failed one
        // stays selected so the user can retry it.
        // SliverAppBar.large renders its title in both the pinned and
        // expanded layout simultaneously, so this can legitimately match
        // more than one Text widget — assert presence, not an exact count.
        expect(
          find.text(l10n('common.selection_count')),
          findsAtLeastNWidgets(1),
        );
        verify(() => chickRepo.save(any())).called(1);
      },
    );
  });
}
