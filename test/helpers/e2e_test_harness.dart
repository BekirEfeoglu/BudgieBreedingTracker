import 'dart:async';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:budgie_breeding_tracker/app.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/event_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/notification_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/database_provider.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/event_model.dart';
import 'package:budgie_breeding_tracker/data/models/growth_measurement_model.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/models/notification_model.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/domain/services/auth/two_factor_service.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart'
    as notif_settings;
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

import 'mocks.dart';
import 'test_fixtures.dart';
export 'mocks.dart';

const e2eTimeout = Timeout(Duration(seconds: 30));

bool _fallbacksRegistered = false;

void ensureE2EBinding() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  registerCommonFallbackValues();
}

void registerCommonFallbackValues() {
  if (_fallbacksRegistered) return;
  _fallbacksRegistered = true;

  registerFallbackValue(OAuthProvider.google);
  registerFallbackValue(Species.unknown);
  registerFallbackValue(
    Bird(
      id: 'fallback-bird',
      userId: 'fallback-user',
      name: 'Fallback',
      gender: BirdGender.unknown,
      status: BirdStatus.alive,
      createdAt: TestDates.baseline,
      updatedAt: TestDates.baseline,
    ),
  );
  registerFallbackValue(
    BreedingPair(
      id: 'fallback-pair',
      userId: 'fallback-user',
      status: BreedingStatus.active,
      createdAt: TestDates.baseline,
      updatedAt: TestDates.baseline,
    ),
  );
  registerFallbackValue(
    Egg(
      id: 'fallback-egg',
      userId: 'fallback-user',
      layDate: TestDates.baseline,
      status: EggStatus.incubating,
      createdAt: TestDates.baseline,
      updatedAt: TestDates.baseline,
    ),
  );
  registerFallbackValue(
    Incubation(
      id: 'fallback-incubation',
      userId: 'fallback-user',
      breedingPairId: 'fallback-pair',
      startDate: TestDates.baseline,
      expectedHatchDate: TestDates.expectedHatch,
    ),
  );
  registerFallbackValue(
    Chick(
      id: 'fallback-chick',
      userId: 'fallback-user',
      gender: BirdGender.unknown,
      healthStatus: ChickHealthStatus.healthy,
      createdAt: TestDates.baseline,
      updatedAt: TestDates.baseline,
    ),
  );
  registerFallbackValue(
    HealthRecord(
      id: 'fallback-health',
      userId: 'fallback-user',
      title: 'Fallback',
      type: HealthRecordType.checkup,
      date: TestDates.baseline,
      createdAt: TestDates.baseline,
    ),
  );
  registerFallbackValue(
    Event(
      id: 'fallback-event',
      title: 'Fallback Event',
      eventDate: TestDates.baseline,
      type: EventType.custom,
      userId: 'fallback-user',
    ),
  );
  registerFallbackValue(
    GrowthMeasurement(
      id: 'fallback-growth',
      chickId: 'fallback-chick',
      weight: 1.0,
      measurementDate: TestDates.baseline,
      userId: 'fallback-user',
    ),
  );
  registerFallbackValue(
    const SyncMetadata(
      id: 'fallback-sync',
      table: 'birds',
      userId: 'fallback-user',
      status: SyncStatus.pending,
    ),
  );
  registerFallbackValue(
    const AppNotification(
      id: 'fallback-notif',
      title: 'Fallback',
      userId: 'fallback-user',
      type: NotificationType.custom,
      priority: NotificationPriority.normal,
    ),
  );
  registerFallbackValue(
    const Profile(id: 'fallback-profile', email: 'fallback@example.com'),
  );
  registerFallbackValue(const notif_settings.NotificationToggleSettings());
  registerFallbackValue(TestDates.baseline);
  registerFallbackValue(const Duration(seconds: 1));
  registerFallbackValue(<Event>[]);
}

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{};
  }
}

class _TestInitSkippedNotifier extends InitSkippedNotifier {
  _TestInitSkippedNotifier(this._value);

  final bool _value;

  @override
  bool build() => _value;
}

AppDatabase createInMemoryDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

