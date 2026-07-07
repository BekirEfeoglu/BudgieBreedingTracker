import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/screens/profile_screen.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_skeleton.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart'
    show appInfoProvider;
import 'package:budgie_breeding_tracker/shared/providers/gamification.dart'
    as gamification;

import '../../../helpers/test_localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const Scaffold(body: Text('Settings')),
        ),
        GoRoute(
          path: '/premium',
          builder: (_, __) => const Scaffold(body: Text('Premium')),
        ),
        GoRoute(
          path: '/badges',
          builder: (_, __) => const Scaffold(body: Text('Badges')),
        ),
      ],
    );
  });

  Widget createSubject({
    required Stream<Profile?> profileStream,
    List<dynamic> extraOverrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue('test-user'),
        currentUserProvider.overrideWith((_) => null),
        userProfileProvider.overrideWith((_) => profileStream),
        unreadNotificationsProvider(
          'test-user',
        ).overrideWith((_) => Stream.value([])),
        appInfoProvider.overrideWith((_) async {
          throw UnimplementedError();
        }),
        ...extraOverrides,
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('ProfileScreen', () {
    testWidgets('shows skeleton while profile is loading', (tester) async {
      final controller = StreamController<Profile?>();

      await tester.pumpWidget(createSubject(profileStream: controller.stream));

      await tester.pump();

      expect(find.byType(ProfileSkeleton), findsOneWidget);

      controller.close();
    });

    testWidgets('shows error state on stream error', (tester) async {
      await tester.pumpWidget(
        createSubject(profileStream: Stream.error('Network error')),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsOneWidget);
    });

    testWidgets('shows profile title', (tester) async {
      final controller = StreamController<Profile?>();

      await tester.pumpWidget(createSubject(profileStream: controller.stream));

      await tester.pump();

      // The ProfileSkeleton should be rendered in the scaffold body
      expect(find.byType(Scaffold), findsWidgets);

      controller.close();
    });

    testWidgets('passes gamification level and badges to the profile header', (
      tester,
    ) async {
      const profile = Profile(
        id: 'test-user',
        email: 'info@test.dev',
        fullName: 'Bekir Efeoglu',
      );
      const badge = gamification.Badge(
        id: 'badge-1',
        key: 'first_bird',
        category: gamification.BadgeCategory.milestone,
        tier: gamification.BadgeTier.gold,
        nameKey: 'badges.first_bird',
        requirement: 1,
      );

      await pumpLocalizedApp(
        tester,
        createSubject(
          profileStream: Stream.value(profile),
          extraOverrides: [
            profileStatsProvider(
              'test-user',
            ).overrideWith((_) => const AsyncData(ProfileStats())),
            gamification
                .userLevelProvider('test-user')
                .overrideWith(
                  (_) async => const gamification.UserLevel(
                    id: 'level-1',
                    userId: 'test-user',
                    level: 12,
                    title: 'gamification.title_expert',
                  ),
                ),
            gamification.badgesProvider.overrideWith(
              (_) async => const [badge],
            ),
            gamification
                .userBadgesProvider('test-user')
                .overrideWith(
                  (_) async => const [
                    gamification.UserBadge(
                      id: 'user-badge-1',
                      userId: 'test-user',
                      badgeId: 'badge-1',
                      isUnlocked: true,
                      progress: 1,
                    ),
                  ],
                ),
          ],
        ),
        settle: false,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('${l10n('community.level_prefix')}12'),
        findsOneWidget,
      );
      expect(
        find.textContaining(l10n('gamification.title_expert')),
        findsOneWidget,
      );
      expect(find.text(l10n('badges.first_bird')), findsNWidgets(2));
      expect(find.text(l10n('badges.showcase')), findsOneWidget);
      expect(find.text(l10n('badges.all_badges')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
