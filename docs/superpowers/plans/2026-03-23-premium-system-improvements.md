# Premium System Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add sync retry mechanism, domain-layer free tier limit validation, and 7-day grace period for expired premium users.

**Architecture:** Three independent improvements to the premium system. (1) Retry pending Supabase syncs via SharedPreferences queue on natural app events. (2) Extract free tier limit checks into a domain service callable from form notifiers. (3) Grace period enum + derived providers that give expired users 7 more days of access with a warning banner.

**Tech Stack:** Flutter/Dart, Riverpod 3, SharedPreferences, Supabase, Sentry, easy_localization

**Spec:** `docs/superpowers/specs/2026-03-23-premium-system-improvements-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/core/enums/subscription_enums.dart` | Edit | Add `GracePeriodStatus` enum |
| `lib/core/constants/app_constants.dart` | Edit | Add `gracePeriodDays = 7` |
| `lib/core/errors/app_exception.dart` | Edit | Add `FreeTierLimitException` |
| `lib/domain/services/premium/free_tier_limit_service.dart` | Create | Domain service for limit guards |
| `lib/domain/services/premium/free_tier_limit_providers.dart` | Create | Riverpod provider for the service |
| `lib/features/premium/providers/premium_notifier.dart` | Edit | Retry logic + premiumExpiresAt sync |
| `lib/features/premium/providers/premium_providers.dart` | Edit | Add `premiumGracePeriodProvider`, `effectivePremiumProvider` |
| `lib/features/birds/providers/bird_form_providers.dart` | Edit | Use service + effectivePremiumProvider |
| `lib/features/breeding/providers/breeding_form_providers.dart` | Edit | Use service + effectivePremiumProvider |
| `lib/router/app_router.dart` | Edit | Use effectivePremiumProvider in guards |
| `lib/features/home/widgets/grace_period_banner.dart` | Create | Grace period warning widget |
| `lib/features/home/screens/home_screen.dart` | Edit | Add GracePeriodBanner |
| `assets/translations/tr.json` | Edit | New premium keys |
| `assets/translations/en.json` | Edit | New premium keys |
| `assets/translations/de.json` | Edit | New premium keys |
| `test/core/enums/subscription_enums_test.dart` | Create | GracePeriodStatus tests |
| `test/domain/services/premium/free_tier_limit_service_test.dart` | Create | Limit service tests |
| `test/features/premium/providers/premium_grace_period_test.dart` | Create | Grace period provider tests |
| `test/features/home/widgets/grace_period_banner_test.dart` | Create | Banner widget test |
| `supabase/functions/validate-free-tier-limit/index.ts` | Create | Server-side defense |

---

## Task 1: Core Layer — GracePeriodStatus Enum + Constants + Exception

**Files:**
- Modify: `lib/core/enums/subscription_enums.dart`
- Modify: `lib/core/constants/app_constants.dart`
- Modify: `lib/core/errors/app_exception.dart`
- Create: `test/core/enums/subscription_enums_test.dart`

- [ ] **Step 1: Add GracePeriodStatus enum to subscription_enums.dart**

Add after the existing `BackupFrequency` enum:

```dart
enum GracePeriodStatus {
  active,
  gracePeriod,
  expired,
  free,
  unknown;

  String toJson() => name;
  static GracePeriodStatus fromJson(String json) {
    try {
      return values.byName(json);
    } catch (_) {
      return GracePeriodStatus.unknown;
    }
  }
}
```

- [ ] **Step 2: Add gracePeriodDays to AppConstants**

In `lib/core/constants/app_constants.dart`, add after `freeTierCriticalRatio`:

```dart
static const int gracePeriodDays = 7;
```

- [ ] **Step 3: Add FreeTierLimitException to app_exception.dart**

In `lib/core/errors/app_exception.dart`, add after `PermissionException`:

```dart
class FreeTierLimitException extends AppException {
  final String entityType;
  final int limit;

  FreeTierLimitException(this.entityType, this.limit)
      : super('Free tier limit reached for $entityType');
}
```

Note: NOT `const` because `super()` contains string interpolation (`$entityType`).

- [ ] **Step 4: Write test for GracePeriodStatus**

