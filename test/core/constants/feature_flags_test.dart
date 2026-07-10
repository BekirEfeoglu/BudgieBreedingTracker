import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/constants/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    test('social and gamification feature flags match production rollout', () {
      expect(FeatureFlags.communityEnabled, isTrue);
      expect(FeatureFlags.marketplaceEnabled, isTrue);
      // Enabled 2026-07-10 — the messaging feature is fully built and
      // server-ready; the community DM entry points dead-ended while it was off.
      expect(FeatureFlags.messagingEnabled, isTrue);
      expect(FeatureFlags.gamificationEnabled, isTrue);
    });
  });
}
