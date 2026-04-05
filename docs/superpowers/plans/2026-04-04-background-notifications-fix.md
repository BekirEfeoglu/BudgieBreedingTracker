# Background Notifications Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix notifications not firing when the app is closed or device is rebooted — boot receiver, re-schedule on app start, battery optimization warning.

**Architecture:** Add Android boot receiver to preserve scheduled alarms across reboots. Add `rescheduleAll()` to `NotificationScheduler` that queries active entities from DAOs and re-schedules their notifications on every app start. Add battery optimization warning banner to notification settings screen.

**Tech Stack:** flutter_local_notifications ^21.0.0, Drift (DAO queries), Riverpod 3, easy_localization

---

### Task 1: Android Boot Receiver

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add boot receiver to AndroidManifest.xml**

Add the `ScheduledNotificationBootReceiver` inside the `<application>` tag, after the existing `<meta-data>` entries and before `</application>`:

```xml
        <!-- Reschedule notifications after device reboot or app update -->
        <receiver android:exported="false"
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
```

The receiver goes after the `flutterEmbedding` meta-data (line 50) and before `</application>` (line 51).

- [ ] **Step 2: Verify manifest is valid XML**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && cat android/app/src/main/AndroidManifest.xml
```
Expected: Well-formed XML with the new `<receiver>` element inside `<application>`.

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "fix(notifications): add boot receiver for alarm persistence across reboots"
```

---

### Task 2: Notification Reschedule Service

