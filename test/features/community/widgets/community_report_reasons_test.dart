@Tags(['community'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/enums/community_enums.dart';
import 'package:budgie_breeding_tracker/features/community/widgets/community_report_reasons.dart';

void main() {
  group('kCommunityReportReasons', () {
    test('contains expected reasons without unknown', () {
      expect(kCommunityReportReasons, hasLength(5));
      expect(
        kCommunityReportReasons,
        isNot(contains(CommunityReportReason.unknown)),
      );
      expect(kCommunityReportReasons, contains(CommunityReportReason.spam));
      expect(
        kCommunityReportReasons,
        contains(CommunityReportReason.harassment),
      );
      expect(
        kCommunityReportReasons,
        contains(CommunityReportReason.inappropriate),
      );
      expect(
        kCommunityReportReasons,
        contains(CommunityReportReason.misinformation),
      );
      expect(kCommunityReportReasons, contains(CommunityReportReason.other));
    });
  });

  group('iconForReportReason', () {
    test('returns correct icons for all reasons', () {
      expect(
        iconForReportReason(CommunityReportReason.spam),
        LucideIcons.mailWarning,
      );
      expect(
        iconForReportReason(CommunityReportReason.harassment),
        LucideIcons.shieldAlert,
      );
      expect(
        iconForReportReason(CommunityReportReason.inappropriate),
        LucideIcons.eyeOff,
      );
      expect(
        iconForReportReason(CommunityReportReason.misinformation),
        LucideIcons.alertCircle,
      );
      expect(
        iconForReportReason(CommunityReportReason.other),
        LucideIcons.messageCircle,
      );
    });

    test('returns helpCircle for unknown fallback', () {
      expect(
        iconForReportReason(CommunityReportReason.unknown),
        LucideIcons.helpCircle,
      );
    });
  });

  group('titleForReportReason', () {
    test('returns non-empty titles for all UI reasons', () {
      for (final reason in kCommunityReportReasons) {
        final title = titleForReportReason(reason);
        expect(title, isNotEmpty, reason: 'Reason $reason should have a title');
      }
    });

    test('returns empty string for unknown', () {
      expect(titleForReportReason(CommunityReportReason.unknown), '');
    });
  });

  group('hintForReportReason', () {
    test('returns non-empty hints for all UI reasons', () {
      for (final reason in kCommunityReportReasons) {
        final hint = hintForReportReason(reason);
        expect(hint, isNotEmpty, reason: 'Reason $reason should have a hint');
      }
    });

    test('returns empty string for unknown', () {
      expect(hintForReportReason(CommunityReportReason.unknown), '');
    });
  });
}
