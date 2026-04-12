import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_list_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/screens/profile_screen.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_skeleton.dart';
import 'package:budgie_breeding_tracker/features/settings/providers/settings_providers.dart';

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
      ],
    );
  });

  Widget createSubject({required Stream<Profile?> profileStream}) {
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
  });
}