**Files:**
- Create: `lib/domain/services/notifications/notification_rescheduler.dart`
- Test: `test/domain/services/notifications/notification_rescheduler_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/domain/services/notifications/notification_rescheduler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/egg_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/breeding_pairs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rescheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';

class MockIncubationsDao extends Mock implements IncubationsDao {}

class MockEggsDao extends Mock implements EggsDao {}

class MockChicksDao extends Mock implements ChicksDao {}

class MockNotificationScheduler extends Mock implements NotificationScheduler {}

void main() {
  late MockIncubationsDao mockIncubationsDao;
  late MockEggsDao mockEggsDao;
  late MockChicksDao mockChicksDao;
  late MockNotificationScheduler mockScheduler;
  late NotificationRescheduler rescheduler;

  setUp(() {
    mockIncubationsDao = MockIncubationsDao();
    mockEggsDao = MockEggsDao();
    mockChicksDao = MockChicksDao();
    mockScheduler = MockNotificationScheduler();
    rescheduler = NotificationRescheduler(
      incubationsDao: mockIncubationsDao,
      eggsDao: mockEggsDao,
      chicksDao: mockChicksDao,
      scheduler: mockScheduler,
    );
  });

  group('rescheduleAll', () {
    const userId = 'test-user';

    test('schedules egg turning and incubation milestones for active incubations', () async {
      final incubation = Incubation(
        id: 'inc-1',
        userId: userId,
        status: IncubationStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
      );
      final egg = Egg(
        id: 'egg-1',
        userId: userId,
        layDate: DateTime.now().subtract(const Duration(days: 5)),
        status: EggStatus.incubating,
        incubationId: 'inc-1',
      );

      when(() => mockIncubationsDao.getAll(userId))
          .thenAnswer((_) async => [incubation]);
      when(() => mockEggsDao.getIncubating(userId))
          .thenAnswer((_) async => [egg]);
      when(() => mockChicksDao.getUnweaned(userId))
          .thenAnswer((_) async => []);
      when(
        () => mockScheduler.scheduleIncubationMilestones(
          incubationId: any(named: 'incubationId'),
          startDate: any(named: 'startDate'),
          label: any(named: 'label'),
          species: any(named: 'species'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockScheduler.scheduleEggTurningReminders(
          eggId: any(named: 'eggId'),
          startDate: any(named: 'startDate'),
          eggLabel: any(named: 'eggLabel'),
          species: any(named: 'species'),
        ),
      ).thenAnswer((_) async {});

      await rescheduler.rescheduleAll(userId);

      verify(
        () => mockScheduler.scheduleIncubationMilestones(
          incubationId: 'inc-1',
          startDate: incubation.startDate!,
          label: any(named: 'label'),
          species: incubation.species,
        ),
      ).called(1);
      verify(
        () => mockScheduler.scheduleEggTurningReminders(
          eggId: 'egg-1',
          startDate: egg.layDate,
          eggLabel: any(named: 'eggLabel'),
          species: any(named: 'species'),
        ),
      ).called(1);
    });

    test('schedules chick care for unweaned chicks', () async {
      final chick = Chick(
        id: 'chick-1',
        userId: userId,
        hatchDate: DateTime.now().subtract(const Duration(days: 3)),
      );

      when(() => mockIncubationsDao.getAll(userId))
          .thenAnswer((_) async => []);
      when(() => mockEggsDao.getIncubating(userId))
          .thenAnswer((_) async => []);
      when(() => mockChicksDao.getUnweaned(userId))
          .thenAnswer((_) async => [chick]);
      when(
        () => mockScheduler.scheduleChickCareReminder(
          chickId: any(named: 'chickId'),
          chickLabel: any(named: 'chickLabel'),
          startDate: any(named: 'startDate'),
          intervalHours: any(named: 'intervalHours'),
          durationDays: any(named: 'durationDays'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockScheduler.scheduleBandingReminders(
          chickId: any(named: 'chickId'),
          chickLabel: any(named: 'chickLabel'),
          hatchDate: any(named: 'hatchDate'),
          bandingDay: any(named: 'bandingDay'),
        ),
      ).thenAnswer((_) async {});

      await rescheduler.rescheduleAll(userId);

      verify(
        () => mockScheduler.scheduleChickCareReminder(
          chickId: 'chick-1',
          chickLabel: any(named: 'chickLabel'),
          startDate: any(named: 'startDate'),
          intervalHours: any(named: 'intervalHours'),
          durationDays: any(named: 'durationDays'),
        ),
      ).called(1);
    });

    test('skips completed incubations', () async {
      final completedIncubation = Incubation(
        id: 'inc-done',
        userId: userId,
        status: IncubationStatus.completed,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
      );

      when(() => mockIncubationsDao.getAll(userId))
          .thenAnswer((_) async => [completedIncubation]);
      when(() => mockEggsDao.getIncubating(userId))
          .thenAnswer((_) async => []);
      when(() => mockChicksDao.getUnweaned(userId))
          .thenAnswer((_) async => []);

      await rescheduler.rescheduleAll(userId);

      verifyNever(
        () => mockScheduler.scheduleIncubationMilestones(
          incubationId: any(named: 'incubationId'),
          startDate: any(named: 'startDate'),
          label: any(named: 'label'),
          species: any(named: 'species'),
        ),
      );
    });

    test('handles empty data gracefully', () async {
      when(() => mockIncubationsDao.getAll(userId))
          .thenAnswer((_) async => []);
      when(() => mockEggsDao.getIncubating(userId))
          .thenAnswer((_) async => []);
      when(() => mockChicksDao.getUnweaned(userId))
          .thenAnswer((_) async => []);

      await rescheduler.rescheduleAll(userId);

      verifyNever(
        () => mockScheduler.scheduleIncubationMilestones(
          incubationId: any(named: 'incubationId'),
          startDate: any(named: 'startDate'),
          label: any(named: 'label'),
          species: any(named: 'species'),
        ),
      );
      verifyNever(
        () => mockScheduler.scheduleEggTurningReminders(
          eggId: any(named: 'eggId'),
          startDate: any(named: 'startDate'),
          eggLabel: any(named: 'eggLabel'),
        ),
      );
    });

    test('continues when one entity fails', () async {
      final incubation = Incubation(
        id: 'inc-1',
        userId: userId,
        status: IncubationStatus.active,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      when(() => mockIncubationsDao.getAll(userId))
          .thenAnswer((_) async => [incubation]);
      when(() => mockEggsDao.getIncubating(userId))
          .thenThrow(Exception('DB error'));
      when(() => mockChicksDao.getUnweaned(userId))
          .thenAnswer((_) async => []);
      when(
        () => mockScheduler.scheduleIncubationMilestones(
          incubationId: any(named: 'incubationId'),
          startDate: any(named: 'startDate'),
          label: any(named: 'label'),
          species: any(named: 'species'),
        ),
      ).thenAnswer((_) async {});

      // Should not throw — continues despite egg DAO failure
      await rescheduler.rescheduleAll(userId);

      verify(
        () => mockScheduler.scheduleIncubationMilestones(
          incubationId: 'inc-1',
          startDate: incubation.startDate!,
          label: any(named: 'label'),
          species: incubation.species,
        ),
      ).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && flutter test test/domain/services/notifications/notification_rescheduler_test.dart
```
Expected: FAIL — `notification_rescheduler.dart` does not exist yet.

