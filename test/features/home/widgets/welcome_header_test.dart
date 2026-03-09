import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/welcome_header.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

void main() {
  Widget createSubject({
    AsyncValue<Profile?> profileAsync = const AsyncData(null),
  }) {
    return ProviderScope(
      overrides: [
        userProfileProvider.overrideWith((_) {
          return switch (profileAsync) {
            AsyncData(:final value) => Stream.value(value),
            AsyncError(:final error) => Stream.error(error),
            _ => const Stream.empty(),
          };
        }),
      ],
      child: const MaterialApp(home: Scaffold(body: WelcomeHeader())),
    );
  }

  group('WelcomeHeader', () {
    testWidgets('renders gradient container', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasGradient = containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration &&
            decoration.gradient is LinearGradient;
      });
      expect(hasGradient, isTrue);
    });

    testWidgets('shows time-based greeting key', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Without EasyLocalization, .tr() returns the key itself
      final greetingKeys = [
        'home.greeting_morning',
        'home.greeting_afternoon',
        'home.greeting_evening',
        'home.greeting_night',
      ];
      final found = greetingKeys.any(
        (key) => find.text(key).evaluate().isNotEmpty,
      );
      expect(found, isTrue, reason: 'Should show one of the greeting keys');
    });

    testWidgets('shows generic welcome when no profile', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('home.welcome'), findsOneWidget);
    });

    testWidgets('shows welcome with name when profile exists', (tester) async {
      const profile = Profile(
        id: 'u1',
        email: 'test@example.com',
        fullName: 'Test User',
      );

      await tester.pumpWidget(
        createSubject(profileAsync: const AsyncData(profile)),
      );
      await tester.pumpAndSettle();

      // .tr(args:) returns key in test context, so check the key is present
      // The widget calls 'home.welcome_name'.tr(args: ['Test User'])
      // Without EasyLocalization, this returns 'home.welcome_name'
      expect(find.text('home.welcome_name'), findsOneWidget);
    });

    testWidgets('shows welcome on profile error', (tester) async {
      await tester.pumpWidget(
        createSubject(
          profileAsync: AsyncError(Exception('fail'), StackTrace.current),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('home.welcome'), findsOneWidget);
    });

    testWidgets('has decorative circle containers', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // The widget has 4 Positioned decorative circles
      expect(find.byType(Positioned), findsNWidgets(4));
    });
  });
}
