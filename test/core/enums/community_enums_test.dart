import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';

void main() {
  group('CommunityPostType', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in CommunityPostType.values) {
        expect(CommunityPostType.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(CommunityPostType.fromJson('invalid'), CommunityPostType.unknown);
      expect(CommunityPostType.fromJson(''), CommunityPostType.unknown);
    });

    test('has expected value count', () {
      expect(CommunityPostType.values.length, 7);
    });
  });

  group('CommunityReportReason', () {
    test('toJson/fromJson round-trip for all values', () {
      for (final value in CommunityReportReason.values) {
        expect(CommunityReportReason.fromJson(value.toJson()), value);
      }
    });

    test('fromJson falls back to unknown on invalid input', () {
      expect(
        CommunityReportReason.fromJson('invalid'),
        CommunityReportReason.unknown,
      );
      expect(
        CommunityReportReason.fromJson(''),
        CommunityReportReason.unknown,
      );
    });

    test('has expected value count', () {
      expect(CommunityReportReason.values.length, 6);
    });
  });
}
