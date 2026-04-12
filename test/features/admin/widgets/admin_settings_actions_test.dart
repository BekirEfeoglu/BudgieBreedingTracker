import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_settings_actions.dart';

void main() {
  group('settingDefaults', () {
    test('contains 10 default setting entries', () {
      expect(settingDefaults.length, 10);
    });

    test('maintenance_mode defaults to false', () {
      expect(settingDefaults['maintenance_mode'], isFalse);
    });

    test('registration_open defaults to true', () {
      expect(settingDefaults['registration_open'], isTrue);
    });

    test('email_verification_required defaults to true', () {
      expect(settingDefaults['email_verification_required'], isTrue);
    });

    test('premium_enabled defaults to true', () {
      expect(settingDefaults['premium_enabled'], isTrue);
    });

    test('rate_limiting_enabled defaults to true', () {
      expect(settingDefaults['rate_limiting_enabled'], isTrue);
    });

    test('two_factor_required defaults to false', () {
      expect(settingDefaults['two_factor_required'], isFalse);
    });

    test('auto_backup_enabled defaults to false', () {
      expect(settingDefaults['auto_backup_enabled'], isFalse);
    });

    test('auto_cleanup_enabled defaults to false', () {
      expect(settingDefaults['auto_cleanup_enabled'], isFalse);
    });

    test('global_push_enabled defaults to true', () {
      expect(settingDefaults['global_push_enabled'], isTrue);
    });

    test('email_alerts_enabled defaults to true', () {
      expect(settingDefaults['email_alerts_enabled'], isTrue);
    });
  });

  group('categoryForKey', () {
    test('returns maintenance for maintenance_mode', () {
      expect(categoryForKey('maintenance_mode'), 'maintenance');
    });

    test('returns maintenance for registration_open', () {
      expect(categoryForKey('registration_open'), 'maintenance');
    });

    test('returns maintenance for email_verification_required', () {
      expect(categoryForKey('email_verification_required'), 'maintenance');
    });

    test('returns security for rate_limiting_enabled', () {
      expect(categoryForKey('rate_limiting_enabled'), 'security');
    });

    test('returns security for two_factor_required', () {
      expect(categoryForKey('two_factor_required'), 'security');
    });

    test('returns backup for auto_backup_enabled', () {
      expect(categoryForKey('auto_backup_enabled'), 'backup');
    });

    test('returns backup for auto_cleanup_enabled', () {
      expect(categoryForKey('auto_cleanup_enabled'), 'backup');
    });

    test('returns notification for global_push_enabled', () {
      expect(categoryForKey('global_push_enabled'), 'notification');
    });

    test('returns notification for email_alerts_enabled', () {
      expect(categoryForKey('email_alerts_enabled'), 'notification');
    });

    test('returns storage for storage keys', () {
      expect(categoryForKey('storage_limit'), 'storage');
    });

    test('returns community for community keys', () {
      expect(categoryForKey('community_moderation'), 'community');
    });

    test('returns general for unknown keys', () {
      expect(categoryForKey('some_unknown_key'), 'general');
    });
  });

  group('AdminSettingsActionState', () {
    test('default state has correct values', () {
      const state = AdminSettingsActionState();
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.isSuccess, isFalse);
    });

    test('copyWith updates isLoading', () {
      const state = AdminSettingsActionState();
      final updated = state.copyWith(isLoading: true);
      expect(updated.isLoading, isTrue);
      expect(updated.error, isNull);
      expect(updated.isSuccess, isFalse);
    });

    test('copyWith updates error', () {
      const state = AdminSettingsActionState();
      final updated = state.copyWith(error: 'some error');
      expect(updated.error, 'some error');
    });

    test('copyWith clears error when set to null', () {
      final state = const AdminSettingsActionState().copyWith(error: 'err');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith updates isSuccess', () {
      const state = AdminSettingsActionState();
      final updated = state.copyWith(isSuccess: true);
      expect(updated.isSuccess, isTrue);
    });
  });
}
