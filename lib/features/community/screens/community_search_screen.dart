import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../router/route_names.dart';
import '../providers/community_feed_providers.dart';
import '../providers/community_providers.dart';
import '../providers/community_search_providers.dart';
import '../widgets/community_post_card.dart';

part 'community_search_results.dart';

class CommunitySearchScreen extends ConsumerStatefulWidget {
  const CommunitySearchScreen({super.key});

  @override
  ConsumerState<CommunitySearchScreen> createState() =>
      _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends ConsumerState<CommunitySearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initialValue = ref.read(communitySearchProvider).query;
    _controller = TextEditingController(text: initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(communitySearchProvider);
    // Watched (not read) because feedState.isLoading drives the loading
    // indicator below — reactivity is needed to rebuild when loading completes.
    final feedState = ref.watch(communityFeedProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: AppSpacing.lg,
          title: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (value) =>
                ref.read(communitySearchProvider.notifier).setQuery(value),
            decoration: InputDecoration(
              hintText: 'community.search_hint'.tr(),
              border: InputBorder.none,
              suffixIcon: searchState.hasQuery
                  ? IconButton(
                      onPressed: () {
                        _controller.clear();
                        ref.read(communitySearchProvider.notifier).clear();
                      },
                      icon: const Icon(LucideIcons.x),
                    )
                  : null,
            ),
          ),
          bottom: searchState.hasQuery
              ? TabBar(
                  tabs: [
                    Tab(text: 'community.search_posts'.tr()),
                    Tab(text: 'community.search_users'.tr()),
                    Tab(text: 'community.search_tags'.tr()),
                  ],
                )
              : null,
        ),
        body: feedState.isLoading && feedState.posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : searchState.hasQuery
            ? _SearchResultsBody(onTagTap: _applyQuery)
            : _SearchSuggestionsBody(onTagTap: _applyQuery),
      ),
    );
  }

  void _applyQuery(String query) {
    _controller.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length),
    );
    ref.read(communitySearchProvider.notifier).setQuery(query);
  }
}

class _CommunityUserTile extends StatelessWidget {
  final CommunitySearchUserResult user;
  final Widget? trailing;

  const _CommunityUserTile({required this.user, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => context.push(
          AppRoutes.communityUserPosts.replaceFirst(':userId', user.userId),
        ),
        leading: CircleAvatar(
          foregroundImage:
              user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
          child: user.avatarUrl == null
              ? Text(
                  user.username.isNotEmpty
                      ? user.username[0].toUpperCase()
                      : '?',
                )
              : null,
        ),
        title: Text(user.username),
        subtitle: Text(
          'community.user_posts_count'.tr(args: ['${user.postCount}']),
        ),
        trailing: trailing ?? const Icon(LucideIcons.chevronRight),
      ),
    );
  }
}

class _SearchResultsBody extends ConsumerWidget {
  final ValueChanged<String> onTagTap;

  const _SearchResultsBody({required this.onTagTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postResults = ref.watch(communitySearchPostsProvider);
    final userResults = ref.watch(communitySearchUsersProvider);
    final tagResults = ref.watch(communitySearchTagsProvider);

    return TabBarView(
      children: [
        _PostResultsList(posts: postResults),
        _UserResultsList(users: userResults),
        _TagResultsList(tags: tagResults, onTagTap: onTagTap),
      ],
    );
  }
}

class _SearchSuggestionsBody extends ConsumerWidget {
  final ValueChanged<String> onTagTap;

  const _SearchSuggestionsBody({required this.onTagTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final popularTags = ref.watch(communityPopularTagsProvider);
    final suggestedUsers = ref.watch(communitySuggestedUsersProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'community.popular_tags'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: popularTags
              .map(
                (tag) => ActionChip(
                  label: Text(tag),
                  onPressed: () => onTagTap(tag),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'community.suggested_users'.tr(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (suggestedUsers.isEmpty)
          Text(
            'community.no_search_results'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...suggestedUsers.map(
            (user) => _CommunityUserTile(user: user),
          ),
      ],
    );
  }
}