- [ ] **Step 3: Write the implementation**

Create `lib/domain/services/notifications/notification_rescheduler.dart`:

```dart
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/chicks_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/eggs_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/incubations_dao.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_scheduler.dart';

/// Re-schedules all active notifications on app startup.
///
/// Queries active incubations, incubating eggs, and unweaned chicks
/// from local DAOs, then calls the corresponding [NotificationScheduler]
/// methods to ensure alarms survive device reboots and aggressive
/// battery optimization.
class NotificationRescheduler {
  NotificationRescheduler({
    required this.incubationsDao,
    required this.eggsDao,
    required this.chicksDao,
    required this.scheduler,
  });

  final IncubationsDao incubationsDao;
  final EggsDao eggsDao;
  final ChicksDao chicksDao;
  final NotificationScheduler scheduler;

  /// Re-schedules notifications for all active entities.
  ///
  /// Each category is independent — a failure in one does not block others.
  /// Deferred via [Future.microtask] from the caller to avoid blocking splash.
  Future<void> rescheduleAll(String userId) async {
    AppLogger.info(
      '[NotificationRescheduler] Reschedule started for user $userId',
    );

    var totalCount = 0;

    totalCount += await _rescheduleIncubations(userId);
    totalCount += await _rescheduleEggTurning(userId);
    totalCount += await _rescheduleChickCare(userId);

    AppLogger.info(
      '[NotificationRescheduler] Reschedule complete: $totalCount entities processed',
    );
  }

  Future<int> _rescheduleIncubations(String userId) async {
    try {
      final incubations = await incubationsDao.getAll(userId);
      final active = incubations
          .where((i) => i.status == IncubationStatus.active && i.startDate != null)
          .toList();

      for (final incubation in active) {
        await scheduler.scheduleIncubationMilestones(
          incubationId: incubation.id,
          startDate: incubation.startDate!,
          label: incubation.id.substring(0, 8),
          species: incubation.species,
        );
      }

      AppLogger.info(
        '[NotificationRescheduler] Rescheduled ${active.length} active incubations',
      );
      return active.length;
    } catch (e, st) {
      AppLogger.error('[NotificationRescheduler] Incubation reschedule failed', e, st);
      return 0;
    }
  }

  Future<int> _rescheduleEggTurning(String userId) async {
    try {
      final eggs = await eggsDao.getIncubating(userId);

      for (final egg in eggs) {
        await scheduler.scheduleEggTurningReminders(
          eggId: egg.id,
          startDate: egg.layDate,
          eggLabel: 'notifications.egg_label'.tr(args: ['${egg.eggNumber ?? ''}']),
        );
      }

      AppLogger.info(
        '[NotificationRescheduler] Rescheduled ${eggs.length} egg turning reminders',
      );
      return eggs.length;
    } catch (e, st) {
      AppLogger.error('[NotificationRescheduler] Egg turning reschedule failed', e, st);
      return 0;
    }
  }

  Future<int> _rescheduleChickCare(String userId) async {
    try {
      final chicks = await chicksDao.getUnweaned(userId);

      for (final chick in chicks) {
        if (chick.hatchDate == null) continue;

        await scheduler.scheduleChickCareReminder(
          chickId: chick.id,
          chickLabel: chick.name ?? chick.id.substring(0, 8),
          startDate: chick.hatchDate!,
          intervalHours: 4,
          durationDays: 30,
        );

        if (!chick.isBanded) {
          await scheduler.scheduleBandingReminders(
            chickId: chick.id,
            chickLabel: chick.name ?? chick.id.substring(0, 8),
            hatchDate: chick.hatchDate!,
            bandingDay: chick.bandingDay,
          );
        }
      }

      AppLogger.info(
        '[NotificationRescheduler] Rescheduled ${chicks.length} chick care reminders',
      );
      return chicks.length;
    } catch (e, st) {
      AppLogger.error('[NotificationRescheduler] Chick care reschedule failed', e, st);
      return 0;
    }
  }
}
```

