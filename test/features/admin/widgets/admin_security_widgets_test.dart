import 'package:flutter_test/flutter_test.dart';

// ignore: unused_import
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_security_widgets.dart';

/// Tests for the admin_security_widgets barrel export file.
///
/// Verifies that all exported types are accessible through the barrel file.
void main() {
  group('admin_security_widgets barrel export', () {
    test('exports SecurityContent', () {
      expect(SecurityContent, isNotNull);
    });

    test('exports SecuritySummary', () {
      expect(SecuritySummary, isNotNull);
    });

    test('exports SecuritySummaryCard', () {
      expect(SecuritySummaryCard, isNotNull);
    });

    test('exports SecurityEventItem', () {
      expect(SecurityEventItem, isNotNull);
    });

    test('exports SecurityMetadataRow', () {
      expect(SecurityMetadataRow, isNotNull);
    });

    test('exports SecurityFilterBar', () {
      expect(SecurityFilterBar, isNotNull);
    });
  });
}
