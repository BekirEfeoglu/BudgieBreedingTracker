abstract class AppConstants {
  static const String appName = 'BudgieBreedingTracker';
  static const String appVersion = '1.0.0';
  static const String privacyPolicyUrl =
      'https://budgiebreedingtracker.online/privacy-policy.html';
  static const String termsOfUseUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
  static const String supportUrl =
      'https://budgiebreedingtracker.online/support/';
  static const List<String> supportedLanguages = ['tr', 'en', 'de'];
  static const String defaultLanguage = 'tr';
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxPhotosPerBird = 10;
  static const int maxEggsPerClutch = 12;
  static const int maxUploadSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int freeTierMaxBirds = 15;
  static const int freeTierMaxBreedingPairs = 5;
  static const int freeTierMaxActiveIncubations = 3;

  // Social Login Credentials
  // TODO(User): Fill these with your actual Google Client IDs
  static const String googleWebClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
  static const String googleIosClientId = const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');
}
