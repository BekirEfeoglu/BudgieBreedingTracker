import 'package:budgie_breeding_tracker/core/enums/update_status.dart';
import 'package:budgie_breeding_tracker/data/models/app_version_model.dart';
import 'package:budgie_breeding_tracker/domain/services/update_check/update_check_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const remote = AppVersion(
    platform: 'ios',
    latestVersion: '1.0.4',
    latestBuild: 18,
    minSupportedBuild: 10,
    storeUrl: 'https://example.com',
  );

  group('UpdateCheckService.compare', () {
    test('returns none when local build equals latest', () {
      expect(
        UpdateCheckService.compare(currentBuild: 18, remote: remote),
        UpdateStatus.none,
      );
    });

    test('returns none when local build exceeds latest', () {
      expect(
        UpdateCheckService.compare(currentBuild: 20, remote: remote),
        UpdateStatus.none,
      );
    });

    test('returns optional when below latest but >= min_supported', () {
      expect(
        UpdateCheckService.compare(currentBuild: 15, remote: remote),
        UpdateStatus.optional,
      );
      expect(
        UpdateCheckService.compare(currentBuild: 10, remote: remote),
        UpdateStatus.optional,
      );
    });

    test('returns forced when below min_supported', () {
      expect(
        UpdateCheckService.compare(currentBuild: 9, remote: remote),
        UpdateStatus.forced,
      );
      expect(
        UpdateCheckService.compare(currentBuild: 1, remote: remote),
        UpdateStatus.forced,
      );
    });

    test('returns none when remote is null (fail-open)', () {
      expect(
        UpdateCheckService.compare(currentBuild: 5, remote: null),
        UpdateStatus.none,
      );
    });
  });
}
