import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'domain/services/sync/sync_providers.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/premium/providers/premium_providers.dart';
import 'features/settings/providers/settings_providers.dart';
import 'router/app_router.dart';
import 'router/route_names.dart';

class BudgieBreedingApp extends ConsumerStatefulWidget {
  const BudgieBreedingApp({super.key});

  @override
  ConsumerState<BudgieBreedingApp> createState() => _BudgieBreedingAppState();
}

class _BudgieBreedingAppState extends ConsumerState<BudgieBreedingApp> {
  late final AppLifecycleListener _lifecycleListener;
  bool _didOpenDebugAuditRoute = false;

  @override
  void initState() {
    super.initState();
    // Sync locale from EasyLocalization to provider AFTER the first frame
    // to avoid state mutation during build phase (causes '!_dirty' assertion).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(appLocaleProvider.notifier).syncFromContext(context);
        _openDebugAuditRouteIfNeeded();
      }
    });

    // Refresh RevenueCat premium status when app comes to foreground.
    // Catches subscription renewals, expirations, and cancellations that
    // occurred while the app was backgrounded.
    _lifecycleListener = AppLifecycleListener(onResume: _onAppResumed);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onAppResumed() {
    final userId = ref.read(currentUserIdProvider);
    if (userId == 'anonymous') return;
    ref.read(localPremiumProvider.notifier).refresh();

    // Push pending local changes on app resume.
    // Uses lightweight pushChanges instead of fullSync — periodic and
    // network-aware providers handle full reconciliation separately.
    final isSyncing = ref.read(isSyncingProvider);
    if (!isSyncing) {
      final orchestrator = ref.read(syncOrchestratorProvider);
      orchestrator.pushChanges(userId).catchError((Object e, StackTrace st) {
        AppLogger.warning('[AppResume] Push failed: $e');
        return false;
      });
    }
  }

  void _openDebugAuditRouteIfNeeded() {
    if (_didOpenDebugAuditRoute || !kDebugMode) return;
    const enableGeneticsColorAudit = bool.fromEnvironment(
      'GENETICS_COLOR_AUDIT',
    );
    if (!enableGeneticsColorAudit) return;

    _didOpenDebugAuditRoute = true;
    ref.read(routerProvider).go(AppRoutes.geneticsColorAudit);
  }

  @override
  Widget build(BuildContext context) {
    // Mount global auth side-effects (RevenueCat/logout premium reset).
    ref.watch(authSessionSideEffectsProvider);

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<String>(currentUserIdProvider, (previous, next) {
      if (previous == next) return;

      final purchaseService = ref.read(purchaseServiceProvider);
      if (next == 'anonymous') {
        unawaited(purchaseService.logout());
        unawaited(ref.read(localPremiumProvider.notifier).setPremium(false));
        return;
      }

      final apiKey = Platform.isIOS
          ? revenueCatApiKeyIos
          : revenueCatApiKeyAndroid;
      if (apiKey.isEmpty) return;

      unawaited(
        purchaseService
            .initialize(apiKey: apiKey, userId: next)
            .then((ready) async {
              if (ready) {
                await ref.read(localPremiumProvider.notifier).refresh();
              }
            })
            .catchError((Object e, StackTrace st) {
              AppLogger.warning('[AppAuth] RevenueCat sync failed: $e');
            }),
      );
    });

    // Sync easy_localization when provider changes
    ref.listen<AppLocale>(appLocaleProvider, (previous, next) {
      if (previous != next) {
        context.setLocale(next.locale);
      }
    });

    final fontScale = ref.watch(fontScaleProvider);
    final compactView = ref.watch(compactViewProvider);
    final reduceAnimations = ref.watch(reduceAnimationsProvider);
    final visualDensity = compactView
        ? const VisualDensity(horizontal: -1, vertical: -1)
        : VisualDensity.standard;

    return MaterialApp.router(
      title: 'BudgieBreedingTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light().copyWith(
        visualDensity: visualDensity,
        listTileTheme: ListTileThemeData(
          dense: compactView,
          visualDensity: visualDensity,
        ),
      ),
      darkTheme: AppTheme.dark().copyWith(
        visualDensity: visualDensity,
        listTileTheme: ListTileThemeData(
          dense: compactView,
          visualDensity: visualDensity,
        ),
      ),
      themeMode: themeMode,
      themeAnimationDuration: reduceAnimations
          ? Duration.zero
          : kThemeAnimationDuration,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
      builder: (context, child) {
        final scale = fontScale.scaleFactor;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduceAnimations,
          ),
          child: child!,
        );
      },
    );
  }
}
