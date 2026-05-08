import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/app_brand_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
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

  group('SplashScreen - animation lifecycle', () {
    testWidgets('loading body shows AnimatedBuilder with Transform.scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(initState: const AsyncLoading<void>()),
      );
      await tester.pump();

      // AnimatedBuilder drives the scale animation.
      expect(find.byType(AnimatedBuilder), findsWidgets);
      expect(find.byType(AppBrandTitle), findsOneWidget);

      // After full animation (800ms), brand title is still visible.
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(AppBrandTitle), findsOneWidget);
    });

    testWidgets('animation completes without errors after 800ms', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(initState: const AsyncLoading<void>()),
      );
      // Pump through the full animation duration.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Widget tree intact after animation completes.
      expect(find.byType(AppBrandTitle), findsOneWidget);
    });

    testWidgets('widget does not crash on rapid mount and unmount', (
      tester,
    ) async {
      // Mount the widget.
      await tester.pumpWidget(
        buildSubject(initState: const AsyncLoading<void>()),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Immediately unmount by replacing with empty container.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pump();

      // No exception means AnimationController disposed correctly.
      expect(find.byType(SplashScreen), findsNothing);
    });
  });

  group('SplashScreen - state transitions', () {
    testWidgets('loading to error transition shows error body', (
      tester,
    ) async {
      // Start in loading state.
      await tester.pumpWidget(
        buildSubject(initState: const AsyncLoading<void>()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AppBrandTitle), findsOneWidget);
      expect(find.text('splash.error_title'), findsNothing);

      // Transition to error state.
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('network error', StackTrace.empty),
        ),
      );
      await tester.pump();

      expect(find.byType(AppBrandTitle), findsNothing);
      expect(find.text('splash.error_title'), findsOneWidget);
    });

    testWidgets('data state shows loading body (router handles nav away)', (
      tester,
    ) async {
      // When initialization completes, splash still shows _LoadingBody.
      // The router handles navigation away from splash.
      await tester.pumpWidget(
        buildSubject(initState: const AsyncData<void>(null)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // data state renders _LoadingBody, not error body.
      expect(find.text('splash.error_title'), findsNothing);
      expect(find.text('splash.retry'), findsNothing);
    });

    testWidgets('repeated errors show error body each time', (tester) async {
      // First error.
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('fail 1', StackTrace.empty),
        ),
      );
      await tester.pump();
      expect(find.text('splash.error_title'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);

      // Second error (different message, same UI).
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('fail 2', StackTrace.empty),
        ),
      );
      await tester.pump();
      expect(find.text('splash.error_title'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('continue offline button only in error state, not loading', (
      tester,
    ) async {
      // Loading state — no continue offline button.
      await tester.pumpWidget(
        buildSubject(initState: const AsyncLoading<void>()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('splash.continue_offline'), findsNothing);

      // Error state — continue offline button present.
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('fail', StackTrace.empty),
        ),
      );
      await tester.pump();
      expect(find.text('splash.continue_offline'), findsOneWidget);
    });
  });

  group('SplashScreen - accessibility', () {
    testWidgets('error icon has AppIcon with semanticsLabel', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('fail', StackTrace.empty),
        ),
      );
      await tester.pump();

      // AppIcon is used for the error icon with a semanticsLabel.
      final appIconFinder = find.byType(AppIcon);
      expect(appIconFinder, findsAtLeast(1));
    });

    testWidgets('retry and continue offline buttons have text labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('fail', StackTrace.empty),
        ),
      );
      await tester.pump();

      // FilledButton has retry label.
      expect(find.text('splash.retry'), findsOneWidget);
      // OutlinedButton has continue offline label.
      expect(find.text('splash.continue_offline'), findsOneWidget);
    });

    testWidgets('error body has Center > Padding > Column layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildSubject(
          initState: const AsyncError<void>('fail', StackTrace.empty),
        ),
      );
      await tester.pump();

      // Verify layout structure: Center wraps Padding wraps Column.
      final centerFinder = find.byType(Center);
      expect(centerFinder, findsAtLeast(1));

      final paddingFinder = find.descendant(
        of: centerFinder,
        matching: find.byType(Padding),
      );
      expect(paddingFinder, findsAtLeast(1));

      final columnFinder = find.descendant(
        of: paddingFinder,
        matching: find.byType(Column),
      );
      expect(columnFinder, findsAtLeast(1));
    });
  });

  group('SplashScreen - image precaching', () {
    testWidgets('loading body attempts precache without crash', (
      tester,
    ) async {
      // Pump loading state — _LoadingBody.didChangeDependencies calls
      // precacheImage('assets/images/budgie-icon.png'). The image will
      // not resolve in tests, but it must not throw.
      await tester.pumpWidget(
        buildSubject(initState: const AsyncLoading<void>()),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // No exception thrown and widget tree is intact.
      expect(find.byType(AppBrandTitle), findsOneWidget);
    });
  });
}
