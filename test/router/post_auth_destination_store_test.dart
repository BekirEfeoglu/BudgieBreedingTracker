import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/router/post_auth_destination_store.dart';

void main() {
  group('SharedPreferencesPostAuthDestinationStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('persists and consumes a validated destination once', () async {
      final store = SharedPreferencesPostAuthDestinationStore();

      await store.save('/birds/123?tab=health');

      expect(await store.take(), '/birds/123?tab=health');
      expect(await store.take(), isNull);
    });

    test('does not persist an external destination', () async {
      final store = SharedPreferencesPostAuthDestinationStore();

      await store.save('https://evil.example/phish');

      expect(await store.take(), isNull);
    });

    test('clear removes a pending destination', () async {
      final store = SharedPreferencesPostAuthDestinationStore();
      await store.save('/settings');

      await store.clear();

      expect(await store.take(), isNull);
    });
  });
}
