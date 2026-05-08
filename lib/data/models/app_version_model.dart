import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version_model.freezed.dart';
part 'app_version_model.g.dart';

@freezed
abstract class AppVersion with _$AppVersion {
  const AppVersion._();

  const factory AppVersion({
    required String platform,
    required String latestVersion,
    required int latestBuild,
    required int minSupportedBuild,
    required String storeUrl,
    String? releaseNotesTr,
    String? releaseNotesEn,
    String? releaseNotesDe,
    DateTime? updatedAt,
  }) = _AppVersion;

  factory AppVersion.fromJson(Map<String, dynamic> json) =>
      _$AppVersionFromJson(json);

  /// Returns release notes for the given locale code, falling back to English.
  String? releaseNotesFor(String localeCode) {
    switch (localeCode) {
      case 'tr':
        return releaseNotesTr;
      case 'de':
        return releaseNotesDe;
      case 'en':
        return releaseNotesEn;
      default:
        return releaseNotesEn;
    }
  }
}
