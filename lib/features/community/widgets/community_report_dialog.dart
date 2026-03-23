import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/enums/community_enums.dart';

/// Shows a dialog for the user to pick a [CommunityReportReason].
///
/// [title] is the dialog headline (e.g. report post vs. report comment).
/// Returns the selected reason, or `null` if dismissed.
Future<CommunityReportReason?> showCommunityReportDialog(
  BuildContext context, {
  required String title,
}) {
  return showDialog<CommunityReportReason>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: CommunityReportReason.values
          .where((r) => r != CommunityReportReason.unknown)
          .map((reason) {
            final label = switch (reason) {
              CommunityReportReason.spam =>
                'community.report_reason_spam'.tr(),
              CommunityReportReason.harassment =>
                'community.report_reason_harassment'.tr(),
              CommunityReportReason.inappropriate =>
                'community.report_reason_inappropriate'.tr(),
              CommunityReportReason.misinformation =>
                'community.report_reason_misinformation'.tr(),
              CommunityReportReason.other =>
                'community.report_reason_other'.tr(),
              CommunityReportReason.unknown => '',
            };
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, reason),
              child: Text(label),
            );
          })
          .toList(),
    ),
  );
}
