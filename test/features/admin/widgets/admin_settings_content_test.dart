import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_monitoring_snapshot_providers.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_settings_content.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_settings_widgets.dart';

final _settingsMap = <String, Map<String, dynamic>>{
  'maintenance_mode': {'value': false},
  'registration_open': {'value': true},
  'email_verification_required': {'value': true},
  'premium_enabled': {'value': true},
  'rate_limiting_enabled': {'value': true},
  'two_factor_required': {'value': false},
  'auto_backup_enabled': {'value': false},
  'auto_cleanup_enabled': {'value': false},
  'global_push_enabled': {'value': true},
  'email_alerts_enabled': {'value': true},
};

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [
      cronJobStatusProvider.overrideWith((ref) => throw UnimplementedError()),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('AdminSettingsContent', () {
    testWidgets('should_render_without_crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();
      expect(find.byType(AdminSettingsContent), findsOneWidget);
    });

    testWidgets('should_show_settings_overview_banner', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();
      expect(find.byType(SettingsOverviewBanner), findsOneWidget);
    });

    testWidgets('should_show_system_settings_section', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();
      expect(find.text(l10n('admin.system_settings')), findsOneWidget);
    });

    testWidgets('should_show_feature_flags_section', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();
      expect(find.text(l10n('admin.feature_flags')), findsOneWidget);
    });

    testWidgets('should_show_security_section', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();
      expect(find.text(l10n('admin.security')), findsOneWidget);
    });

    testWidgets('should_show_app_update_settings_section', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();
      expect(find.text(l10n('admin.app_update_settings')), findsOneWidget);
    });

    testWidgets('shows required updates disabled when minimum build is zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();

      expect(find.text(l10n('admin.force_update_disabled')), findsNWidgets(2));
    });

    testWidgets('rejects a minimum build above the latest build', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();

      await tester.tap(find.text(l10n('admin.edit_app_update_settings')));
      await tester.pumpAndSettle();
      final latestBuildFields = find.widgetWithText(
        TextFormField,
        l10n('admin.latest_build'),
      );
      final minimumBuildFields = find.widgetWithText(
        TextFormField,
        l10n('admin.min_supported_build'),
      );
      await tester.enterText(latestBuildFields.first, '60');
      await tester.enterText(minimumBuildFields.first, '61');
      await tester.tap(find.text(l10n('common.save')));
      await tester.pump();

      expect(find.text(l10n('admin.min_build_exceeds_latest')), findsOneWidget);
    });

    testWidgets('asks for confirmation before raising a minimum build', (
      tester,
    ) async {
      final settings = <String, Map<String, dynamic>>{
        ..._settingsMap,
        'app_version': {
          'value': {
            'ios': {
              'latest_version': '1.1.8',
              'latest_build': 60,
              'min_supported_build': 0,
              'store_url': 'https://apps.apple.com/app/id123',
            },
            'android': {
              'latest_version': '1.1.8',
              'latest_build': 60,
              'min_supported_build': 32,
              'store_url': 'https://play.google.com/store/apps/details?id=test',
            },
          },
        },
      };
      await tester.pumpWidget(_wrap(AdminSettingsContent(settings: settings)));
      await tester.pump();

      await tester.tap(find.text(l10n('admin.edit_app_update_settings')));
      await tester.pumpAndSettle();
      final minimumBuildFields = find.widgetWithText(
        TextFormField,
        l10n('admin.min_supported_build'),
      );
      await tester.enterText(minimumBuildFields.first, '1');
      await tester.tap(find.text(l10n('common.save')));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n('admin.confirm_min_supported_build')),
        findsOneWidget,
      );
      expect(
        find.text(l10n('admin.confirm_min_supported_build_desc')),
        findsOneWidget,
      );
    });

    testWidgets('should_show_multiple_accent_settings_sections', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();
      // App Update, System, Feature, Security, Data, Notification = 6 sections
      expect(find.byType(AccentSettingsSection), findsNWidgets(6));
    });

    testWidgets('should_show_reset_defaults_button', (tester) async {
      await tester.pumpWidget(
        _wrap(AdminSettingsContent(settings: _settingsMap)),
      );
      await tester.pump();
      expect(find.byType(ResetDefaultsButton), findsOneWidget);
    });

    testWidgets('should_handle_string_boolean_values', (tester) async {
      final settings = <String, Map<String, dynamic>>{
        'maintenance_mode': {'value': 'true'},
        'registration_open': {'value': 'false'},
      };
      await tester.pumpWidget(_wrap(AdminSettingsContent(settings: settings)));
      await tester.pump();
      expect(find.byType(AdminSettingsContent), findsOneWidget);
    });

    testWidgets('should_handle_empty_settings_map', (tester) async {
      await tester.pumpWidget(_wrap(const AdminSettingsContent(settings: {})));
      await tester.pump();
      expect(find.byType(AdminSettingsContent), findsOneWidget);
    });
  });
}
