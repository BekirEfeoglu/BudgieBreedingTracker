import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/app_database.dart';
import 'package:budgie_breeding_tracker/data/local/database/mappers/profile_mapper.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';

void main() {
  group('ProfileRowMapper.toModel()', () {
    test('maps all fields correctly', () {
      final premiumExpiry = DateTime.utc(2025, 12, 31);
      final row = ProfileRow(
        id: 'u1',
        email: 'test@example.com',
        isPremium: true,
        subscriptionStatus: SubscriptionStatus.premium,
        fullName: 'John Doe',
        avatarUrl: 'https://example.com/avatar.jpg',
        role: 'admin',
        language: 'en',
        premiumExpiresAt: premiumExpiry,
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 6, 1),
      );
      final model = row.toModel();

      expect(model.id, 'u1');
      expect(model.email, 'test@example.com');
      expect(model.isPremium, true);
      expect(model.subscriptionStatus, SubscriptionStatus.premium);
      expect(model.fullName, 'John Doe');
      expect(model.avatarUrl, 'https://example.com/avatar.jpg');
      expect(model.role, 'admin');
      expect(model.language, 'en');
      expect(model.premiumExpiresAt, premiumExpiry);
    });

    test('handles null optional fields', () {
      const row = ProfileRow(
        id: 'u2',
        email: 'free@example.com',
        isPremium: false,
        subscriptionStatus: SubscriptionStatus.free,
        fullName: null,
        avatarUrl: null,
        role: null,
        language: null,
        premiumExpiresAt: null,
      );
      final model = row.toModel();

      expect(model.fullName, isNull);
      expect(model.avatarUrl, isNull);
      expect(model.role, isNull);
      expect(model.language, isNull);
      expect(model.premiumExpiresAt, isNull);
      expect(model.isPremium, false);
    });
  });

  group('ProfileModelMapper.toCompanion()', () {
    test('wraps all fields in Value', () {
      final model = Profile(
        id: 'u1',
        email: 'user@example.com',
        isPremium: true,
        subscriptionStatus: SubscriptionStatus.trial,
        fullName: 'Jane Smith',
        avatarUrl: 'https://example.com/jane.png',
        role: 'user',
        language: 'de',
        premiumExpiresAt: DateTime.utc(2025, 6, 30),
      );
      final companion = model.toCompanion();

      expect(companion.id.value, 'u1');
      expect(companion.email.value, 'user@example.com');
      expect(companion.isPremium.value, true);
      expect(companion.subscriptionStatus.value, SubscriptionStatus.trial);
      expect(companion.fullName.value, 'Jane Smith');
      expect(companion.avatarUrl.value, 'https://example.com/jane.png');
      expect(companion.role.value, 'user');
      expect(companion.language.value, 'de');
    });

    test('sets updatedAt to current time', () {
      final before = DateTime.now();
      const model = Profile(id: 'u1', email: 'test@test.com');
      final companion = model.toCompanion();

      expect(
        companion.updatedAt.value!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
