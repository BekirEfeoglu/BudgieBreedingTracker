import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/splash/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SplashScreen — loading state', () {
    testWidgets('shows animated logo while loading', (tester) async {
      // overrideWithValue(AsyncLoading) keeps the provider in loading state
      // synchronously — no Completer needed.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appInitializationProvider.overrideWithValue(
              const AsyncLoading<void>(),
            ),
          ],
          child: const MaterialApp(home: SplashScreen()),
        ),
      );
      await tester.pump();

      // In loading state, _LoadingBody is shown.
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsWidgets);
    });
  });

  group('SplashScreen — error state', () {
    // Using overrideWithValue(AsyncError) puts the provider directly in error
    // state on the very first build — no async timing / pumpAndSettle needed.
    // This avoids the issue where pumpAndSettle cannot settle while
    // _LoadingBody's AnimationController is still ticking.

    testWidgets('shows retry button and continue offline button on error', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appInitializationProvider.overrideWithValue(
              const AsyncError<void>('init failed', StackTrace.empty),
            ),
          ],
          child: const MaterialApp(home: SplashScreen()),
        ),
      );
      await tester.pump();

      // Retry button (FilledButton.icon)
      expect(find.byType(FilledButton), findsOneWidget);

      // Continue offline button (OutlinedButton)
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('tapping continue offline sets initSkippedProvider to true', (
      tester,
    ) async {
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

      // Tap "Continue offline" (OutlinedButton)
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(container.read(initSkippedProvider), isTrue);
    });

    testWidgets('shows no crash when retry button is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appInitializationProvider.overrideWithValue(
              const AsyncError<void>('fail', StackTrace.empty),
            ),
          ],
          child: const MaterialApp(home: SplashScreen()),
        ),
      );
      await tester.pump();

      // Tap retry — calls ref.invalidate(appInitializationProvider)
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      // No exception → test passes
    });
  });
}
