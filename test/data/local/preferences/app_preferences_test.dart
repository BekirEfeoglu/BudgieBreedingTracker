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
