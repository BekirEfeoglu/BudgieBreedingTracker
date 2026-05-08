import 'package:budgie_breeding_tracker/data/models/app_version_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppVersion', () {
    test('fromJson parses ios row', () {
      final json = <String, dynamic>{
        'platform': 'ios',
        'latest_version': '1.0.4',
        'latest_build': 18,
        'min_supported_build': 10,
        'store_url': 'https://apps.apple.com/app/id6759828211',
        'release_notes_tr': 'Hata duzeltmeleri',
        'release_notes_en': 'Bug fixes',
        'release_notes_de': null,
      };

      final model = AppVersion.fromJson(json);

      expect(model.platform, 'ios');
      expect(model.latestVersion, '1.0.4');
      expect(model.latestBuild, 18);
      expect(model.minSupportedBuild, 10);
      expect(model.storeUrl, isNotEmpty);
      expect(model.releaseNotesTr, 'Hata duzeltmeleri');
      expect(model.releaseNotesDe, isNull);
    });

    test('releaseNotesFor returns localized text or fallback', () {
      const model = AppVersion(
        platform: 'ios',
        latestVersion: '1.0.4',
        latestBuild: 18,
        minSupportedBuild: 10,
        storeUrl: 'https://example.com',
        releaseNotesTr: 'TR notes',
        releaseNotesEn: 'EN notes',
      );

      expect(model.releaseNotesFor('tr'), 'TR notes');
      expect(model.releaseNotesFor('en'), 'EN notes');
      expect(model.releaseNotesFor('de'), 'EN notes');
      expect(model.releaseNotesFor('fr'), 'EN notes');
    });
  });
}
