import 'package:flutter_test/flutter_test.dart';

// ignore: unused_import
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_audit_widgets.dart';

/// Tests for the admin_audit_widgets barrel export file.
///
/// Verifies that all exported types are accessible through the barrel file.
void main() {
  group('admin_audit_widgets barrel export', () {
    test('exports AuditContent', () {
      // Verify the type is accessible through the barrel export.
      expect(AuditContent, isNotNull);
    });

    test('exports AuditSummary', () {
      expect(AuditSummary, isNotNull);
    });

    test('exports AuditLogItem', () {
      expect(AuditLogItem, isNotNull);
    });

    test('exports AuditFilterBar', () {
      expect(AuditFilterBar, isNotNull);
    });

    test('exports AuditDateChip', () {
      expect(AuditDateChip, isNotNull);
    });
  });
}
