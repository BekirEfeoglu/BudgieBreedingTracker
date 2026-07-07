import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/constants/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('social and gamification feature flags match production rollout', () {
      expect(FeatureFlags.communityEnabled, isTrue);
      expect(FeatureFlags.marketplaceEnabled, isTrue);
      expect(FeatureFlags.messagingEnabled, isFalse);
      expect(FeatureFlags.gamificationEnabled, isTrue);
    });
  });
}
