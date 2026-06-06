import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/app_update/app_update_info.dart';

void main() {
  group('AppUpdateInfo', () {
    test('platforma gore system_settings degerini parse eder', () {
      final info = AppUpdateInfo.fromSettingValue({
        'ios': {
          'latest_version': '1.0.6',
          'latest_build': 20,
          'min_supported_build': 19,
          'store_url': 'https://apps.apple.com/app/id6759828211',
          'release_notes_tr': 'Yeni surum hazir',
        },
      }, platform: 'ios');

      expect(info, isNotNull);
      expect(info!.latestVersion, '1.0.6');
      expect(info.latestBuild, 20);
      expect(info.minSupportedBuild, 19);
      expect(info.releaseNotesTr, 'Yeni surum hazir');
    });

    test('current build min supported altindaysa zorunlu guncelleme ister', () {
      const info = AppUpdateInfo(
        latestVersion: '1.0.6',
        latestBuild: 20,
        minSupportedBuild: 19,
        storeUrl: 'https://apps.apple.com/app/id6759828211',
      );

      final status = info.evaluate(currentVersion: '1.0.5', currentBuild: 18);

      expect(status.isUpdateAvailable, isTrue);
      expect(status.isRequired, isTrue);
    });

    test(
      'latest build current buildden buyukse opsiyonel guncelleme ister',
      () {
        const info = AppUpdateInfo(
          latestVersion: '1.0.6',
          latestBuild: 20,
          minSupportedBuild: 18,
          storeUrl: 'https://apps.apple.com/app/id6759828211',
        );

        final status = info.evaluate(currentVersion: '1.0.5', currentBuild: 19);

        expect(status.isUpdateAvailable, isTrue);
        expect(status.isRequired, isFalse);
      },
    );

    test('opsiyonel guncelleme Android store bildirimi icin gorunur kalir', () {
      const info = AppUpdateInfo(
        latestVersion: '1.1.2',
        latestBuild: 33,
        minSupportedBuild: 0,
        storeUrl:
            'https://play.google.com/store/apps/details?id=com.budgiebreeding.budgie_breeding_tracker',
      );

      final status = info.evaluate(currentVersion: '1.1.1', currentBuild: 32);
      final visible = visibleAppUpdateStatus(status);

      expect(visible, isNotNull);
      expect(visible!.isUpdateAvailable, isTrue);
      expect(visible.isRequired, isFalse);
    });

    test(
      'App Store surumu Supabase latest degerinden yeniyse onu kullanir',
      () {
        final info = resolveAppUpdateInfo(
          settingValue: {
            'ios': {
              'latest_version': '1.0.5',
              'latest_build': 19,
              'min_supported_build': 18,
              'store_url': 'https://apps.apple.com/app/id6759828211',
            },
          },
          appStoreListing: const AppStoreListing(
            version: '1.0.6',
            storeUrl: 'https://apps.apple.com/tr/app/id6759828211',
          ),
          platform: 'ios',
          defaultStoreUrl: 'https://apps.apple.com/app/id6759828211',
        );

        expect(info, isNotNull);
        expect(info!.latestVersion, '1.0.6');
        expect(info.latestBuild, 0);
        expect(info.minSupportedBuild, 18);
        expect(info.storeUrl, 'https://apps.apple.com/tr/app/id6759828211');
      },
    );

    test(
      'App Store henuz Supabase latest surumune ulasmadiysa iOS uyarisi store surumune kilitlenir',
      () {
        final info = resolveAppUpdateInfo(
          settingValue: {
            'ios': {
              'latest_version': '1.1.2',
              'latest_build': 33,
              'min_supported_build': 33,
              'store_url': 'https://apps.apple.com/app/id6759828211',
            },
          },
          appStoreListing: const AppStoreListing(
            version: '1.1.1',
            storeUrl:
                'https://apps.apple.com/tr/app/budgie-breeding-tracker/id6759828211',
          ),
          platform: 'ios',
          defaultStoreUrl: 'https://apps.apple.com/app/id6759828211',
        );

        expect(info, isNotNull);
        expect(info!.latestVersion, '1.1.1');
        expect(info.latestBuild, 0);
        expect(info.minSupportedBuild, 0);
        expect(
          info.storeUrl,
          'https://apps.apple.com/tr/app/budgie-breeding-tracker/id6759828211',
        );
      },
    );
  });
}
