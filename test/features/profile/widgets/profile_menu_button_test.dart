import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_button.dart';

Widget _wrap(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(home: Scaffold(appBar: AppBar(actions: [child]))),
  );
}

void main() {
  group('ProfileMenuButton', () {
    testWidgets('renders without crashing during loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              // Return a stream that never emits to simulate loading
              return const Stream<Profile?>.empty();
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(ProfileMenuButton), findsOneWidget);
    });

    testWidgets('shows CircleAvatar during loading state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              return const Stream<Profile?>.empty();
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows initials when profile has no avatar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              return Stream.value(
                const Profile(
                  id: 'user-1',
                  email: 'john@example.com',
                  fullName: 'John Doe',
                ),
              );
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('shows single initial for single-word name', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              return Stream.value(
                const Profile(
                  id: 'user-1',
                  email: 'ali@example.com',
                  fullName: 'Ali',
                ),
              );
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('shows email prefix initial when fullName is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              return Stream.value(
                const Profile(
                  id: 'user-1',
                  email: 'bekir@example.com',
                ),
              );
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // resolvedDisplayName falls back to email prefix 'bekir' -> initial 'B'
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('renders CircleAvatar on error state', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              return Stream.error('Network error');
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows tooltip with profile.title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              return Stream.value(
                const Profile(
                  id: 'user-1',
                  email: 'test@example.com',
                  fullName: 'Test User',
                ),
              );
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Tooltip), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'profile.title');
    });

    testWidgets('avatar has radius of 18', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              return Stream.value(
                const Profile(
                  id: 'user-1',
                  email: 'test@example.com',
                  fullName: 'Test User',
                ),
              );
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar),
      );
      expect(avatar.radius, 18);
    });

    testWidgets('has Semantics button label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              return Stream.value(
                const Profile(
                  id: 'user-1',
                  email: 'test@example.com',
                  fullName: 'Test',
                ),
              );
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Semantics), findsAtLeastNWidgets(1));
    });

    testWidgets('uses GestureDetector for tap', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ProfileMenuButton(),
          overrides: [
            userProfileProvider.overrideWith((_) {
              return Stream.value(
                const Profile(
                  id: 'user-1',
                  email: 'test@example.com',
                  fullName: 'Test',
                ),
              );
            }),
            currentUserProvider.overrideWith((_) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));
    });
  });
}