ProviderContainer createTestContainer({
  List<dynamic> overrides = const [],
  String userId = 'test-user',
  bool isAuthenticated = true,
  bool isPremium = false,
  AuthActions? authActions,
  TwoFactorService? twoFactorService,
  FutureOr<bool> Function(Ref ref)? isAdminBuilder,
  bool initSkipped = true,
  int defaultBirdCount = 0,
  int defaultActiveBreedingCount = 0,
  int defaultHealthRecordCount = 0,
}) {
  final defaultAuthActions = MockAuthActions();
  when(
    () => defaultAuthActions.signInWithEmail(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  ).thenAnswer((_) async => AuthResponse());
  when(
    () => defaultAuthActions.signUpWithEmail(
      email: any(named: 'email'),
      password: any(named: 'password'),
      data: any(named: 'data'),
    ),
  ).thenAnswer((_) async => AuthResponse());
  when(
    () => defaultAuthActions.signInWithOAuth(any()),
  ).thenAnswer((_) async => true);
  when(() => defaultAuthActions.resetPassword(any())).thenAnswer((_) async {});
  when(() => defaultAuthActions.signOut()).thenAnswer((_) async {});
  final effectiveAuthActions = authActions ?? defaultAuthActions;

  final defaultTwoFactorService = MockTwoFactorService();
  when(
    () => defaultTwoFactorService.needsVerification(),
  ).thenAnswer((_) async => false);
  final effectiveTwoFactorService = twoFactorService ?? defaultTwoFactorService;

  return ProviderContainer(
    overrides: <dynamic>[
      appDatabaseProvider.overrideWith((ref) {
        final db = createInMemoryDatabase();
        ref.onDispose(db.close);
        return db;
      }),
      currentUserIdProvider.overrideWithValue(userId),
      currentUserProvider.overrideWith((_) => null),
      isAuthenticatedProvider.overrideWithValue(isAuthenticated),
      isPremiumProvider.overrideWithValue(isPremium),
      isAdminProvider.overrideWith(isAdminBuilder ?? (_) async => false),
      appInitializationProvider.overrideWith((_) async {}),
      initSkippedProvider.overrideWith(
        () => _TestInitSkippedNotifier(initSkipped),
      ),
      authActionsProvider.overrideWithValue(effectiveAuthActions),
      twoFactorServiceProvider.overrideWithValue(effectiveTwoFactorService),
      supabaseInitializedProvider.overrideWithValue(true),
      adServiceProvider.overrideWithValue(MockAdService()),
      birdCountProvider.overrideWith((_, __) => Stream.value(defaultBirdCount)),
      activeBreedingCountProvider.overrideWith(
        (_, __) => Stream.value(defaultActiveBreedingCount),
      ),
      healthRecordCountProvider.overrideWith(
        (_, __) => Stream.value(defaultHealthRecordCount),
      ),
      ...overrides,
    ].cast(),
  );
}

Future<void> pumpApp(
  WidgetTester tester,
  ProviderContainer container, {
  Widget? child,
  GoRouter? router,
  Locale locale = const Locale('tr'),
}) async {
  final app = router != null
      ? MaterialApp.router(routerConfig: router)
      : MaterialApp(home: child ?? const SizedBox.shrink());

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
        fallbackLocale: const Locale('tr'),
        startLocale: locale,
        path: 'unused',
        assetLoader: const _TestAssetLoader(),
        child: app,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> pumpBudgieApp(
  WidgetTester tester,
  ProviderContainer container, {
  Locale locale = const Locale('tr'),
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: EasyLocalization(
        supportedLocales: const [Locale('tr'), Locale('en'), Locale('de')],
        fallbackLocale: const Locale('tr'),
        startLocale: locale,
        path: 'unused',
        assetLoader: const _TestAssetLoader(),
        child: const BudgieBreedingApp(),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 200));
}

GoRouter buildTestNavigator({
  String initialLocation = '/',
  required List<RouteBase> routes,
  GoRouterRedirect? redirect,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: routes,
    redirect: redirect,
    debugLogDiagnostics: false,
  );
}

Future<String> resolveRedirectFor(
  WidgetTester tester,
  GoRouter router,
  String location,
) async {
  late BuildContext context;
  await tester.pumpWidget(
    Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Builder(
        builder: (ctx) {
          context = ctx;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  final matchList = router.configuration.findMatch(Uri.parse(location));
  final resolved = await router.configuration.redirect(
    context,
    matchList,
    redirectHistory: <RouteMatchList>[],
  );
  return resolved.uri.toString();
}

// All mock classes are centralized in mocks.dart and re-exported above.
