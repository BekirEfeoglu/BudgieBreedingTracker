import 'package:flutter_test/flutter_test.dart';

// ignore: unused_import
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_monitoring_widgets.dart';

/// Tests for the admin_monitoring_widgets barrel export file.
///
/// Verifies that all exported types are accessible through the barrel file.
void main() {
  group('admin_monitoring_widgets barrel export', () {
    test('exports MonitoringContent', () {
      expect(MonitoringContent, isNotNull);
    });

    test('exports MonitoringStatusBanner', () {
      expect(MonitoringStatusBanner, isNotNull);
    });

    test('exports MonitoringCapacityGrid', () {
      expect(MonitoringCapacityGrid, isNotNull);
    });

    test('exports MonitoringCapacityCard', () {
      expect(MonitoringCapacityCard, isNotNull);
    });

    test('exports MonitoringIndexUsageCard', () {
      expect(MonitoringIndexUsageCard, isNotNull);
    });

    test('exports MonitoringTableDetailsSection', () {
      expect(MonitoringTableDetailsSection, isNotNull);
    });

    test('exports formatBytes helper', () {
      expect(formatBytes(1024), equals('1.0 KB'));
    });

    test('exports formatNumber helper', () {
      expect(formatNumber(1234), equals('1,234'));
    });

    test('exports capacityColor helper', () {
      expect(capacityColor(0.5), isNotNull);
    });
  });
}
