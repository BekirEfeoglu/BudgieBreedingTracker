import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
export 'package:budgie_breeding_tracker/data/models/community_comment_model.dart';
export 'package:budgie_breeding_tracker/core/enums/community_enums.dart';

/// Whether the community feature is enabled.
/// Content moderation (Apple Guideline 1.2) enforced via
/// [ContentModerationService] in create/comment providers.
final isCommunityEnabledProvider = Provider<bool>((ref) => true);

/// Tab enum for the community screen.
enum CommunityFeedTab {
  explore,
  following,
  guides,
  questions;

  String get label => switch (this) {
    CommunityFeedTab.explore => 'community.tab_explore'.tr(),
    CommunityFeedTab.following => 'community.tab_following'.tr(),
    CommunityFeedTab.guides => 'community.tab_guides'.tr(),
    CommunityFeedTab.questions => 'community.tab_questions'.tr(),
  };
}

/// Sort options for the explore tab.
enum CommunityExploreSort { newest, trending }

/// Explore sort state.
class ExploreSortNotifier extends Notifier<CommunityExploreSort> {
  @override
  CommunityExploreSort build() => CommunityExploreSort.newest;
}

final exploreSortProvider =
    NotifierProvider<ExploreSortNotifier, CommunityExploreSort>(
      ExploreSortNotifier.new,
    );

/// Active tab state for pill tab bar (replaces DefaultTabController).
class CommunityActiveTabNotifier extends Notifier<CommunityFeedTab> {
  @override
  CommunityFeedTab build() => CommunityFeedTab.explore;
}

final communityActiveTabProvider =
    NotifierProvider<CommunityActiveTabNotifier, CommunityFeedTab>(
  CommunityActiveTabNotifier.new,
);

/// Shared relative date formatter for community widgets.
String formatCommunityDate(DateTime? date) {
  if (date == null) return '';
  // Server timestamps come in as UTC; normalize to local before diff so
  // DST/timezone offsets do not produce negative inDays at boundaries
  // (datetime-format.md anti-pattern #4).
  final localDate = date.toLocal();
  final diff = DateTime.now().difference(localDate);
  if (diff.inMinutes < 1) return 'community.just_now'.tr();
  if (diff.inMinutes < 60) {
    return 'community.minutes_ago'.tr(args: [diff.inMinutes.toString()]);
  }
  if (diff.inHours < 24) {
    return 'community.hours_ago'.tr(args: [diff.inHours.toString()]);
  }
  return 'community.days_ago'.tr(args: [diff.inDays.toString()]);
}
