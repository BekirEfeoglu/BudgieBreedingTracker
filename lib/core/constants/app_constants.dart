abstract class AppConstants {
  static const String appName = 'BudgieBreedingTracker';
  static const String appVersion = '1.0.0';
  static const List<String> supportedLanguages = ['tr', 'en', 'de'];
  static const String defaultLanguage = 'tr';
  static const Duration syncInterval = Duration(minutes: 15);
  static const int maxPhotosPerBird = 10;
  static const int maxEggsPerClutch = 12;
  static const int maxUploadSizeBytes = 10 * 1024 * 1024; // 10 MB
  static const int freeTierMaxBirds = 15;
  static const int freeTierMaxBreedingPairs = 5;
  static const int freeTierMaxActiveIncubations = 3;
}