**Note:** The `_rescheduleEggTurning` method uses `'notifications.egg_label'.tr()` — this key needs to be added in Task 5 (localization). For the test to compile, the import `import 'package:easy_localization/easy_localization.dart';` is needed in the implementation file. In tests, `.tr()` returns the key string itself (via TestAssetLoader), so tests will pass without real translations.

Add the easy_localization import to the implementation:

```dart
import 'package:easy_localization/easy_localization.dart';
```

(Add after the existing imports, before the class declaration.)

- [ ] **Step 4: Run tests to verify they pass**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && flutter test test/domain/services/notifications/notification_rescheduler_test.dart
```
Expected: All 5 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/services/notifications/notification_rescheduler.dart test/domain/services/notifications/notification_rescheduler_test.dart
git commit -m "feat(notifications): add NotificationRescheduler for app-start re-scheduling"
```

---

### Task 3: Wire Rescheduler Into App Initialization

**Files:**
- Modify: `lib/domain/services/notifications/notification_providers.dart`
- Modify: `lib/features/auth/providers/auth_providers.dart`

- [ ] **Step 1: Add rescheduler provider**

In `lib/domain/services/notifications/notification_providers.dart`, add at the end of the file (after `notificationSchedulerProvider`):

```dart
import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rescheduler.dart';
```

Add these imports at the top of the file alongside existing imports.

Then add the provider at the end:

```dart
/// Provides the [NotificationRescheduler] for app-start re-scheduling.
///
/// Queries active entities from local DAOs and re-schedules their
/// notifications to survive device reboots and battery optimization.
final notificationReschedulerProvider = Provider<NotificationRescheduler>((
  ref,
) {
  return NotificationRescheduler(
    incubationsDao: ref.watch(incubationsDaoProvider),
    eggsDao: ref.watch(eggsDaoProvider),
    chicksDao: ref.watch(chicksDaoProvider),
    scheduler: ref.watch(notificationSchedulerProvider),
  );
});
```

- [ ] **Step 2: Call rescheduleAll in app initialization**

In `lib/features/auth/providers/auth_providers.dart`, add this import at the top:

```dart
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_rescheduler.dart';
```

Then modify the `appInitializationProvider` to call reschedule after notification init. In the existing code, after `processPendingPayloads(ref);` (line 116) and before the `Future.microtask` data sync (line 120), add the reschedule call:

```dart
  // Process any notification payloads that arrived before router was ready
  processPendingPayloads(ref);

  // Re-schedule active notifications (survives reboot + battery kill)
  // Deferred to avoid blocking splash — runs in background
  Future.microtask(() => _rescheduleNotifications(ref, userId));

  // Step 3: Defer full data sync to background — don't block splash
```

Then add the helper function after the existing `_initNotifications` function:

```dart
/// Re-schedules all active notifications on app startup.
///
/// Runs in background (via Future.microtask) to avoid blocking splash.
/// Queries active incubations, incubating eggs, and unweaned chicks
/// from local DAOs and re-registers their alarms with the OS.
Future<void> _rescheduleNotifications(Ref ref, String userId) async {
  try {
    final rescheduler = ref.read(notificationReschedulerProvider);
    await rescheduler.rescheduleAll(userId);
  } catch (e, st) {
    AppLogger.warning('[AppInit] Notification reschedule failed: $e');
    Sentry.captureException(e, stackTrace: st);
  }
}
```

