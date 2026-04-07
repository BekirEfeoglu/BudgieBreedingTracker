import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_monitoring_snapshot_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_settings_content.dart';

import '../../../helpers/test_localization.dart';

/// Builds a minimal settings map with all expected keys set to [defaultValue].
Map<String, Map<String, dynamic>> _buildSettings({bool defaultValue = true}) {
  const keys = [
    'maintenance_mode',
    'registration_open',
    'email_verification_required',
    'premium_enabled',
    'community_enabled',
    'marketplace_enabled',
    'gamification_enabled',
    'messaging_enabled',
    'genetics_enabled',
    'rate_limiting_enabled',
    'two_factor_required',
    'auto_backup_enabled',
    'auto_cleanup_enabled',
    'global_push_enabled',
    'email_alerts_enabled',
  ];
  return {
    for (final key in keys)
      key: {'value': defaultValue, 'updated_at': '2024-01-01T00:00:00Z'},
  };
}

Widget _wrap(Map<String, Map<String, dynamic>> settings) {
  return ProviderScope(
    overrides: [
      cronJobStatusProvider.overrideWith(
        (_) => Future.value(<String, dynamic>{'status': 'ok'}),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: AdminSettingsContent(settings: settings),
      ),
    ),
  );
}

void main() {
  group('AdminSettingsContent', () {
    testWidgets('renders without crashing', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_buildSettings()));
      expect(find.byType(AdminSettingsContent), findsOneWidget);
    });

    testWidgets('shows system settings section', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_buildSettings()));
      expect(find.text(l10n('admin.system_settings')), findsOneWidget);
    });

    testWidgets('shows feature flags section', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_buildSettings()));
      expect(find.text(l10n('admin.feature_flags')), findsOneWidget);
    });

    testWidgets('shows security section', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_buildSettings()));
      expect(find.text(l10n('admin.security')), findsOneWidget);
    });

    testWidgets('shows data management section', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_buildSettings()));
      expect(find.text(l10n('admin.data_management')), findsOneWidget);
    });

    testWidgets('shows notification settings section', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_buildSettings()));
      expect(find.text(l10n('admin.notification_settings')), findsOneWidget);
    });

    testWidgets('shows cron status section', (tester) async {
      await pumpLocalizedApp(tester, _wrap(_buildSettings()));
      expect(
        find.textContaining(l10n('admin.cron_status_title')),
        findsOneWidget,
      );
    });

    testWidgets('renders with empty settings map', (tester) async {
      await pumpLocalizedApp(tester, _wrap({}));
      expect(find.byType(AdminSettingsContent), findsOneWidget);
    });
  });
}
