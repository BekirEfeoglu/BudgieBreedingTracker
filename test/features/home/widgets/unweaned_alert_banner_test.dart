import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/features/home/widgets/unweaned_alert_banner.dart';

import '../../../helpers/test_localization.dart';

void main() {
  Widget createSubject(int count, {double textScale = 1}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, __) => NoTransitionPage(
            child: Scaffold(body: UnweanedAlertBanner(count: count)),
          ),
        ),
        GoRoute(
          path: '/chicks',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: Scaffold(body: Text('Chicks'))),
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    );
  }

  Widget createTranslatedSubject(int count, Locale locale) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (_, __) => NoTransitionPage(
            child: Scaffold(body: UnweanedAlertBanner(count: count)),
          ),
        ),
        GoRoute(
          path: '/chicks',
          pageBuilder: (_, __) =>
              const NoTransitionPage(child: Scaffold(body: Text('Chicks'))),
        ),
      ],
    );

    return EasyLocalization(
      supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      assetLoader: const RealTestAssetLoader(),
      fallbackLocale: const Locale('tr'),
      startLocale: locale,
      child: Builder(
        builder: (context) => MaterialApp.router(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          routerConfig: router,
        ),
      ),
    );
  }

  group('UnweanedAlertBanner', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(createSubject(3));
      await tester.pump();

      expect(find.byType(UnweanedAlertBanner), findsOneWidget);
    });

    testWidgets('shows nothing (SizedBox.shrink) when count is 0', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(0));
      await tester.pump();

      // count=0 returns SizedBox.shrink — no alert text visible
      expect(find.text(l10n('home.unweaned_alert')), findsNothing);
      expect(find.text(l10n('home.view_unweaned')), findsNothing);
    });

    testWidgets('shows banner container when count > 0', (tester) async {
      await tester.pumpWidget(createSubject(3));
      await tester.pump();

      expect(find.byType(Container), findsAtLeastNWidgets(1));
    });

    testWidgets('shows unweaned_alert text when count > 0', (tester) async {
      await tester.pumpWidget(createSubject(5));
      await tester.pump();

      expect(find.text(l10n('home.unweaned_alert')), findsOneWidget);
    });

    testWidgets('shows view button when count > 0', (tester) async {
      await tester.pumpWidget(createSubject(2));
      await tester.pump();

      expect(find.text(l10n('home.view_unweaned')), findsOneWidget);
    });

    testWidgets('tapping view navigates to chicks screen', (tester) async {
      await tester.pumpWidget(createSubject(2));
      await tester.pump();

      await tester.tap(find.text(l10n('home.view_unweaned')));
      await tester.pumpAndSettle();

      expect(find.text('Chicks'), findsOneWidget);
    });

    testWidgets('shows single chick banner for count=1', (tester) async {
      await tester.pumpWidget(createSubject(1));
      await tester.pump();

      expect(find.text(l10n('home.unweaned_alert')), findsOneWidget);
    });

    testWidgets('does not overflow at accessibility text size', (tester) async {
      await tester.pumpWidget(createSubject(1, textScale: 3.5));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(l10n('home.view_unweaned')), findsOneWidget);
    });

    for (final locale in const ['tr', 'en', 'de']) {
      testWidgets(
        'does not overflow with translated copy on narrow $locale layout',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(280, 640));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await EasyLocalization.ensureInitialized();

          await tester.pumpWidget(createTranslatedSubject(5, Locale(locale)));
          await tester.pump(const Duration(milliseconds: 200));

          expect(tester.takeException(), isNull);
          expect(
            find.text(resolvedL10n('home.view_unweaned', locale: locale)),
            findsOneWidget,
          );
        },
      );
    }
  });
}
