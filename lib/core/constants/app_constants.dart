import '../../bootstrap.dart';

abstract class AppConstants {
  static const String appName = 'BudgieBreedingTracker';
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl =
      'https://budgiebreedingtracker.online/privacy-policy.html';
  static const String termsOfUseUrl =
      'https://budgiebreedingtracker.online/terms-of-use.html';
  static const String supportUrl =
      'https://budgiebreedingtracker.online/support/';
  static const String communityGuidelinesUrl =
      'https://budgiebreedingtracker.online/community-guidelines.html';

  /// Apple App Store product page URL for "Write a Review" deep link.
  static const String appStoreUrl =
      'https://apps.apple.com/app/id6740091218?action=write-review';

  /// Google Play Store listing URL.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.budgiebreeding.tracker';
  static const List<String> supportedLanguages = ['tr', 'en', 'de'];
  static const String defaultLanguage = 'tr';
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxPhotosPerBird = 10;
  static const int maxEggsPerClutch = 12;
  static const int maxUploadSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int freeTierMaxBirds = 15;
  static const int freeTierMaxBreedingPairs = 5;
  static const int freeTierMaxActiveIncubations = 3;

  /// Ratio threshold for warning state (bird count approaching limit).
  static const double freeTierWarningRatio = 0.66;

  /// Ratio threshold for critical state (bird count very close to limit).
  static const double freeTierCriticalRatio = 0.93;

  static const int gracePeriodDays = 7;

  // Social Login Credentials — resolved at runtime from .env / BuildConfig / --dart-define.
  static String get googleWebClientId => googleWebClientIdResolved;
  static String get googleIosClientId => googleIosClientIdResolved;
}