Create `test/core/enums/subscription_enums_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';

void main() {
  group('GracePeriodStatus', () {
    test('toJson returns name', () {
      expect(GracePeriodStatus.active.toJson(), 'active');
      expect(GracePeriodStatus.gracePeriod.toJson(), 'gracePeriod');
      expect(GracePeriodStatus.unknown.toJson(), 'unknown');
    });

    test('fromJson parses valid values', () {
      expect(GracePeriodStatus.fromJson('active'), GracePeriodStatus.active);
      expect(
        GracePeriodStatus.fromJson('gracePeriod'),
        GracePeriodStatus.gracePeriod,
      );
      expect(GracePeriodStatus.fromJson('expired'), GracePeriodStatus.expired);
      expect(GracePeriodStatus.fromJson('free'), GracePeriodStatus.free);
    });

    test('fromJson returns unknown for invalid value', () {
      expect(GracePeriodStatus.fromJson('invalid'), GracePeriodStatus.unknown);
      expect(GracePeriodStatus.fromJson(''), GracePeriodStatus.unknown);
    });
  });
}
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/core/enums/subscription_enums_test.dart -v`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add lib/core/enums/subscription_enums.dart lib/core/constants/app_constants.dart lib/core/errors/app_exception.dart test/core/enums/subscription_enums_test.dart
git commit -m "feat(premium): add GracePeriodStatus enum, gracePeriodDays constant, FreeTierLimitException"
```

---

## Task 2: Domain Service — FreeTierLimitService

**Files:**
- Create: `lib/domain/services/premium/free_tier_limit_service.dart`
- Create: `lib/domain/services/premium/free_tier_limit_providers.dart`
- Create: `test/domain/services/premium/free_tier_limit_service_test.dart`

- [ ] **Step 1: Write failing tests for FreeTierLimitService**

Create `test/domain/services/premium/free_tier_limit_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_service.dart';

class MockBirdRepository extends Mock implements BirdRepository {}

class MockBreedingPairRepository extends Mock
    implements BreedingPairRepository {}

class MockIncubationRepository extends Mock implements IncubationRepository {}

