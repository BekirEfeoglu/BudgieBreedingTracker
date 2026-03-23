import 'package:flutter_test/flutter_test.dart';

// ignore: unused_import
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_dashboard_widgets.dart';

/// Tests for the admin_dashboard_widgets barrel export file.
///
/// Verifies that all exported types are accessible through the barrel file.
void main() {
  group('admin_dashboard_widgets barrel export', () {
    test('exports DashboardContent', () {
      expect(DashboardContent, isNotNull);
    });

    test('exports DashboardSystemHealthBanner', () {
      expect(DashboardSystemHealthBanner, isNotNull);
    });

    test('exports DashboardStatsGrid', () {
      expect(DashboardStatsGrid, isNotNull);
    });

    test('exports DashboardStatCard', () {
      expect(DashboardStatCard, isNotNull);
    });

    test('exports DashboardQuickActionButton', () {
      expect(DashboardQuickActionButton, isNotNull);
    });

    test('exports DashboardAlertsSection', () {
      expect(DashboardAlertsSection, isNotNull);
    });

    test('exports DashboardContentReviewSection', () {
      expect(DashboardContentReviewSection, isNotNull);
    });

    test('exports DashboardRecentActionsSection', () {
      expect(DashboardRecentActionsSection, isNotNull);
    });
  });
}
