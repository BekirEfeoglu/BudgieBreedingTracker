import 'dart:async';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:budgie_breeding_tracker/data/remote/storage/storage_service.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/chick_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/clutch_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/egg_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/event_reminder_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/growth_measurement_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/health_record_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/nest_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/notification_schedule_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/photo_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/profile_repository.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_metadata_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/auth/two_factor_service.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/two_factor_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/backup/backup_service.dart';
import 'package:budgie_breeding_tracker/domain/services/calendar/calendar_event_generator.dart';
import 'package:budgie_breeding_tracker/domain/services/export/excel_export_service.dart';
import 'package:budgie_breeding_tracker/domain/services/export/pdf_export_service.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/domain/services/import/data_import_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_service.dart';
import 'package:budgie_breeding_tracker/domain/services/payment/purchase_service.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_orchestrator.dart';
import 'package:budgie_breeding_tracker/features/admin/providers/admin_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/notifications/providers/notification_settings_providers.dart'
    as notif_settings;
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

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
  registerFallbackValue(
    Bird(
      id: 'fallback-bird',
      userId: 'fallback-user',
      name: 'Fallback',
      gender: BirdGender.unknown,
      status: BirdStatus.alive,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  );
  registerFallbackValue(
    BreedingPair(
      id: 'fallback-pair',
      userId: 'fallback-user',
      status: BreedingStatus.active,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  );
  registerFallbackValue(
    Egg(
      id: 'fallback-egg',
      userId: 'fallback-user',
      layDate: DateTime(2024, 1, 1),
      status: EggStatus.incubating,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  );
  registerFallbackValue(
    Incubation(
      id: 'fallback-incubation',
      userId: 'fallback-user',
      breedingPairId: 'fallback-pair',
      startDate: DateTime(2024, 1, 1),
      expectedHatchDate: DateTime(2024, 1, 19),
    ),
  );
  registerFallbackValue(
    Chick(
      id: 'fallback-chick',
      userId: 'fallback-user',
      gender: BirdGender.unknown,
      healthStatus: ChickHealthStatus.healthy,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    ),
  );
  registerFallbackValue(
    HealthRecord(
      id: 'fallback-health',
      userId: 'fallback-user',
      title: 'Fallback',
      type: HealthRecordType.checkup,
      date: DateTime(2024, 1, 1),
      createdAt: DateTime(2024, 1, 1),
    ),
  );
  registerFallbackValue(
    Event(
      id: 'fallback-event',
      title: 'Fallback Event',
      eventDate: DateTime(2024, 1, 1),
      type: EventType.custom,
      userId: 'fallback-user',
    ),
  );
  registerFallbackValue(
    GrowthMeasurement(
      id: 'fallback-growth',
      chickId: 'fallback-chick',
      weight: 1.0,
      measurementDate: DateTime(2024, 1, 1),
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
  registerFallbackValue(DateTime(2024, 1, 1));
  registerFallbackValue(const Duration(seconds: 1));
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

// Requested core mocks
class MockAuthActions extends Mock implements AuthActions {}

class MockTwoFactorService extends Mock implements TwoFactorService {}

class MockBirdRepository extends Mock implements BirdRepository {}

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockEggRepository extends Mock implements EggRepository {}

class MockChickRepository extends Mock implements ChickRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

class MockClutchRepository extends Mock implements ClutchRepository {}

class MockHealthRecordRepository extends Mock
    implements HealthRecordRepository {}

class MockGrowthMeasurementRepository extends Mock
    implements GrowthMeasurementRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

class MockEventRepository extends Mock implements EventRepository {}

class MockEventReminderRepository extends Mock
    implements EventReminderRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockSyncMetadataRepository extends Mock
    implements SyncMetadataRepository {}

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

class MockNestRepository extends Mock implements NestRepository {}

class MockPhotoRepository extends Mock implements PhotoRepository {}

class MockNotificationScheduleRepository extends Mock
    implements NotificationScheduleRepository {}

class MockStorageService extends Mock implements StorageService {}

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockNotificationService extends Mock implements NotificationService {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

class MockPurchaseService extends Mock implements PurchaseService {}

class MockPdfExportService extends Mock implements PdfExportService {}

class MockExcelExportService extends Mock implements ExcelExportService {}

class MockMendelianCalculator extends Mock implements MendelianCalculator {}

class MockBackupService extends Mock implements BackupService {}

class MockCalendarEventGenerator extends Mock
    implements CalendarEventGenerator {}

class MockDataImportService extends Mock implements DataImportService {}

typedef ConnectivityPlus = Connectivity;

class MockConnectivity extends Mock implements ConnectivityPlus {}
