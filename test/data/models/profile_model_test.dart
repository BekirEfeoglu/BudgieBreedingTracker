import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';

Profile _buildProfile({
  String id = 'user-1',
  String email = 'user@example.com',
  bool isPremium = false,
  SubscriptionStatus subscriptionStatus = SubscriptionStatus.free,
  String? fullName,
  String? avatarUrl,
  String? role,
  String? language,
  DateTime? premiumExpiresAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Profile(
    id: id,
    email: email,
    isPremium: isPremium,
    subscriptionStatus: subscriptionStatus,
    fullName: fullName,
    avatarUrl: avatarUrl,
    role: role,
    language: language,
    premiumExpiresAt: premiumExpiresAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('Profile model', () {
    group('fromJson / toJson', () {
      test('round-trips correctly with all fields', () {
        final profile = _buildProfile(
          id: 'user-42',
          email: 'admin@example.com',
          isPremium: true,
          subscriptionStatus: SubscriptionStatus.premium,
          fullName: 'Admin User',
          avatarUrl: 'https://example.com/avatar.png',
          role: 'admin',
          language: 'en',
          premiumExpiresAt: DateTime(2025, 1, 1),
          createdAt: DateTime(2024, 1, 1, 8, 0),
          updatedAt: DateTime(2024, 1, 2, 8, 0),
        );

        final restored = Profile.fromJson(profile.toJson());
        expect(restored, profile);
      });

      test('applies defaults for premium flags', () {
        final profile = Profile.fromJson({
          'id': 'user-1',
          'email': 'user@example.com',
        });

        expect(profile.isPremium, isFalse);
        expect(profile.subscriptionStatus, SubscriptionStatus.free);
      });

      test('falls back to free on unknown subscription status', () {
        final profile = Profile.fromJson({
          'id': 'user-1',
          'email': 'user@example.com',
          'subscription_status': 'not-real',
        });

        expect(profile.subscriptionStatus, SubscriptionStatus.free);
      });
    });

    group('copyWith', () {
      test('updates selected fields', () {
        final profile = _buildProfile(fullName: 'Old Name', language: 'tr');
        final updated = profile.copyWith(fullName: 'New Name', language: 'de');

        expect(updated.fullName, 'New Name');
        expect(updated.language, 'de');
        expect(updated.id, profile.id);
        expect(updated.email, profile.email);
      });
    });
  });

  group('ProfileX extension', () {
    test('isAdmin and isFounder depend on role', () {
      final admin = _buildProfile(role: 'admin');
      final founder = _buildProfile(role: 'founder');
      final user = _buildProfile(role: 'user');

      expect(admin.isAdmin, isTrue);
      expect(admin.isFounder, isFalse);
      expect(founder.isFounder, isTrue);
      expect(user.isAdmin, isFalse);
      expect(user.isFounder, isFalse);
    });

    test('hasPremium is true for premium/trial or isPremium flag', () {
      final byFlag = _buildProfile(isPremium: true);
      final byPremiumStatus = _buildProfile(
        isPremium: false,
        subscriptionStatus: SubscriptionStatus.premium,
      );
      final byTrialStatus = _buildProfile(
        isPremium: false,
        subscriptionStatus: SubscriptionStatus.trial,
      );
      final free = _buildProfile(
        isPremium: false,
        subscriptionStatus: SubscriptionStatus.free,
      );

      expect(byFlag.hasPremium, isTrue);
      expect(byPremiumStatus.hasPremium, isTrue);
      expect(byTrialStatus.hasPremium, isTrue);
      expect(free.hasPremium, isFalse);
    });

    test('resolvedDisplayName returns fullName or email prefix', () {
      final withName = _buildProfile(fullName: 'Display Name');
      final noName = _buildProfile(email: 'prefix@example.com', fullName: null);

      expect(withName.resolvedDisplayName, 'Display Name');
      expect(noName.resolvedDisplayName, 'prefix');
    });
  });
}
