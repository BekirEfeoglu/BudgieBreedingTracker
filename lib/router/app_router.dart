import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/providers/auth_providers.dart';
import '../features/admin/providers/admin_providers.dart';
import '../features/home/widgets/main_shell.dart';
import 'guards/admin_guard.dart';
import 'guards/premium_guard.dart';
import '../domain/services/ads/ad_reward_providers.dart';
import '../features/premium/providers/premium_providers.dart';
import '../features/home/screens/home_screen.dart';
import '../features/birds/screens/bird_list_screen.dart';
import '../features/birds/screens/bird_detail_screen.dart';
import '../features/birds/screens/bird_form_screen.dart';
import '../features/breeding/screens/breeding_list_screen.dart';
import '../features/breeding/screens/breeding_detail_screen.dart';
import '../features/breeding/screens/breeding_form_screen.dart';
import '../features/eggs/screens/egg_management_screen.dart';
import '../features/chicks/screens/chick_list_screen.dart';
import '../features/chicks/screens/chick_detail_screen.dart';
import '../features/chicks/screens/chick_form_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/more/screens/more_screen.dart';
import '../features/auth/providers/two_factor_providers.dart';
import '../features/splash/screens/splash_screen.dart';
import '../core/widgets/not_found_screen.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'route_names.dart';
import 'route_utils.dart';
import 'router_notifier.dart';
import 'routes/admin_routes.dart';
import 'routes/auth_routes.dart';
import '../core/constants/feature_flags.dart';
import 'routes/community_routes.dart';
import 'routes/gamification_routes.dart';
import 'routes/marketplace_routes.dart';
import 'routes/messaging_routes.dart';
import 'routes/user_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);
  String? lastConsumedGeneticsRewardLocation;
  const debugStartRoute = String.fromEnvironment('DEBUG_START_ROUTE');
  final normalizedDebugStartRoute = debugStartRoute.trim();
  const enableGeneticsColorAudit = bool.fromEnvironment('GENETICS_COLOR_AUDIT');
  final hasDebugStartRoute = normalizedDebugStartRoute.isNotEmpty;
  final initialLocation = kDebugMode && hasDebugStartRoute
      ? normalizedDebugStartRoute
      : (kDebugMode && enableGeneticsColorAudit
            ? AppRoutes.geneticsColorAudit
            : AppRoutes.home);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    overridePlatformDefaultLocation:
        kDebugMode && (hasDebugStartRoute || enableGeneticsColorAudit),
    refreshListenable: notifier,
    observers: [SentryNavigatorObserver()],
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = ref.read(isAuthenticatedProvider);
      final isAdminAsync = ref.read(isAdminProvider);
      final isPremium = ref.read(effectivePremiumProvider);
      final appInit = ref.read(appInitializationProvider);
      final initSkipped = ref.read(initSkippedProvider);
      final isAppReady = appInit.hasValue || initSkipped;

      final location = state.matchedLocation;

      final isAuthRoute =
          location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.authCallback ||
          location == AppRoutes.oauthCallback ||
          location == AppRoutes.emailVerification ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.twoFactorVerify;
      final isSplashRoute = location == AppRoutes.splash;

      // Auth guard
      if (!isLoggedIn && !isAuthRoute && !_isAnonymousAllowedRoute(location)) {
        return AppRoutes.login;
      }
      if (isLoggedIn && isAuthRoute && location != AppRoutes.twoFactorVerify) {
        return AppRoutes.home;
      }

      // 2FA guard: redirect to verify screen if MFA verification is pending
      final pendingFactorId = ref.read(pendingMfaFactorIdProvider);
      if (isLoggedIn &&
          pendingFactorId != null &&
          location != AppRoutes.twoFactorVerify) {
        return '${AppRoutes.twoFactorVerify}?factorId=$pendingFactorId';
      }

      // Initialization guard: show splash while profile syncs from Supabase
      final isInitError = appInit.hasError && !initSkipped;
      if (isLoggedIn && !isAppReady && !isSplashRoute) return AppRoutes.splash;
      if (isSplashRoute && isAppReady && !isInitError) {
        if (kDebugMode && hasDebugStartRoute) return normalizedDebugStartRoute;
        return AppRoutes.home;
      }

      final isGeneticsRoute =
          location == AppRoutes.genetics ||
          location == AppRoutes.geneticsHistory ||
          location == AppRoutes.geneticsReverse ||
          location == AppRoutes.geneticsCompare;
      if (!isGeneticsRoute) {
        // Reset route-level consume guard after leaving genetics routes.
        lastConsumedGeneticsRewardLocation = null;
      }

      // Premium guard: restrict premium routes (with reward exemptions)
      if (location == AppRoutes.statistics) {
        final statsReward = ref.read(isStatisticsRewardActiveProvider);
        if (!isPremium && !statsReward) return AppRoutes.premium;
      } else if (isGeneticsRoute) {
        final geneticsReward = ref.read(isGeneticsRewardActiveProvider);
        if (!isPremium && !geneticsReward) return AppRoutes.premium;
        if (!isPremium &&
            geneticsReward &&
            lastConsumedGeneticsRewardLocation != location) {
          // Consume one rewarded-access use per genetics route entry.
          unawaited(
            ref.read(isGeneticsRewardActiveProvider.notifier).consume(),
          );
          lastConsumedGeneticsRewardLocation = location;
        }
      } else if (location == AppRoutes.genealogy) {
        final premiumRedirect = PremiumGuard.redirect(isPremium);
        if (premiumRedirect != null) return premiumRedirect;
      }

      // Admin guard: restrict /admin/* routes to admin users
      final isAdminRoute = location.startsWith('/admin');
      if (isAdminRoute) {
        final adminRedirect = AdminGuard.redirect(isAdminAsync);
        if (adminRedirect != null) return adminRedirect;
      }

      return null;
    },
    routes: [
      // Splash (initialization)
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Public routes (Auth)
      ...buildAuthRoutes(),

      // Main App Shell (Bottom Nav)
      ShellRoute(
        navigatorKey: mainShellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.birds,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const BirdListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'form',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => BirdFormScreen(
                  editBirdId: state.uri.queryParameters['editId'],
                ),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  if (!isValidRouteId(id)) return const NotFoundScreen();
                  return BirdDetailScreen(birdId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.breeding,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const BreedingListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'form',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => BreedingFormScreen(
                  editPairId: state.uri.queryParameters['editId'],
                ),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  if (!isValidRouteId(id)) return const NotFoundScreen();
                  return BreedingDetailScreen(pairId: id);
                },
                routes: [
                  GoRoute(
                    path: 'eggs',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      if (!isValidRouteId(id)) return const NotFoundScreen();
                      return EggManagementScreen(pairId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.chicks,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ChickListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'form',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => ChickFormScreen(
                  editChickId: state.uri.queryParameters['editId'],
                ),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  if (!isValidRouteId(id)) return const NotFoundScreen();
                  return ChickDetailScreen(chickId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.calendar,
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const CalendarScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.more,
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const MoreScreen()),
          ),
        ],
      ),

      if (FeatureFlags.communityEnabled) ...buildCommunityRoutes(),
      if (FeatureFlags.marketplaceEnabled) ...buildMarketplaceRoutes(),
      if (FeatureFlags.messagingEnabled) ...buildMessagingRoutes(),
      if (FeatureFlags.gamificationEnabled) ...buildGamificationRoutes(),

      // Premium, user, 2FA, and health record routes
      ...buildUserRoutes(),

      // Admin routes (ShellRoute with AdminShell)
      buildAdminRoutes(adminShellNavigatorKey),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});

bool _isAnonymousAllowedRoute(String location) {
  // Only truly public routes are allowed without authentication.
  // Data routes (birds, breeding, chicks, calendar, health-records)
  // require login to prevent unauthorized data access.
  return location == AppRoutes.premium ||
      location == AppRoutes.userGuide ||
      location == AppRoutes.privacyPolicy ||
      location == AppRoutes.termsOfService ||
      location == AppRoutes.communityGuidelines;
}
