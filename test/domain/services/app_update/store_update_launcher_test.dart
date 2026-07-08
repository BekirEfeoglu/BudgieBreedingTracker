import 'package:budgie_breeding_tracker/domain/services/app_update/store_update_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoreUpdateLauncher', () {
    test('opens iOS App Store product sheet before URL fallback', () async {
      final calls = <Map<String, Object?>>[];
      var fallbackCalled = false;
      final launcher = StoreUpdateLauncher(
        platform: StoreUpdatePlatform.ios,
        invokeMethod: <T>(method, arguments) async {
          calls.add({'method': method, 'arguments': arguments});
          return true as T;
        },
        launchExternal: (_) async {
          fallbackCalled = true;
          return true;
        },
      );

      final opened = await launcher.openStore(
        'https://apps.apple.com/tr/app/budgie-breeding-tracker/id6759828211',
      );

      expect(opened, isTrue);
      expect(calls, [
        {
          'method': 'openAppStoreProduct',
          'arguments': {'appId': '6759828211'},
        },
      ]);
      expect(fallbackCalled, isFalse);
    });

    test('falls back to external URL when iOS product sheet fails', () async {
      var fallbackUri = '';
      final launcher = StoreUpdateLauncher(
        platform: StoreUpdatePlatform.ios,
        invokeMethod: <T>(method, arguments) async => false as T,
        launchExternal: (uri) async {
          fallbackUri = uri.toString();
          return true;
        },
      );

      final opened = await launcher.openStore(
        'https://apps.apple.com/app/id6759828211',
      );

      expect(opened, isTrue);
      expect(fallbackUri, 'https://apps.apple.com/app/id6759828211');
    });

    test('opens Play Store package with native Android channel first', () async {
      final calls = <Map<String, Object?>>[];
      final launcher = StoreUpdateLauncher(
        platform: StoreUpdatePlatform.android,
        invokeMethod: <T>(method, arguments) async {
          calls.add({'method': method, 'arguments': arguments});
          return true as T;
        },
        launchExternal: (_) async => false,
      );

      final opened = await launcher.openStore(
        'https://play.google.com/store/apps/details?id=com.budgiebreeding.budgie_breeding_tracker',
      );

      expect(opened, isTrue);
      expect(calls, [
        {
          'method': 'openPlayStore',
          'arguments': {
            'url':
                'https://play.google.com/store/apps/details?id=com.budgiebreeding.budgie_breeding_tracker',
            'packageName': 'com.budgiebreeding.budgie_breeding_tracker',
          },
        },
      ]);
    });

    test('returns false for invalid URL', () async {
      final launcher = StoreUpdateLauncher(
        platform: StoreUpdatePlatform.other,
        invokeMethod: <T>(method, arguments) async => true as T,
        launchExternal: (_) async => true,
      );

      expect(await launcher.openStore('not a url'), isFalse);
    });
  });
}
