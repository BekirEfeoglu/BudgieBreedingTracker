import 'package:budgie_breeding_tracker/data/local/preferences/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppPreferences> _createPrefs(Map<String, Object> initialValues) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final raw = await SharedPreferences.getInstance();
  return AppPreferences(raw);
}

void main() {
  group('AppPreferences defaults', () {
    test(
      'returns expected default values when preferences are empty',
      () async {
        final prefs = await _createPrefs(const {});

        expect(prefs.themeMode, 'system');
        expect(prefs.language, 'tr');
        expect(prefs.notificationsEnabled, isTrue);
        expect(prefs.compactView, isFalse);
        expect(prefs.calendarViewMode, 'month');
        expect(prefs.autoSync, isTrue);
        expect(prefs.unitSystem, 'metric');
        expect(prefs.dateFormat, 'dmy');
        expect(prefs.defaultIncubationDays, 18);
        expect(prefs.defaultClutchSize, 6);
        expect(prefs.fontScale, 'normal');
        expect(prefs.imageQuality, 'high');
        expect(prefs.pedigreeDepth, 5);
        expect(prefs.lastSyncedAt, isNull);
      },
    );
  });

  group('AppPreferences persistence', () {
    test('persists and reads common values', () async {
      final prefs = await _createPrefs(const {});
      final syncTime = DateTime.utc(2026, 1, 5, 12, 30, 0);

      await prefs.setThemeMode('dark');
      await prefs.setLanguage('en');
      await prefs.setNotificationsEnabled(false);
      await prefs.setCompactView(true);
      await prefs.setLastSyncedAt(syncTime);

      expect(prefs.themeMode, 'dark');
      expect(prefs.language, 'en');
      expect(prefs.notificationsEnabled, isFalse);
      expect(prefs.compactView, isTrue);
      expect(prefs.lastSyncedAt, isNotNull);
      expect(prefs.lastSyncedAt!.isAtSameMomentAs(syncTime), isTrue);
    });

    test('returns null for invalid lastSyncedAt format', () async {
      final prefs = await _createPrefs({
        AppPreferences.keyLastSyncedAt: 'invalid-date',
      });

      expect(prefs.lastSyncedAt, isNull);
    });
  });

  group('AppPreferences pedigree depth', () {
    test('clamps read value into allowed range 3..8', () async {
      final tooLow = await _createPrefs({AppPreferences.keyPedigreeDepth: 1});
      final tooHigh = await _createPrefs({AppPreferences.keyPedigreeDepth: 42});

      expect(tooLow.pedigreeDepth, 3);
      expect(tooHigh.pedigreeDepth, 8);
    });

    test('clamps written value into allowed range 3..8', () async {
      final prefs = await _createPrefs(const {});

      await prefs.setPedigreeDepth(2);
      expect(prefs.pedigreeDepth, 3);
      expect(prefs.getInt(AppPreferences.keyPedigreeDepth), 3);

      await prefs.setPedigreeDepth(9);
      expect(prefs.pedigreeDepth, 8);
      expect(prefs.getInt(AppPreferences.keyPedigreeDepth), 8);
    });
  });

  group('AppPreferences defaults (extended)', () {
    test('returns expected boolean defaults when empty', () async {
      final prefs = await _createPrefs(const {});

      expect(prefs.onboardingComplete, isFalse);
      expect(prefs.rememberMe, isFalse);
      expect(prefs.hapticFeedback, isTrue);
      expect(prefs.reduceAnimations, isFalse);
      expect(prefs.autoDownloadImages, isTrue);
      expect(prefs.eggTurningReminder, isTrue);
      expect(prefs.temperatureAlert, isTrue);
    });

    test('returns expected string defaults when empty', () async {
      final prefs = await _createPrefs(const {});

      expect(prefs.chickSort, 'newest');
    });

    test('returns expected int defaults when empty', () async {
      final prefs = await _createPrefs(const {});

      expect(prefs.rewardGeneticsUsesRemaining, 0);
      expect(prefs.rewardExportUsesRemaining, 0);
    });

    test('returns null for DateTime defaults when empty', () async {
      final prefs = await _createPrefs(const {});

      expect(prefs.rewardStatisticsUnlockedAt, isNull);
      expect(prefs.lastSyncedAt, isNull);
    });

    test('returns empty list for blockedUserIds when empty', () async {
      final prefs = await _createPrefs(const {});

      expect(prefs.blockedUserIds, isEmpty);
    });
  });

  group('AppPreferences persistence (extended)', () {
    test('persists onboarding and rememberMe', () async {
      final prefs = await _createPrefs(const {});

      await prefs.setOnboardingComplete(true);
      await prefs.setRememberMe(true);

      expect(prefs.onboardingComplete, isTrue);
      expect(prefs.rememberMe, isTrue);
    });

    test('persists chick sort and calendar view mode', () async {
      final prefs = await _createPrefs(const {});

      await prefs.setChickSort('oldest');
      await prefs.setCalendarViewMode('week');

      expect(prefs.chickSort, 'oldest');
      expect(prefs.calendarViewMode, 'week');
    });

    test('persists auto sync and unit system', () async {
      final prefs = await _createPrefs(const {});

      await prefs.setAutoSync(false);
      await prefs.setUnitSystem('imperial');
      await prefs.setDateFormat('mdy');

      expect(prefs.autoSync, isFalse);
      expect(prefs.unitSystem, 'imperial');
      expect(prefs.dateFormat, 'mdy');
    });

    test('persists breeding defaults', () async {
      final prefs = await _createPrefs(const {});

      await prefs.setDefaultIncubationDays(21);
      await prefs.setDefaultClutchSize(8);

      expect(prefs.defaultIncubationDays, 21);
      expect(prefs.defaultClutchSize, 8);
    });

    test('persists accessibility settings', () async {
      final prefs = await _createPrefs(const {});

      await prefs.setHapticFeedback(false);
      await prefs.setReduceAnimations(true);
      await prefs.setFontScale('large');

      expect(prefs.hapticFeedback, isFalse);
      expect(prefs.reduceAnimations, isTrue);
      expect(prefs.fontScale, 'large');
    });

    test('persists photo and media settings', () async {
      final prefs = await _createPrefs(const {});

      await prefs.setImageQuality('low');
      await prefs.setAutoDownloadImages(false);

      expect(prefs.imageQuality, 'low');
      expect(prefs.autoDownloadImages, isFalse);
    });

    test('persists breeding alert settings', () async {
      final prefs = await _createPrefs(const {});

      await prefs.setEggTurningReminder(false);
      await prefs.setTemperatureAlert(false);

      expect(prefs.eggTurningReminder, isFalse);
      expect(prefs.temperatureAlert, isFalse);
    });

    test('persists ad reward values', () async {
      final prefs = await _createPrefs(const {});
      final unlockTime = DateTime.utc(2026, 3, 15, 14, 0);

      await prefs.setRewardStatisticsUnlockedAt(unlockTime);
      await prefs.setRewardGeneticsUsesRemaining(3);
      await prefs.setRewardExportUsesRemaining(5);

      expect(prefs.rewardStatisticsUnlockedAt, isNotNull);
      expect(
        prefs.rewardStatisticsUnlockedAt!.isAtSameMomentAs(unlockTime),
        isTrue,
      );
      expect(prefs.rewardGeneticsUsesRemaining, 3);
      expect(prefs.rewardExportUsesRemaining, 5);
    });

    test('returns null for invalid rewardStatisticsUnlockedAt format',
        () async {
      final prefs = await _createPrefs({
        AppPreferences.keyRewardStatisticsUnlockedAt: 'not-a-date',
      });

      expect(prefs.rewardStatisticsUnlockedAt, isNull);
    });
  });

  group('AppPreferences blocked users', () {
    test('addBlockedUser adds a user ID', () async {
      final prefs = await _createPrefs(const {});

      await prefs.addBlockedUser('user-1');

      expect(prefs.blockedUserIds, ['user-1']);
      expect(prefs.isUserBlocked('user-1'), isTrue);
    });

    test('addBlockedUser does not add duplicate', () async {
      final prefs = await _createPrefs(const {});

      await prefs.addBlockedUser('user-1');
      await prefs.addBlockedUser('user-1');

      expect(prefs.blockedUserIds, hasLength(1));
    });

    test('addBlockedUser accumulates multiple users', () async {
      final prefs = await _createPrefs(const {});

      await prefs.addBlockedUser('user-1');
      await prefs.addBlockedUser('user-2');
      await prefs.addBlockedUser('user-3');

      expect(prefs.blockedUserIds, hasLength(3));
      expect(prefs.isUserBlocked('user-1'), isTrue);
      expect(prefs.isUserBlocked('user-2'), isTrue);
      expect(prefs.isUserBlocked('user-3'), isTrue);
    });

    test('removeBlockedUser removes a user ID', () async {
      final prefs = await _createPrefs(const {});

      await prefs.addBlockedUser('user-1');
      await prefs.addBlockedUser('user-2');
      await prefs.removeBlockedUser('user-1');

      expect(prefs.blockedUserIds, ['user-2']);
      expect(prefs.isUserBlocked('user-1'), isFalse);
      expect(prefs.isUserBlocked('user-2'), isTrue);
    });

    test('isUserBlocked returns false for non-blocked user', () async {
      final prefs = await _createPrefs(const {});

      expect(prefs.isUserBlocked('user-999'), isFalse);
    });

    test('persists blocked users from initial values', () async {
      final prefs = await _createPrefs({
        AppPreferences.keyBlockedUserIds: ['user-a', 'user-b'],
      });

      expect(prefs.blockedUserIds, ['user-a', 'user-b']);
      expect(prefs.isUserBlocked('user-a'), isTrue);
    });
  });

  group('AppPreferences key constants', () {
    test('all key constants are non-empty', () {
      final keys = [
        AppPreferences.keyThemeMode,
        AppPreferences.keyLanguage,
        AppPreferences.keyNotificationsEnabled,
        AppPreferences.keyCompactView,
        AppPreferences.keyLastSyncedAt,
        AppPreferences.keyOnboardingComplete,
        AppPreferences.keyRememberMe,
        AppPreferences.keyChickSort,
        AppPreferences.keyCalendarViewMode,
        AppPreferences.keyAutoSync,
        AppPreferences.keyUnitSystem,
        AppPreferences.keyDateFormat,
        AppPreferences.keyDefaultIncubationDays,
        AppPreferences.keyDefaultClutchSize,
        AppPreferences.keyHapticFeedback,
        AppPreferences.keyReduceAnimations,
        AppPreferences.keyFontScale,
        AppPreferences.keyImageQuality,
        AppPreferences.keyAutoDownloadImages,
        AppPreferences.keyEggTurningReminder,
        AppPreferences.keyTemperatureAlert,
        AppPreferences.keyLastReconciledAt,
        AppPreferences.keyPedigreeDepth,
        AppPreferences.keyWifiOnlySync,
        AppPreferences.keyRewardStatisticsUnlockedAt,
        AppPreferences.keyRewardGeneticsUses,
        AppPreferences.keyRewardExportUses,
        AppPreferences.keyBlockedUserIds,
      ];

      for (final key in keys) {
        expect(key, isNotEmpty, reason: 'Key constant must not be empty');
      }
    });

    test('all key constants have pref_ prefix', () {
      final keys = [
        AppPreferences.keyThemeMode,
        AppPreferences.keyLanguage,
        AppPreferences.keyNotificationsEnabled,
        AppPreferences.keyCompactView,
        AppPreferences.keyLastSyncedAt,
        AppPreferences.keyOnboardingComplete,
        AppPreferences.keyRememberMe,
        AppPreferences.keyChickSort,
        AppPreferences.keyCalendarViewMode,
        AppPreferences.keyAutoSync,
        AppPreferences.keyUnitSystem,
        AppPreferences.keyDateFormat,
        AppPreferences.keyDefaultIncubationDays,
        AppPreferences.keyDefaultClutchSize,
        AppPreferences.keyHapticFeedback,
        AppPreferences.keyReduceAnimations,
        AppPreferences.keyFontScale,
        AppPreferences.keyImageQuality,
        AppPreferences.keyAutoDownloadImages,
        AppPreferences.keyEggTurningReminder,
        AppPreferences.keyTemperatureAlert,
        AppPreferences.keyLastReconciledAt,
        AppPreferences.keyPedigreeDepth,
        AppPreferences.keyWifiOnlySync,
        AppPreferences.keyRewardStatisticsUnlockedAt,
        AppPreferences.keyRewardGeneticsUses,
        AppPreferences.keyRewardExportUses,
        AppPreferences.keyBlockedUserIds,
      ];

      for (final key in keys) {
        expect(key.startsWith('pref_'), isTrue,
            reason: '"$key" should start with pref_');
      }
    });

    test('key constants are unique', () {
      final keys = [
        AppPreferences.keyThemeMode,
        AppPreferences.keyLanguage,
        AppPreferences.keyNotificationsEnabled,
        AppPreferences.keyCompactView,
        AppPreferences.keyLastSyncedAt,
        AppPreferences.keyOnboardingComplete,
        AppPreferences.keyRememberMe,
        AppPreferences.keyChickSort,
        AppPreferences.keyCalendarViewMode,
        AppPreferences.keyAutoSync,
        AppPreferences.keyUnitSystem,
        AppPreferences.keyDateFormat,
        AppPreferences.keyDefaultIncubationDays,
        AppPreferences.keyDefaultClutchSize,
        AppPreferences.keyHapticFeedback,
        AppPreferences.keyReduceAnimations,
        AppPreferences.keyFontScale,
        AppPreferences.keyImageQuality,
        AppPreferences.keyAutoDownloadImages,
        AppPreferences.keyEggTurningReminder,
        AppPreferences.keyTemperatureAlert,
        AppPreferences.keyLastReconciledAt,
        AppPreferences.keyPedigreeDepth,
        AppPreferences.keyWifiOnlySync,
        AppPreferences.keyRewardStatisticsUnlockedAt,
        AppPreferences.keyRewardGeneticsUses,
        AppPreferences.keyRewardExportUses,
        AppPreferences.keyBlockedUserIds,
      ];

      expect(keys.toSet().length, keys.length,
          reason: 'All key constants must be unique');
    });
  });

  group('AppPreferences generic access', () {
    test('supports get/set/remove/clear helpers', () async {
      final prefs = await _createPrefs(const {});

      await prefs.setString('k_string', 'value');
      await prefs.setBool('k_bool', true);
      await prefs.setInt('k_int', 7);

      expect(prefs.getString('k_string'), 'value');
      expect(prefs.getBool('k_bool'), isTrue);
      expect(prefs.getInt('k_int'), 7);

      await prefs.remove('k_string');
      expect(prefs.getString('k_string'), isNull);

      await prefs.clear();
      expect(prefs.getBool('k_bool'), isNull);
      expect(prefs.getInt('k_int'), isNull);
    });
  });
}