- [ ] **Step 3: Verify static analysis**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && flutter analyze --no-fatal-infos lib/domain/services/notifications/notification_providers.dart lib/features/auth/providers/auth_providers.dart
```
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/domain/services/notifications/notification_providers.dart lib/features/auth/providers/auth_providers.dart
git commit -m "feat(notifications): wire rescheduler into app initialization flow"
```

---

### Task 4: Battery Optimization Warning Banner

**Files:**
- Modify: `lib/features/notifications/screens/notification_settings_screen.dart`
- Modify: `lib/data/local/preferences/app_preferences.dart`
- Test: `test/features/notifications/screens/notification_settings_battery_banner_test.dart`

- [ ] **Step 1: Add preference key for dismissal**

In `lib/data/local/preferences/app_preferences.dart`, add a new key constant alongside the existing ones:

```dart
static const keyBatteryWarningDismissed = 'pref_battery_warning_dismissed';
```

Add getter and setter:

```dart
bool get batteryWarningDismissed =>
    _prefs.getBool(keyBatteryWarningDismissed) ?? false;

Future<bool> setBatteryWarningDismissed(bool dismissed) =>
    _prefs.setBool(keyBatteryWarningDismissed, dismissed);
```

- [ ] **Step 2: Write the battery banner widget test**

Create `test/features/notifications/screens/notification_settings_battery_banner_test.dart`:

```dart
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/notifications/screens/notification_settings_screen.dart';

import '../../../helpers/test_localization.dart';

void main() {
  group('BatteryOptimizationBanner', () {
    testWidgets('renders warning text', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const Scaffold(body: BatteryOptimizationBanner(isDismissed: false)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('notifications.battery_optimization_warning'),
        findsOneWidget,
      );
    });

    testWidgets('shows dismiss button', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const Scaffold(body: BatteryOptimizationBanner(isDismissed: false)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('notifications.battery_optimization_dismiss'),
        findsOneWidget,
      );
    });

    testWidgets('does not render when dismissed', (tester) async {
      await pumpLocalizedWidget(
        tester,
        const Scaffold(body: BatteryOptimizationBanner(isDismissed: true)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('notifications.battery_optimization_warning'),
        findsNothing,
      );
    });
  });
}
```

- [ ] **Step 3: Add BatteryOptimizationBanner widget**

In `lib/features/notifications/screens/notification_settings_screen.dart`, add the banner widget at the end of the file (before the closing `// _DndSection` comment):

```dart
/// Warning banner for Android battery optimization.
///
/// Shown at the top of notification settings when the user hasn't
/// dismissed it. Advises disabling battery optimization for reliable
/// notification delivery.
class BatteryOptimizationBanner extends StatelessWidget {
  const BatteryOptimizationBanner({
    super.key,
    required this.isDismissed,
    this.onDismiss,
  });

  final bool isDismissed;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (isDismissed) return const SizedBox.shrink();

    // Only show on Android — iOS handles background alarms reliably
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.batteryWarning,
                color: theme.colorScheme.onErrorContainer,
                size: AppSpacing.xxl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'notifications.battery_optimization_warning'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              child: Text('notifications.battery_optimization_dismiss'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
```

Add the `dart:io` import at the top of the file:

```dart
import 'dart:io' show Platform;
```

- [ ] **Step 4: Wire banner into NotificationSettingsScreen**

In the `NotificationSettingsScreen.build()` method, add the banner as the first child in the `ListView.children` list, before `const _NotificationHeader()`:

```dart
        children: [
          BatteryOptimizationBanner(
            isDismissed: ref.watch(_batteryWarningDismissedProvider),
            onDismiss: () {
              ref.read(_batteryWarningDismissedProvider.notifier).state = true;
              ref.read(appPreferencesProvider).setBatteryWarningDismissed(true);
            },
          ),
          const _NotificationHeader(),
```

Add a file-scoped provider for the dismissed state at the top of the file (after the imports, before the class):

