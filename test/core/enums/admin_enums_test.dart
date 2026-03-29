import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/admin_enums.dart';

void main() {
  group('AlertSeverity', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in AlertSeverity.values) {
        expect(AlertSeverity.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(AlertSeverity.fromJson('invalid'), AlertSeverity.unknown);
      expect(AlertSeverity.fromJson(''), AlertSeverity.unknown);
      expect(AlertSeverity.fromJson('CRITICAL'), AlertSeverity.unknown);
    });

    test('has expected value count', () {
      expect(AlertSeverity.values.length, 4);
    });
  });

  group('SecuritySeverityLevel', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in SecuritySeverityLevel.values) {
        expect(SecuritySeverityLevel.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(
        SecuritySeverityLevel.fromJson('invalid'),
        SecuritySeverityLevel.unknown,
      );
      expect(SecuritySeverityLevel.fromJson(''), SecuritySeverityLevel.unknown);
    });

    test('has expected value count', () {
      expect(SecuritySeverityLevel.values.length, 4);
    });
  });

  group('AdminRole', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in AdminRole.values) {
        expect(AdminRole.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(AdminRole.fromJson('admin'), AdminRole.unknown);
      expect(AdminRole.fromJson('superadmin'), AdminRole.unknown);
      expect(AdminRole.fromJson(''), AdminRole.unknown);
    });

    test('has expected value count', () {
      expect(AdminRole.values.length, 3);
    });
  });

  group('FeedbackStatus', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in FeedbackStatus.values) {
        expect(FeedbackStatus.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(FeedbackStatus.fromJson('closed'), FeedbackStatus.unknown);
      expect(FeedbackStatus.fromJson(''), FeedbackStatus.unknown);
    });

    test('has expected value count', () {
      expect(FeedbackStatus.values.length, 4);
    });
  });

  group('AdminActionType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in AdminActionType.values) {
        if (value == AdminActionType.unknown) continue;
        expect(AdminActionType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(
        AdminActionType.fromJson('nonexistent_action'),
        AdminActionType.unknown,
      );
    });

    test('fromJson handles snake_case action strings', () {
      expect(AdminActionType.fromJson('delete_user'), AdminActionType.delete);
      expect(AdminActionType.fromJson('create_bird'), AdminActionType.create);
      expect(AdminActionType.fromJson('grant_premium'), AdminActionType.grantPremium);
      expect(AdminActionType.fromJson('toggle_active'), AdminActionType.toggleActive);
    });
  });

  group('SecurityEventType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in SecurityEventType.values) {
        if (value == SecurityEventType.unknown) continue;
        expect(SecurityEventType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(SecurityEventType.fromJson('xyz'), SecurityEventType.unknown);
    });

    test('fromJson handles keyword matching', () {
      expect(
        SecurityEventType.fromJson('login_failed'),
        SecurityEventType.failedLogin,
      );
      expect(
        SecurityEventType.fromJson('suspicious_activity'),
        SecurityEventType.suspiciousActivity,
      );
      expect(
        SecurityEventType.fromJson('rate_limited'),
        SecurityEventType.rateLimited,
      );
    });

    test('inferredSeverity returns correct levels', () {
      expect(
        SecurityEventType.bruteForce.inferredSeverity,
        SecuritySeverityLevel.high,
      );
      expect(
        SecurityEventType.unauthorizedAccess.inferredSeverity,
        SecuritySeverityLevel.high,
      );
      expect(
        SecurityEventType.suspiciousActivity.inferredSeverity,
        SecuritySeverityLevel.medium,
      );
      expect(
        SecurityEventType.failedLogin.inferredSeverity,
        SecuritySeverityLevel.low,
      );
      expect(
        SecurityEventType.unknown.inferredSeverity,
        SecuritySeverityLevel.unknown,
      );
    });
  });
}
