import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';

void main() {
  group('AppConstants — app metadata', () {
    test('appName is non-empty', () {
      expect(AppConstants.appName, isNotEmpty);
    });

    test('appName is BudgieBreedingTracker', () {
      expect(AppConstants.appName, 'BudgieBreedingTracker');
    });

    test('appVersion follows semver format', () {
      expect(
        RegExp(r'^\d+\.\d+\.\d+').hasMatch(AppConstants.appVersion),
        isTrue,
        reason: 'appVersion should follow semver (e.g., 1.0.0)',
      );
    });

    test('appVersion is 1.0.2', () {
      expect(AppConstants.appVersion, '1.0.2');
    });
  });

  group('AppConstants — URLs', () {
    test('privacyPolicyUrl is a valid https URL', () {
      expect(AppConstants.privacyPolicyUrl, startsWith('https://'));
      expect(
        Uri.tryParse(AppConstants.privacyPolicyUrl),
        isNotNull,
        reason: 'privacyPolicyUrl should be a valid URI',
      );
    });

    test('termsOfUseUrl is a valid https URL', () {
      expect(AppConstants.termsOfUseUrl, startsWith('https://'));
      expect(
        Uri.tryParse(AppConstants.termsOfUseUrl),
        isNotNull,
      );
    });

    test('supportUrl is a valid https URL', () {
      expect(AppConstants.supportUrl, startsWith('https://'));
      expect(
        Uri.tryParse(AppConstants.supportUrl),
        isNotNull,
      );
    });

    test('communityGuidelinesUrl is a valid https URL', () {
      expect(AppConstants.communityGuidelinesUrl, startsWith('https://'));
      expect(
        Uri.tryParse(AppConstants.communityGuidelinesUrl),
        isNotNull,
      );
    });

    test('appStoreUrl is a valid https URL', () {
      expect(AppConstants.appStoreUrl, startsWith('https://'));
      expect(
        Uri.tryParse(AppConstants.appStoreUrl),
        isNotNull,
      );
    });

    test('playStoreUrl is a valid https URL', () {
      expect(AppConstants.playStoreUrl, startsWith('https://'));
      expect(
        Uri.tryParse(AppConstants.playStoreUrl),
        isNotNull,
      );
    });

    test('appStoreUrl contains Apple domain', () {
      expect(AppConstants.appStoreUrl, contains(l10n('apple.com')));
    });

    test('playStoreUrl contains Google domain', () {
      expect(AppConstants.playStoreUrl, contains(l10n('google.com')));
    });
  });

  group('AppConstants — localization', () {
    test('supportedLanguages contains tr, en, de', () {
      expect(AppConstants.supportedLanguages, containsAll(['tr', 'en', 'de']));
    });

    test('supportedLanguages has exactly 3 languages', () {
      expect(AppConstants.supportedLanguages.length, 3);
    });

    test('defaultLanguage is tr', () {
      expect(AppConstants.defaultLanguage, 'tr');
    });

    test('defaultLanguage is in supportedLanguages', () {
      expect(
        AppConstants.supportedLanguages,
        contains(AppConstants.defaultLanguage),
      );
    });
  });

  group('AppConstants — sync', () {
    test('syncInterval is 15 minutes', () {
      expect(AppConstants.syncInterval, const Duration(minutes: 15));
    });

    test('syncInterval is positive', () {
      expect(AppConstants.syncInterval.inSeconds, greaterThan(0));
    });
  });

  group('AppConstants — entity limits', () {
    test('maxPhotosPerBird is 10', () {
      expect(AppConstants.maxPhotosPerBird, 10);
    });

    test('maxEggsPerClutch is 12', () {
      expect(AppConstants.maxEggsPerClutch, 12);
    });

    test('maxPhotosPerBird is positive', () {
      expect(AppConstants.maxPhotosPerBird, greaterThan(0));
    });

    test('maxEggsPerClutch is positive', () {
      expect(AppConstants.maxEggsPerClutch, greaterThan(0));
    });

    test('maxEggsPerClutch is reasonable for budgies (4-12 typical)', () {
      expect(AppConstants.maxEggsPerClutch, greaterThanOrEqualTo(4));
      expect(AppConstants.maxEggsPerClutch, lessThanOrEqualTo(20));
    });
  });

  group('AppConstants — upload limits', () {
    test('maxUploadSizeBytes is 10 MB', () {
      expect(AppConstants.maxUploadSizeBytes, 10 * 1024 * 1024);
    });

    test('maxUploadSizeBytes is positive', () {
      expect(AppConstants.maxUploadSizeBytes, greaterThan(0));
    });
  });

  group('AppConstants — free tier limits', () {
    test('freeTierMaxBirds is 15', () {
      expect(AppConstants.freeTierMaxBirds, 15);
    });

    test('freeTierMaxBreedingPairs is 5', () {
      expect(AppConstants.freeTierMaxBreedingPairs, 5);
    });

    test('freeTierMaxActiveIncubations is 3', () {
      expect(AppConstants.freeTierMaxActiveIncubations, 3);
    });

    test('free tier limits are positive', () {
      expect(AppConstants.freeTierMaxBirds, greaterThan(0));
      expect(AppConstants.freeTierMaxBreedingPairs, greaterThan(0));
      expect(AppConstants.freeTierMaxActiveIncubations, greaterThan(0));
    });

    test('freeTierMaxBirds > freeTierMaxBreedingPairs', () {
      expect(
        AppConstants.freeTierMaxBirds,
        greaterThan(AppConstants.freeTierMaxBreedingPairs),
        reason: 'Should allow more birds than breeding pairs',
      );
    });
  });

  group('AppConstants — social login credentials', () {
    test('googleWebClientId getter does not throw', () {
      // In test env these will be empty strings (no --dart-define)
      expect(() => AppConstants.googleWebClientId, returnsNormally);
    });

    test('googleIosClientId getter does not throw', () {
      expect(() => AppConstants.googleIosClientId, returnsNormally);
    });
  });
}
