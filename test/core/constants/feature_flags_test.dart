import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/constants/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('all social features are disabled by default', () {
      expect(FeatureFlags.communityEnabled, isFalse);
      expect(FeatureFlags.marketplaceEnabled, isFalse);
      expect(FeatureFlags.messagingEnabled, isFalse);
      expect(FeatureFlags.gamificationEnabled, isFalse);
    });
  });
}
