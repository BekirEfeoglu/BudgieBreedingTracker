import 'package:flutter_test/flutter_test.dart';

// ignore: unused_import
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_user_detail_widgets.dart';

/// Tests for the admin_user_detail_widgets barrel export file.
///
/// Verifies that all exported types are accessible through the barrel file.
void main() {
  group('admin_user_detail_widgets barrel export', () {
    test('exports UserDetailContent', () {
      expect(UserDetailContent, isNotNull);
    });

    test('exports UserDetailProfileHeader', () {
      expect(UserDetailProfileHeader, isNotNull);
    });

    test('exports UserDetailSubscriptionSection', () {
      expect(UserDetailSubscriptionSection, isNotNull);
    });

    test('exports UserDetailStatsRow', () {
      expect(UserDetailStatsRow, isNotNull);
    });

    test('exports UserDetailActivityLogSection', () {
      expect(UserDetailActivityLogSection, isNotNull);
    });
  });
}