```dart
/// Tracks whether the battery optimization warning has been dismissed.
final _batteryWarningDismissedProvider = StateProvider<bool>((ref) {
  return ref.watch(appPreferencesProvider).batteryWarningDismissed;
});
```

**Note:** This requires importing `app_preferences.dart` and its provider. Find where `appPreferencesProvider` is defined and import it. If it doesn't exist as a Riverpod provider, create a local read from `AppPreferences` via `SharedPreferences.getInstance()`. Check the codebase first.

- [ ] **Step 5: Run widget test**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && flutter test test/features/notifications/screens/notification_settings_battery_banner_test.dart
```
Expected: All 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/notifications/screens/notification_settings_screen.dart lib/data/local/preferences/app_preferences.dart test/features/notifications/screens/notification_settings_battery_banner_test.dart
git commit -m "feat(notifications): add battery optimization warning banner"
```

---

### Task 5: Localization Keys

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add keys to tr.json (master)**

Add these keys inside the existing `"notifications"` object:

```json
"battery_optimization_warning": "Bildirimlerin zamaninda gelmesi icin cihaz ayarlarindan bu uygulama icin pil optimizasyonunu kapatin.",
"battery_optimization_dismiss": "Bir daha gosterme",
"egg_label": "Yumurta {}"
```

- [ ] **Step 2: Add keys to en.json**

```json
"battery_optimization_warning": "To receive notifications on time, disable battery optimization for this app in your device settings.",
"battery_optimization_dismiss": "Don't show again",
"egg_label": "Egg {}"
```

- [ ] **Step 3: Add keys to de.json**

```json
"battery_optimization_warning": "Damit Benachrichtigungen rechtzeitig ankommen, deaktivieren Sie die Akkuoptimierung fuer diese App in den Geraeteeinstellungen.",
"battery_optimization_dismiss": "Nicht mehr anzeigen",
"egg_label": "Ei {}"
```

- [ ] **Step 4: Verify l10n sync**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && python3 scripts/check_l10n_sync.py
```
Expected: All 3 files in sync, no missing keys.

- [ ] **Step 5: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(l10n): add battery optimization warning and egg label keys"
```

---

### Task 6: Logging Improvements

**Files:**
- Modify: `lib/domain/services/notifications/notification_service.dart`

- [ ] **Step 1: Add scheduling log to scheduleNotification**

In `notification_service.dart`, inside the `scheduleNotification()` method, add a log line after the `_plugin.zonedSchedule()` call (after line 195):

```dart
    AppLogger.info(
      '[NotificationService] Scheduled: id=$id, at=$scheduledDate, channel=$channelId',
    );
```

- [ ] **Step 2: Add cancellation log to cancel method**

In the `cancel()` method (line 221-223), add a log line:

```dart
  Future<void> cancel(int id) async {
    await _plugin.cancel(id: id);
    AppLogger.debug('[NotificationService] Cancelled notification id=$id');
  }
```

- [ ] **Step 3: Verify analysis passes**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && flutter analyze --no-fatal-infos lib/domain/services/notifications/notification_service.dart
```
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/domain/services/notifications/notification_service.dart
git commit -m "feat(notifications): add scheduling and cancellation debug logging"
```

---

### Task 7: Final Verification

**Files:** None (verification only)

- [ ] **Step 1: Run full static analysis**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && flutter analyze --no-fatal-infos
```
Expected: No errors.

- [ ] **Step 2: Run notification-related tests**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && flutter test test/domain/services/notifications/
```
Expected: All tests PASS.

- [ ] **Step 3: Run code quality check**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && python3 scripts/verify_code_quality.py
```
Expected: No violations.

- [ ] **Step 4: Run l10n sync check**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && python3 scripts/check_l10n_sync.py
```
Expected: All languages in sync.

- [ ] **Step 5: Verify CLAUDE.md stats**

Run:
```bash
cd /Users/bekirefeoglu/Desktop/BudgieBreedingTracker && python3 scripts/verify_rules.py
```
Expected: Stats match or update needed (domain services count may increase by 0 since rescheduler is in existing notifications dir).
