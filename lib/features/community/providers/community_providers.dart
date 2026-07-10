import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:budgie_breeding_tracker/data/models/community_post_model.dart';
export 'package:budgie_breeding_tracker/data/models/community_comment_model.dart';
export 'package:budgie_breeding_tracker/data/providers/community_profile_providers.dart'
    show publicUserProfileProvider;
export 'package:budgie_breeding_tracker/core/enums/community_enums.dart';

/// Whether the community feature is enabled.
/// Content moderation (Apple Guideline 1.2) enforced via
/// [ContentModerationService] in create/comment providers.
/// Hardcoded true bugün; Faz 2'de server-side kill switch'e bağlanacak
/// (`app_config` tablosu + remoteConfigProvider, fail-open — spec § 4.4).
/// `_ComingSoonBody` bu yüzden bilinçli tutuluyor, silme.
final isCommunityEnabledProvider = Provider<bool>((ref) => true);

/// Tab enum for the community screen.
enum CommunityFeedTab {
  explore,
  following,
  guides,
  marketplace;

  String get label => switch (this) {
    CommunityFeedTab.explore => 'community.tab_explore'.tr(),
    CommunityFeedTab.following => 'community.tab_following'.tr(),
    CommunityFeedTab.guides => 'community.tab_guides'.tr(),
    CommunityFeedTab.marketplace => 'community.tab_marketplace'.tr(),
  };
}

/// Sort options for the explore tab.
enum CommunityExploreSort { newest, trending }

class ExploreSortNotifier extends Notifier<CommunityExploreSort> {
  @override
  CommunityExploreSort build() => CommunityExploreSort.newest;

  void setSort(CommunityExploreSort newSort) {
    state = newSort;
  }
}

final exploreSortProvider =
    NotifierProvider<ExploreSortNotifier, CommunityExploreSort>(
      ExploreSortNotifier.new,
    );

/// Selected topic (tag) filter for the Guides tab library. `null` = all topics.
///
/// Client-side filter over the already-loaded guide posts, so switching topics
/// is instant and needs no extra fetch. Reset when leaving the Guides tab is
/// not required — re-selecting the same chip clears it.
class GuideTopicFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void toggle(String topic) => state = state == topic ? null : topic;
  void clear() => state = null;
}

final guideTopicFilterProvider =
    NotifierProvider<GuideTopicFilterNotifier, String?>(
      GuideTopicFilterNotifier.new,
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
///
/// Beyond 7 days it falls back to an absolute, locale-aware date instead of an
/// ever-growing "N days ago" (a 400-day-old post reading "400 gün önce" is
/// meaningless — datetime-format.md: >7 days → full date). Pass [locale]
/// (`context.locale.toString()`) so month names match the app language.
String formatCommunityDate(DateTime? date, {String? locale}) {
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
  if (diff.inDays <= 7) {
    return 'community.days_ago'.tr(args: [diff.inDays.toString()]);
  }
  return DateFormat.yMMMd(locale).format(localDate);
}