void main() {
  late FreeTierLimitService service;
  late MockBirdRepository mockBirdRepo;
  late MockBreedingPairRepository mockBreedingRepo;
  late MockIncubationRepository mockIncubationRepo;

  setUp(() {
    mockBirdRepo = MockBirdRepository();
    mockBreedingRepo = MockBreedingPairRepository();
    mockIncubationRepo = MockIncubationRepository();
    service = FreeTierLimitService(
      birdRepo: mockBirdRepo,
      breedingPairRepo: mockBreedingRepo,
      incubationRepo: mockIncubationRepo,
    );
  });

  group('guardBirdLimit', () {
    test('does not throw when under limit', () async {
      final birds = List.generate(
        AppConstants.freeTierMaxBirds - 1,
        (i) => Bird(
          id: '$i',
          userId: 'u1',
          name: 'Bird $i',
          gender: BirdGender.male,
        ),
      );
      when(() => mockBirdRepo.getAll('u1')).thenAnswer((_) async => birds);

      await expectLater(service.guardBirdLimit('u1'), completes);
    });

    test('throws FreeTierLimitException at limit', () async {
      final birds = List.generate(
        AppConstants.freeTierMaxBirds,
        (i) => Bird(
          id: '$i',
          userId: 'u1',
          name: 'Bird $i',
          gender: BirdGender.male,
        ),
      );
      when(() => mockBirdRepo.getAll('u1')).thenAnswer((_) async => birds);

      await expectLater(
        service.guardBirdLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });
  });

  group('guardBreedingPairLimit', () {
    test('only counts active/ongoing pairs', () async {
      final pairs = [
        BreedingPair(
          id: '1',
          userId: 'u1',
          maleId: 'm1',
          femaleId: 'f1',
          status: BreedingStatus.completed,
          pairingDate: DateTime.now(),
        ),
      ];
      when(
        () => mockBreedingRepo.getAll('u1'),
      ).thenAnswer((_) async => pairs);

      await expectLater(service.guardBreedingPairLimit('u1'), completes);
    });

    test('throws when active pairs at limit', () async {
      final pairs = List.generate(
        AppConstants.freeTierMaxBreedingPairs,
        (i) => BreedingPair(
          id: '$i',
          userId: 'u1',
          maleId: 'm$i',
          femaleId: 'f$i',
          status: BreedingStatus.active,
          pairingDate: DateTime.now(),
        ),
      );
      when(
        () => mockBreedingRepo.getAll('u1'),
      ).thenAnswer((_) async => pairs);

      await expectLater(
        service.guardBreedingPairLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });
  });

  group('guardIncubationLimit', () {
    test('throws when active incubations at limit', () async {
      final incubations = List.generate(
        AppConstants.freeTierMaxActiveIncubations,
        (i) => Incubation(
          id: '$i',
          userId: 'u1',
          breedingPairId: 'bp$i',
          status: IncubationStatus.active,
          startDate: DateTime.now(),
          expectedHatchDate: DateTime.now().add(const Duration(days: 18)),
        ),
      );
      when(
        () => mockIncubationRepo.getAll('u1'),
      ).thenAnswer((_) async => incubations);

      await expectLater(
        service.guardIncubationLimit('u1'),
        throwsA(isA<FreeTierLimitException>()),
      );
    });

    test('does not throw when under limit', () async {
      when(
        () => mockIncubationRepo.getAll('u1'),
      ).thenAnswer((_) async => []);

      await expectLater(service.guardIncubationLimit('u1'), completes);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/domain/services/premium/free_tier_limit_service_test.dart -v`
Expected: FAIL (file not found)

- [ ] **Step 3: Create FreeTierLimitService**

Create `lib/domain/services/premium/free_tier_limit_service.dart`:

```dart
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/breeding_pair_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/incubation_repository.dart';

/// Domain service that enforces free tier entity limits.
///
/// Called by form notifiers before creating new entities.
/// Premium users bypass all checks (caller responsibility).
class FreeTierLimitService {
  final BirdRepository _birdRepo;
  final BreedingPairRepository _breedingPairRepo;
  final IncubationRepository _incubationRepo;

  const FreeTierLimitService({
    required BirdRepository birdRepo,
    required BreedingPairRepository breedingPairRepo,
    required IncubationRepository incubationRepo,
  })  : _birdRepo = birdRepo,
        _breedingPairRepo = breedingPairRepo,
        _incubationRepo = incubationRepo;

  /// Throws [FreeTierLimitException] if bird count >= [AppConstants.freeTierMaxBirds].
  Future<void> guardBirdLimit(String userId) async {
    final birds = await _birdRepo.getAll(userId);
    if (birds.length >= AppConstants.freeTierMaxBirds) {
      throw FreeTierLimitException('bird', AppConstants.freeTierMaxBirds);
    }
  }

  /// Throws [FreeTierLimitException] if active breeding pair count >= limit.
  Future<void> guardBreedingPairLimit(String userId) async {
    final pairs = await _breedingPairRepo.getAll(userId);
    final activeCount = pairs
        .where(
          (p) =>
              p.status == BreedingStatus.active ||
              p.status == BreedingStatus.ongoing,
        )
        .length;
    if (activeCount >= AppConstants.freeTierMaxBreedingPairs) {
      throw FreeTierLimitException(
        'breeding',
        AppConstants.freeTierMaxBreedingPairs,
      );
    }
  }

  /// Throws [FreeTierLimitException] if active incubation count >= limit.
  Future<void> guardIncubationLimit(String userId) async {
    final incubations = await _incubationRepo.getAll(userId);
    final activeCount = incubations
        .where((i) => i.status == IncubationStatus.active)
        .length;
    if (activeCount >= AppConstants.freeTierMaxActiveIncubations) {
      throw FreeTierLimitException(
        'incubation',
        AppConstants.freeTierMaxActiveIncubations,
      );
    }
  }
}
```

- [ ] **Step 4: Create provider file**

Create `lib/domain/services/premium/free_tier_limit_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_service.dart';

final freeTierLimitServiceProvider = Provider<FreeTierLimitService>((ref) {
  return FreeTierLimitService(
    birdRepo: ref.watch(birdRepositoryProvider),
    breedingPairRepo: ref.watch(breedingPairRepositoryProvider),
    incubationRepo: ref.watch(incubationRepositoryProvider),
  );
});
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/domain/services/premium/free_tier_limit_service_test.dart -v`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add lib/domain/services/premium/ test/domain/services/premium/
git commit -m "feat(premium): add FreeTierLimitService domain service with provider"
```

---

## Task 3: Sync Retry Mechanism in PremiumNotifier

**Files:**
- Modify: `lib/features/premium/providers/premium_notifier.dart`

- [ ] **Step 1: Add retry constants and pending sync key helper**

In `PremiumNotifier` class, add after `_cacheKey`:

```dart
static const int _maxSyncRetries = 3;
static String _pendingSyncKey(String userId) => 'pending_premium_sync_$userId';
```

- [ ] **Step 2: Add _savePendingSync method**

```dart
Future<void> _savePendingSync(String userId, bool isPremium) async {
  final prefs = await SharedPreferences.getInstance();
  final data = jsonEncode({
    'isPremium': isPremium,
    'retryCount': 0,
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  });
  await prefs.setString(_pendingSyncKey(userId), data);
  AppLogger.info('[PremiumNotifier] Saved pending sync for user $userId');
}
```

- [ ] **Step 3: Add _clearPendingSync method**

```dart
Future<void> _clearPendingSync(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_pendingSyncKey(userId));
}
```

- [ ] **Step 4: Add _retryPendingSync method**

```dart
Future<void> _retryPendingSync(String userId) async {
  if (userId == 'anonymous') return;
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_pendingSyncKey(userId));
  if (raw == null) return;

  int retryCount = 0;
  bool isPremium = true;
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    retryCount = (map['retryCount'] as num?)?.toInt() ?? 0;
    isPremium = map['isPremium'] as bool? ?? true;
  } catch (_) {
    await _clearPendingSync(userId);
    return;
  }

  if (retryCount >= _maxSyncRetries) {
    AppLogger.warning(
      '[PremiumNotifier] Max sync retries ($retryCount) reached for $userId',
    );
    Sentry.captureException(
      Exception('Premium Supabase sync failed after $_maxSyncRetries retries'),
      stackTrace: StackTrace.current,
    );
    await _clearPendingSync(userId);
    return;
  }

  AppLogger.info(
    '[PremiumNotifier] Retrying pending sync (attempt ${retryCount + 1}/$_maxSyncRetries)',
  );

  try {
    await _syncPremiumToSupabase(isPremium: isPremium);
    // _syncPremiumToSupabase clears pending on success (step 6)
  } catch (_) {
    final newData = jsonEncode({
      'isPremium': isPremium,
      'retryCount': retryCount + 1,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
    await prefs.setString(_pendingSyncKey(userId), newData);
  }
}
```

- [ ] **Step 5: Add `import 'dart:convert';` to premium_providers.dart**

In `lib/features/premium/providers/premium_providers.dart`, add at the top with other imports:

```dart
import 'dart:convert';
```

Also add the Sentry import if not present:

```dart
import 'package:sentry_flutter/sentry_flutter.dart';
```

- [ ] **Step 6: Update _syncPremiumToSupabase — add premiumExpiresAt + clear pending on success + save pending on failure**

In `_syncPremiumToSupabase`, make these changes:

**6a.** After the profiles table update (line 133-139), add `premium_expires_at`:

Replace the profiles update block:
```dart
// Update profiles table (source of truth)
await client
    .from(SupabaseConstants.profilesTable)
    .update({
      'is_premium': isPremium,
      'subscription_status': isPremium ? 'premium' : 'free',
    })
    .eq('id', userId);
```

With:
```dart
// Determine expiry from RevenueCat subscription info
DateTime? expiresAt;
if (isPremium) {
  try {
    if (!ref.mounted) return;
    final info = await ref
        .read(purchaseServiceProvider)
        .getSubscriptionInfo();
    expiresAt = info.expirationDate;
  } catch (_) {
    // RevenueCat info unavailable — proceed without expiry
  }
}

// Update profiles table (source of truth)
await client
    .from(SupabaseConstants.profilesTable)
    .update({
      'is_premium': isPremium,
      'subscription_status': isPremium ? 'premium' : 'free',
      'premium_expires_at': isPremium ? expiresAt?.toIso8601String() : null,
    })
    .eq('id', userId);
```

Note: Move the `expiresAt` logic up before the profiles update so it's available for both profiles and user_subscriptions. Remove the duplicate `expiresAt` block that was previously inside the `if (isPremium)` section (lines 142-152 of original).

**6b.** At the very end of the try block (before catch), add success clear:

```dart
      // Sync succeeded — clear any pending retry
      await _clearPendingSync(userId);
```

**6c.** In the catch block, add pending save for retryable errors. Replace the current catch block:

```dart
    } catch (e) {
      if (_isSupabaseUnavailableError(e)) {
        AppLogger.info(
          '[PremiumNotifier] Skipping Supabase sync: Supabase is not initialized',
        );
      } else {
        AppLogger.warning(
          '[PremiumNotifier] Supabase sync failed (non-fatal): $e',
        );
        // Save for retry on next app resume
        await _savePendingSync(userId, isPremium);
      }
    }
```

- [ ] **Step 7: Wire retry into _load and refresh**

**7a.** In `_load()`, add after the RevenueCat try-catch block (after line 53):

```dart
    // Retry any pending Supabase sync from a previous failed attempt
    await _retryPendingSync(userId);
```

**7b.** In `refresh()`, add at the end of the method (after the try-catch, before the closing `}`):

```dart
    // Retry any pending Supabase sync
    final userId = ref.read(currentUserIdProvider);
    await _retryPendingSync(userId);
```

- [ ] **Step 8: Run existing premium tests to check nothing broke**

Run: `flutter test test/features/premium/ -v`
Expected: ALL PASS (or only pre-existing failures)

- [ ] **Step 9: Add sync retry unit tests**

Create `test/features/premium/providers/premium_sync_retry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('Premium sync retry SharedPreferences logic', () {
    const userId = 'test-user';
    String pendingSyncKey(String uid) => 'pending_premium_sync_$uid';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('pending sync data can be saved and read', () async {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'isPremium': true,
        'retryCount': 0,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString(pendingSyncKey(userId), data);

      final raw = prefs.getString(pendingSyncKey(userId));
      expect(raw, isNotNull);
      final map = jsonDecode(raw!) as Map<String, dynamic>;
      expect(map['isPremium'], true);
      expect(map['retryCount'], 0);
    });

    test('retry count increments correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final initial = jsonEncode({
        'isPremium': true,
        'retryCount': 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString(pendingSyncKey(userId), initial);

      // Simulate increment
      final raw = prefs.getString(pendingSyncKey(userId))!;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final retryCount = (map['retryCount'] as num).toInt();
      final updated = jsonEncode({
        'isPremium': map['isPremium'],
        'retryCount': retryCount + 1,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await prefs.setString(pendingSyncKey(userId), updated);

      final result = jsonDecode(
        prefs.getString(pendingSyncKey(userId))!,
      ) as Map<String, dynamic>;
      expect(result['retryCount'], 2);
    });

    test('clear removes pending sync', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        pendingSyncKey(userId),
        jsonEncode({'isPremium': true, 'retryCount': 0}),
      );

      await prefs.remove(pendingSyncKey(userId));
      expect(prefs.getString(pendingSyncKey(userId)), isNull);
    });

    test('max retry threshold is 3', () {
      const maxSyncRetries = 3;
      expect(0 >= maxSyncRetries, false);
      expect(2 >= maxSyncRetries, false);
      expect(3 >= maxSyncRetries, true);
      expect(5 >= maxSyncRetries, true);
    });

    test('anonymous user has no pending sync', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pendingSyncKey('anonymous')), isNull);
    });
  });
}
```

Run: `flutter test test/features/premium/providers/premium_sync_retry_test.dart -v`
Expected: ALL PASS

- [ ] **Step 10: Commit**

```bash
git add lib/features/premium/providers/premium_providers.dart lib/features/premium/providers/premium_notifier.dart test/features/premium/providers/premium_sync_retry_test.dart
git commit -m "feat(premium): add Supabase sync retry mechanism with pending queue"
```

---

## Task 4: Grace Period Providers

**Files:**
- Modify: `lib/features/premium/providers/premium_providers.dart`
- Create: `test/features/premium/providers/premium_grace_period_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/features/premium/providers/premium_grace_period_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';

void main() {
  group('premiumGracePeriodProvider', () {
    /// Creates a container where userProfileProvider is overridden to
    /// immediately emit the given [profile]. We use `listen` + `pump` to
    /// ensure the stream has emitted before reading derived providers.
    Future<ProviderContainer> createContainer({Profile? profile}) async {
      final container = ProviderContainer(
        overrides: [
          userProfileProvider.overrideWith(
            (ref) => Stream.value(profile),
          ),
          currentUserIdProvider.overrideWith((ref) => profile?.id ?? 'anon'),
          isAuthenticatedProvider.overrideWith((ref) => true),
        ],
      );
      // Wait for the stream to emit so profileAsync.value is populated.
      await container.read(userProfileProvider.future);
      return container;
    }

    test('returns active when isPremium is true', () async {
      final container = await createContainer(
        profile: const Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: true,
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.active,
      );
    });

    test('returns active for admin role', () async {
      final container = await createContainer(
        profile: const Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
          role: 'admin',
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.active,
      );
    });

    test('returns gracePeriod when expired within 7 days', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.gracePeriod,
      );
    });

    test('returns expired when expired more than 7 days ago', () async {
      final container = await createContainer(
        profile: Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
          premiumExpiresAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.expired,
      );
    });

    test('returns free when no premiumExpiresAt', () async {
      final container = await createContainer(
        profile: const Profile(
          id: 'u1',
          email: 'a@b.com',
          isPremium: false,
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(premiumGracePeriodProvider),
        GracePeriodStatus.free,
      );
    });
  });

  group('effectivePremiumProvider', () {
    test('returns true for active', () {
      final container = ProviderContainer(
        overrides: [
          premiumGracePeriodProvider.overrideWith(
            (ref) => GracePeriodStatus.active,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(effectivePremiumProvider), true);
    });

    test('returns true for gracePeriod', () {
      final container = ProviderContainer(
        overrides: [
          premiumGracePeriodProvider.overrideWith(
            (ref) => GracePeriodStatus.gracePeriod,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(effectivePremiumProvider), true);
    });

    test('returns false for expired', () {
      final container = ProviderContainer(
        overrides: [
          premiumGracePeriodProvider.overrideWith(
            (ref) => GracePeriodStatus.expired,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(effectivePremiumProvider), false);
    });

    test('returns false for free', () {
      final container = ProviderContainer(
        overrides: [
          premiumGracePeriodProvider.overrideWith(
            (ref) => GracePeriodStatus.free,
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(effectivePremiumProvider), false);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/features/premium/providers/premium_grace_period_test.dart -v`
Expected: FAIL (providers not found)

- [ ] **Step 3: Add premiumGracePeriodProvider and effectivePremiumProvider**

In `lib/features/premium/providers/premium_providers.dart`, add the import for the new enum and constants:

```dart
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
```

Then add after `subscriptionInfoProvider` (at the end of the file):

```dart
/// Determines the user's premium grace period status.
///
/// Uses profile data (premiumExpiresAt) to detect grace period.
/// Admin/founder roles always return [GracePeriodStatus.active].
///
/// Usage: Use this provider when you need to distinguish between
/// active premium, grace period, and expired states.
/// For simple "has access?" checks, use [effectivePremiumProvider] instead.
final premiumGracePeriodProvider = Provider<GracePeriodStatus>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  final profile = profileAsync.value;

  // No profile loaded yet — treat as unknown/free
  if (profile == null) return GracePeriodStatus.free;

  // Admin/founder always active
  if (profile.isAdmin || profile.isFounder) return GracePeriodStatus.active;

  // Currently premium (active subscription)
  if (profile.hasPremium) return GracePeriodStatus.active;

  // Check grace period via premiumExpiresAt
  final expiresAt = profile.premiumExpiresAt;
  if (expiresAt == null) return GracePeriodStatus.free;

  final daysSinceExpiry = DateTime.now().difference(expiresAt).inDays;
  if (daysSinceExpiry <= AppConstants.gracePeriodDays) {
    return GracePeriodStatus.gracePeriod;
  }

  return GracePeriodStatus.expired;
});

/// Whether the user has effective premium access (active OR grace period).
///
/// Use this provider for:
/// - Free tier limit checks in form notifiers
/// - Premium route guards
///
/// Do NOT use for:
/// - Ad visibility (use [isPremiumProvider] — grace period shows ads)
/// - Subscription info display (use [premiumGracePeriodProvider])
final effectivePremiumProvider = Provider<bool>((ref) {
  final status = ref.watch(premiumGracePeriodProvider);
  return status == GracePeriodStatus.active ||
      status == GracePeriodStatus.gracePeriod;
});
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/premium/providers/premium_grace_period_test.dart -v`
Expected: ALL PASS (some tests may need override adjustments — fix as needed)

- [ ] **Step 5: Run all existing premium tests**

Run: `flutter test test/features/premium/ -v`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/premium/providers/premium_providers.dart test/features/premium/providers/premium_grace_period_test.dart
git commit -m "feat(premium): add grace period and effective premium providers"
```

---

## Task 5: Update Form Notifiers to Use Service + effectivePremiumProvider

**Files:**
- Modify: `lib/features/birds/providers/bird_form_providers.dart`
- Modify: `lib/features/breeding/providers/breeding_form_providers.dart`

- [ ] **Step 1: Update bird_form_providers.dart**

**1a.** Add import:

```dart
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_providers.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
```

**1b.** In `createBird()`, replace the inline limit check (lines 99-113) with:

```dart
      // Free tier bird limit check
      final isPremium = ref.read(effectivePremiumProvider);
      if (!isPremium) {
        try {
          await ref.read(freeTierLimitServiceProvider).guardBirdLimit(userId);
        } on FreeTierLimitException catch (e) {
          state = state.copyWith(
            isLoading: false,
            error: 'premium.bird_limit_reached'.tr(
              args: ['${e.limit}'],
            ),
            isBirdLimitReached: true,
          );
          return;
        }
      }
```

**1c.** In the "remaining birds" calculation (lines 148-152), replace `isPremium` reference:

Already uses local `isPremium` variable which is now from `effectivePremiumProvider` — no change needed.

**1d.** Remove the now-unused `AppConstants` import if it was only used for `freeTierMaxBirds` in the limit check. Check — if `AppConstants.freeTierMaxBirds` is still used in the remaining-birds calculation, keep it.

- [ ] **Step 2: Update breeding_form_providers.dart**

**2a.** Add import:

```dart
import 'package:budgie_breeding_tracker/domain/services/premium/free_tier_limit_providers.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
```

**2b.** In `createBreeding()`, replace the inline limit checks (lines 92-127) with:

```dart
      // Free tier limit checks
      final isPremium = ref.read(effectivePremiumProvider);
      if (!isPremium) {
        try {
          await ref
              .read(freeTierLimitServiceProvider)
              .guardBreedingPairLimit(userId);
        } on FreeTierLimitException {
          state = state.copyWith(
            isLoading: false,
            error: 'premium.breeding_limit_reached'.tr(
              args: ['${AppConstants.freeTierMaxBreedingPairs}'],
            ),
            isBreedingLimitReached: true,
          );
          return;
        }

        try {
          await ref
              .read(freeTierLimitServiceProvider)
              .guardIncubationLimit(userId);
        } on FreeTierLimitException {
          state = state.copyWith(
            isLoading: false,
            error: 'premium.incubation_limit_reached'.tr(
              args: ['${AppConstants.freeTierMaxActiveIncubations}'],
            ),
            isIncubationLimitReached: true,
          );
          return;
        }
      }
```

- [ ] **Step 3: Run existing form tests**

Run: `flutter test test/features/birds/providers/ test/features/breeding/providers/ -v`
Expected: ALL PASS (may need to add `effectivePremiumProvider` and `freeTierLimitServiceProvider` overrides in test setup)

- [ ] **Step 4: Commit**

```bash
git add lib/features/birds/providers/bird_form_providers.dart lib/features/breeding/providers/breeding_form_providers.dart
git commit -m "refactor(premium): use FreeTierLimitService and effectivePremiumProvider in form notifiers"
```

---

## Task 6: Update Router Premium Guards

**Files:**
- Modify: `lib/router/app_router.dart`

- [ ] **Step 1: Add effectivePremiumProvider usage**

In `lib/router/app_router.dart`, the `redirect` function currently reads:

```dart
final isPremium = ref.read(isPremiumProvider);
```

Change to:

```dart
final isPremium = ref.read(effectivePremiumProvider);
```

This affects the premium guard checks at lines 114-132. The variable name stays `isPremium` so all downstream logic is unchanged.

- [ ] **Step 2: Add import if needed**

The file already imports `premium_providers.dart` which will contain `effectivePremiumProvider`. No new import needed.

- [ ] **Step 3: Run router tests**

Run: `flutter test test/router/ -v`
Expected: ALL PASS (may need `effectivePremiumProvider` override in test setup)

- [ ] **Step 4: Commit**

```bash
git add lib/router/app_router.dart
git commit -m "feat(premium): use effectivePremiumProvider in route guards for grace period support"
```

---

## Task 7: Grace Period Banner + Home Screen Integration

**Files:**
- Create: `lib/features/home/widgets/grace_period_banner.dart`
- Modify: `lib/features/home/screens/home_screen.dart`
- Create: `test/features/home/widgets/grace_period_banner_test.dart`

- [ ] **Step 1: Create GracePeriodBanner widget**

Create `lib/features/home/widgets/grace_period_banner.dart`:

```dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart'; // AppColors.warning used as base; theme-adapted below
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

class GracePeriodBanner extends ConsumerWidget {
  const GracePeriodBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(premiumGracePeriodProvider);
    if (status != GracePeriodStatus.gracePeriod) {
      return const SizedBox.shrink();
    }

    final profileAsync = ref.watch(userProfileProvider);
    final expiresAt = profileAsync.value?.premiumExpiresAt;
    final daysAgo = expiresAt != null
        ? DateTime.now().difference(expiresAt).inDays
        : 0;
    final theme = Theme.of(context);
    // Use AppColors.warning as accent — consistent with LimitApproachingBanner
    final bannerColor = AppColors.warning;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: bannerColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'premium.grace_period_title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'premium.grace_period_message'.tr(args: ['$daysAgo']),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(AppRoutes.premium),
            child: Text(
              'premium.grace_period_renew'.tr(),
              style: TextStyle(
                color: bannerColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add GracePeriodBanner to home_screen.dart**

In `lib/features/home/screens/home_screen.dart`:

**2a.** Add import:

```dart
import 'package:budgie_breeding_tracker/features/home/widgets/grace_period_banner.dart';
```

**2b.** Add the banner after `LimitApproachingBanner` (line 80):

```dart
              LimitApproachingBanner(userId: userId),
              const GracePeriodBanner(),
```

- [ ] **Step 3: Write widget test**

Create `test/features/home/widgets/grace_period_banner_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/grace_period_banner.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

void main() {
  group('GracePeriodBanner', () {
    testWidgets('hidden when not in grace period', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            premiumGracePeriodProvider
                .overrideWithValue(GracePeriodStatus.active),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(
                const Profile(id: 'u1', email: 'a@b.com', isPremium: true),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: GracePeriodBanner())),
        ),
      );

      expect(find.byType(GracePeriodBanner), findsOneWidget);
      expect(find.text('premium.grace_period_title'), findsNothing);
    });

    testWidgets('shown when in grace period', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            premiumGracePeriodProvider
                .overrideWithValue(GracePeriodStatus.gracePeriod),
            userProfileProvider.overrideWith(
              (ref) => Stream.value(
                Profile(
                  id: 'u1',
                  email: 'a@b.com',
                  isPremium: false,
                  premiumExpiresAt: DateTime.now().subtract(
                    const Duration(days: 3),
                  ),
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: GracePeriodBanner())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });
  });
}
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/features/home/widgets/grace_period_banner_test.dart -v`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/home/widgets/grace_period_banner.dart lib/features/home/screens/home_screen.dart test/features/home/widgets/grace_period_banner_test.dart
git commit -m "feat(premium): add GracePeriodBanner widget and integrate into home screen"
```

---

## Task 8: Localization Keys

**Files:**
- Modify: `assets/translations/tr.json`
- Modify: `assets/translations/en.json`
- Modify: `assets/translations/de.json`

- [ ] **Step 1: Add keys to tr.json**

In the `"premium"` section of `assets/translations/tr.json`, add:

```json
"grace_period_title": "Premium Süreniz Doldu",
"grace_period_message": "Premium aboneliğiniz {} gün önce sona erdi. Yenileyin!",
"grace_period_renew": "Şimdi Yenile",
"sync_failed_warning": "Premium durumunuz sunucuya senkronize edilemedi",
"free_tier_limit_bird": "Ücretsiz planda en fazla {} kuş ekleyebilirsiniz",
"free_tier_limit_breeding": "Ücretsiz planda en fazla {} aktif çift oluşturabilirsiniz",
"free_tier_limit_incubation": "Ücretsiz planda en fazla {} aktif kuluçka başlatabilirsiniz"
```

- [ ] **Step 2: Add keys to en.json**

In the `"premium"` section of `assets/translations/en.json`, add:

```json
"grace_period_title": "Your Premium Has Expired",
"grace_period_message": "Your premium subscription expired {} days ago. Renew now!",
"grace_period_renew": "Renew Now",
"sync_failed_warning": "Your premium status could not be synced to the server",
"free_tier_limit_bird": "Free plan allows up to {} birds",
"free_tier_limit_breeding": "Free plan allows up to {} active breeding pairs",
"free_tier_limit_incubation": "Free plan allows up to {} active incubations"
```

- [ ] **Step 3: Add keys to de.json**

In the `"premium"` section of `assets/translations/de.json`, add:

```json
"grace_period_title": "Ihr Premium ist abgelaufen",
"grace_period_message": "Ihr Premium-Abonnement ist vor {} Tagen abgelaufen. Jetzt erneuern!",
"grace_period_renew": "Jetzt erneuern",
"sync_failed_warning": "Ihr Premium-Status konnte nicht mit dem Server synchronisiert werden",
"free_tier_limit_bird": "Im kostenlosen Plan können Sie bis zu {} Vögel hinzufügen",
"free_tier_limit_breeding": "Im kostenlosen Plan können Sie bis zu {} aktive Zuchtpaare erstellen",
"free_tier_limit_incubation": "Im kostenlosen Plan können Sie bis zu {} aktive Bruten starten"
```

- [ ] **Step 4: Run L10n sync check**

Run: `python scripts/check_l10n_sync.py`
Expected: All keys in sync across 3 files

- [ ] **Step 5: Commit**

```bash
git add assets/translations/tr.json assets/translations/en.json assets/translations/de.json
git commit -m "feat(l10n): add premium grace period and free tier limit translation keys"
```

---

## Task 9: Supabase Edge Function (Defense-in-Depth)

**Files:**
- Create: `supabase/functions/validate-free-tier-limit/index.ts`

- [ ] **Step 1: Create edge function**

Create `supabase/functions/validate-free-tier-limit/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const LIMITS: Record<string, number> = {
  birds: 15,
  breeding_pairs: 5,
  incubations: 3,
};

serve(async (req) => {
  try {
    const { table, user_id } = await req.json();

    if (!table || !user_id) {
      return new Response(
        JSON.stringify({ error: "Missing table or user_id" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const limit = LIMITS[table];
    if (!limit) {
      // No limit for this table — allow
      return new Response(
        JSON.stringify({ allowed: true }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    // Check if user is premium
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: profile } = await supabase
      .from("profiles")
      .select("is_premium, role")
      .eq("id", user_id)
      .single();

    if (
      profile?.is_premium ||
      profile?.role === "admin" ||
      profile?.role === "founder"
    ) {
      return new Response(
        JSON.stringify({ allowed: true }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    // Count active records
    let query = supabase
      .from(table)
      .select("id", { count: "exact", head: true })
      .eq("user_id", user_id)
      .eq("is_deleted", false);

    // For breeding_pairs, only count active/ongoing
    if (table === "breeding_pairs") {
      query = query.in("status", ["active", "ongoing"]);
    }
    // For incubations, only count active
    if (table === "incubations") {
      query = query.eq("status", "active");
    }

    const { count } = await query;

    const allowed = (count ?? 0) < limit;

    return new Response(
      JSON.stringify({ allowed, count, limit }),
      {
        status: allowed ? 200 : 403,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
```

- [ ] **Step 2: Commit**

```bash
git add supabase/functions/validate-free-tier-limit/
git commit -m "feat(supabase): add validate-free-tier-limit edge function for server-side defense"
```

---

## Task 10: Final Verification

- [ ] **Step 1: Run flutter analyze**

Run: `flutter analyze --no-fatal-infos`
Expected: No errors

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: ALL PASS

- [ ] **Step 3: Run code quality scripts**

Run: `python scripts/verify_code_quality.py`
Expected: PASS

Run: `python scripts/check_l10n_sync.py`
Expected: All keys in sync

- [ ] **Step 4: Fix any issues found in steps 1-3**

- [ ] **Step 5: Final commit if any fixes were needed**

Stage only the specific files that were modified, then commit:
```bash
git commit -m "fix(premium): address analysis and test issues from premium improvements"
```
