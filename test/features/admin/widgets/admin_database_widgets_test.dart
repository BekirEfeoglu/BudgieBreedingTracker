import 'package:flutter_test/flutter_test.dart';

// ignore: unused_import
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_database_widgets.dart';

/// Tests for the admin_database_widgets barrel export file.
///
/// Verifies that all exported types are accessible through the barrel file.
void main() {
  group('admin_database_widgets barrel export', () {
    test('exports DatabaseContent', () {
      expect(DatabaseContent, isNotNull);
    });

    test('exports DatabaseSummaryCard', () {
      expect(DatabaseSummaryCard, isNotNull);
    });

    test('exports DatabaseGlobalActionsBar', () {
      expect(DatabaseGlobalActionsBar, isNotNull);
    });

    test('exports DatabaseActionButton', () {
      expect(DatabaseActionButton, isNotNull);
    });

    test('exports DatabaseTableList', () {
      expect(DatabaseTableList, isNotNull);
    });

    test('exports DatabaseTableRow', () {
      expect(DatabaseTableRow, isNotNull);
    });
  });
}
