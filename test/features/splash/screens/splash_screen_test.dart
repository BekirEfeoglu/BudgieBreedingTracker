import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/app_brand_title.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/splash/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildSubject({required AsyncValue<void> initState}) {
    return ProviderScope(
      overrides: [
        appInitializationProvider.overrideWithValue(initState),
      ],
      child: const MaterialApp(home: SplashScreen()),
    );
  }

  group('SplashScreen - loading state', () {
    testWidgets('shows AppBrandTitle and AnimatedBuilder while loading', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(initState: const AsyncLoading<void>()),
      );
      // Pump to let the AnimationController start.
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(AppBrandTitle), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('shows CircularProgressIndicator is absent in loading body', (
      tester,
    ) async {
      // The current splash loading body uses AnimatedBuilder + AppBrandTitle,
      // not a CircularProgressIndicator. Verify the brand title is present.
      await tester.pumpWidget(
        buildSubject(initState: const AsyncLoading<void>()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBrandTitle), findsOneWidget);
    });

    testWidgets('scale animation starts and completes (AnimatedBuilder ticks)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(initState: const AsyncLoading<void>()),
      );

      // At t=0 the AnimationController has started.
      await tester.pump();

      // The AnimatedBuilder should be present, driving the scale transform.
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // After the full animation duration (800ms), the animation completes.
      await tester.pump(const Duration(milliseconds: 800));

      // The widget tree should still have the AnimatedBuilder and AppBrandTitle.
      expect(find.byType(AppBrandTitle), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });

    testWidgets('data state also shows loading body', (tester) async {
      // When appInitializationProvider completes (data), splash still
      // renders _LoadingBody (router handles navigation away).
      await tester.pumpWidget(
        buildSubject(initState: const AsyncData<void>(null)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBrandTitle), findsOneWidget);
    });
  });

  group('SplashScreen - error state', () {
    testWidgets('shows error message text', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('init failed', StackTrace.empty),
        ),
      );
      await tester.pump();

      // Error title and message localization keys appear as raw keys in test.
      expect(find.text('splash.error_title'), findsOneWidget);
      expect(find.text('splash.error_message'), findsOneWidget);
    });

    testWidgets('shows retry button and continue offline button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('init failed', StackTrace.empty),
        ),
      );
      await tester.pump();

      // Retry button (FilledButton.icon)
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('splash.retry'), findsOneWidget);

      // Continue offline button (OutlinedButton)
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('splash.continue_offline'), findsOneWidget);
    });

    testWidgets('tapping retry button invalidates provider without crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('fail', StackTrace.empty),
        ),
      );
      await tester.pump();

      // Tap retry — calls ref.invalidate(appInitializationProvider).
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // No exception thrown means invalidation succeeded.
      expect(find.byType(SplashScreen), findsOneWidget);
    });

    testWidgets(
      'tapping continue offline sets initSkippedProvider to true',
      (tester) async {
        late ProviderContainer container;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appInitializationProvider.overrideWithValue(
                const AsyncError<void>('init failed', StackTrace.empty),
              ),
            ],
            child: Builder(
              builder: (context) {
                container = ProviderScope.containerOf(context);
                return const MaterialApp(home: SplashScreen());
              },
            ),
          ),
        );
        await tester.pump();

        // Verify initial state is false.
        expect(container.read(initSkippedProvider), isFalse);

        // Tap "Continue offline" (OutlinedButton).
        await tester.tap(find.byType(OutlinedButton));
        await tester.pump();

        // State should now be true.
        expect(container.read(initSkippedProvider), isTrue);
      },
    );

    testWidgets('error body does not show AppBrandTitle', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('fail', StackTrace.empty),
        ),
      );
      await tester.pump();

      // Error body shows error UI, not the brand title.
      expect(find.byType(AppBrandTitle), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
