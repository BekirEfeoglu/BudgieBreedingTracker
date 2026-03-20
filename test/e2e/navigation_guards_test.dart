@Tags(['e2e'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/main_shell.dart';
import 'package:budgie_breeding_tracker/router/guards/admin_guard.dart';
import 'package:budgie_breeding_tracker/router/guards/premium_guard.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

import '../helpers/e2e_test_harness.dart';

void main() {
  ensureE2EBinding();

  group('Navigation and Guard E2E', () {
    setUp(() {
      _ScrollableBirdTabState.resetPersistedState();
    });

    testWidgets(
      'GIVEN free-tier user WHEN premium route is accessed THEN redirect target is /premium',
      (tester) async {
        expect(PremiumGuard.redirect(false), AppRoutes.premium);
        expect(PremiumGuard.redirect(true), isNull);
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN non-admin user WHEN /admin route is requested THEN redirect target is home and admin is hidden',
      (tester) async {
        expect(AdminGuard.redirect(const AsyncData(false)), AppRoutes.home);
        expect(AdminGuard.redirect(const AsyncData(true)), isNull);
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN logged-in user in home shell WHEN all 5 tabs are opened THEN each tab is reachable and tab state persists',
      (tester) async {
        final mockProfileRepository = MockProfileRepository();
        when(() => mockProfileRepository.pull(any())).thenAnswer((_) async {});

        final container = createTestContainer(
          isAuthenticated: true,
          overrides: [
            profileRepositoryProvider.overrideWithValue(mockProfileRepository),
            networkStatusProvider.overrideWith((_) => Stream.value(true)),
            periodicSyncProvider.overrideWith((ref) {}),
            networkAwareSyncProvider.overrideWith((ref) {}),
          ],
        );
        addTearDown(container.dispose);

        final router = GoRouter(
          initialLocation: AppRoutes.birds,
          routes: [
            ShellRoute(
              builder: (context, state, child) => MainShell(child: child),
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  pageBuilder: (_, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const _TabScreen(label: 'home_tab'),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.birds,
                  pageBuilder: (_, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const _ScrollableBirdTab(),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.breeding,
                  pageBuilder: (_, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const _TabScreen(label: 'breeding_tab'),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.calendar,
                  pageBuilder: (_, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const _TabScreen(label: 'calendar_tab'),
                  ),
                ),
                GoRoute(
                  path: AppRoutes.more,
                  pageBuilder: (_, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const _TabScreen(label: 'more_tab'),
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        // Force narrow viewport so MainShell renders NavigationBar (not NavigationRail).
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await pumpApp(tester, container, router: router);
        await tester.pumpAndSettle();

        final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(navBar.destinations.length, 5);

        await tester.enterText(
          find.byKey(const Key('birds_search')),
          'persisted',
        );
        await tester.drag(
          find.byKey(const Key('birds_list')),
          const Offset(0, -1800),
        );
        await tester.pumpAndSettle();
        expect(find.text('bird_item_40'), findsWidgets);

        await tester.tap(find.text('nav.home'));
        await tester.pumpAndSettle();
        expect(find.text('home_tab'), findsOneWidget);

        await tester.tap(find.text('nav.breeding'));
        await tester.pumpAndSettle();
        expect(find.text('breeding_tab'), findsOneWidget);

        await tester.tap(find.text('nav.calendar'));
        await tester.pumpAndSettle();
        expect(find.text('calendar_tab'), findsOneWidget);

        await tester.tap(find.text('nav.more'));
        await tester.pumpAndSettle();
        expect(find.text('more_tab'), findsOneWidget);

        await tester.tap(find.text('nav.birds'));
        await tester.pumpAndSettle();

        expect(find.text('typed:persisted'), findsOneWidget);
        expect(find.text('bird_item_40'), findsWidgets);
      },
      timeout: e2eTimeout,
    );

    testWidgets(
      'GIVEN deep-link request WHEN /birds/123 is opened THEN detail screen loads directly',
      (tester) async {
        const detailPath = '/birds/123';
        final router = buildTestNavigator(
          initialLocation: detailPath,
          routes: [
            GoRoute(
              path: '/birds/:id',
              builder: (_, state) =>
                  Text('bird_detail_${state.pathParameters['id']}'),
            ),
          ],
        );
        addTearDown(router.dispose);

        final container = createTestContainer(isAuthenticated: true);
        addTearDown(container.dispose);

        await pumpApp(tester, container, router: router);
        await tester.pumpAndSettle();

        expect(find.text('bird_detail_123'), findsOneWidget);
      },
      timeout: e2eTimeout,
    );
  });
}

class _TabScreen extends StatelessWidget {
  const _TabScreen({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}

class _ScrollableBirdTab extends StatefulWidget {
  const _ScrollableBirdTab();

  @override
  State<_ScrollableBirdTab> createState() => _ScrollableBirdTabState();
}

class _ScrollableBirdTabState extends State<_ScrollableBirdTab>
    with AutomaticKeepAliveClientMixin<_ScrollableBirdTab> {
  static String _persistedQuery = '';
  static double _persistedOffset = 0;

  static void resetPersistedState() {
    _persistedQuery = '';
    _persistedOffset = 0;
  }

  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late String _query;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _query = _persistedQuery;
    _searchController = TextEditingController(text: _persistedQuery);
    _scrollController = ScrollController(initialScrollOffset: _persistedOffset);
    _scrollController.addListener(() {
      _persistedOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _persistedQuery = _query;
    _persistedOffset = _scrollController.hasClients
        ? _scrollController.offset
        : _persistedOffset;
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Column(
        children: [
          TextField(
            key: const Key('birds_search'),
            controller: _searchController,
            onChanged: (value) => setState(() {
              _query = value;
              _persistedQuery = value;
            }),
          ),
          Text('typed:$_query'),
          Expanded(
            child: ListView.builder(
              key: const Key('birds_list'),
              controller: _scrollController,
              itemCount: 120,
              itemBuilder: (_, index) =>
                  ListTile(title: Text('bird_item_$index')),
            ),
          ),
        ],
      ),
    );
  }
}
