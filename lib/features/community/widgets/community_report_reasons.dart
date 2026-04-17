import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/community_enums.dart';

/// Ordered list of user-selectable report reasons shown in
/// [showCommunityReportSheet]. `unknown` is intentionally excluded —
/// it is a deserialization fallback, not a user choice.
const List<CommunityReportReason> kCommunityReportReasons = [
  CommunityReportReason.spam,
  CommunityReportReason.harassment,
  CommunityReportReason.inappropriate,
  CommunityReportReason.misinformation,
  CommunityReportReason.other,
];

/// Icon mapping for a report reason. `unknown` falls back to a help icon
/// even though it never appears in the UI list.
IconData iconForReportReason(CommunityReportReason reason) => switch (reason) {
      CommunityReportReason.spam => LucideIcons.mailWarning,
      CommunityReportReason.harassment => LucideIcons.shieldAlert,
      CommunityReportReason.inappropriate => LucideIcons.eyeOff,
      CommunityReportReason.misinformation => LucideIcons.alertCircle,
      CommunityReportReason.other => LucideIcons.messageCircle,
      CommunityReportReason.unknown => LucideIcons.helpCircle,
    };

/// Localized title key mapping for a report reason.
String titleForReportReason(CommunityReportReason reason) => switch (reason) {
      CommunityReportReason.spam => 'community.report_reason_spam'.tr(),
      CommunityReportReason.harassment =>
        'community.report_reason_harassment'.tr(),
      CommunityReportReason.inappropriate =>
        'community.report_reason_inappropriate'.tr(),
      CommunityReportReason.misinformation =>
        'community.report_reason_misinformation'.tr(),
      CommunityReportReason.other => 'community.report_reason_other'.tr(),
      CommunityReportReason.unknown => '',
    };

/// Localized hint key mapping for a report reason.
String hintForReportReason(CommunityReportReason reason) => switch (reason) {
      CommunityReportReason.spam => 'community.report_spam_hint'.tr(),
      CommunityReportReason.harassment =>
        'community.report_harassment_hint'.tr(),
      CommunityReportReason.inappropriate =>
        'community.report_inappropriate_hint'.tr(),
      CommunityReportReason.misinformation =>
        'community.report_misinformation_hint'.tr(),
      CommunityReportReason.other => 'community.report_other_hint'.tr(),
      CommunityReportReason.unknown => '',
    };
