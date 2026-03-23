part of 'community_search_screen.dart';

class _PostResultsList extends StatelessWidget {
  final List<CommunityPost> posts;

  const _PostResultsList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _SearchEmptyBody();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      itemCount: posts.length,
      itemBuilder: (context, index) => CommunityPostCard(post: posts[index]),
    );
  }
}

class _UserResultsList extends StatelessWidget {
  final List<CommunitySearchUserResult> users;

  const _UserResultsList({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const _SearchEmptyBody();

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          child: ListTile(
            onTap: () => context.push(
              AppRoutes.communityUserPosts.replaceFirst(':userId', user.userId),
            ),
            leading: CircleAvatar(
              foregroundImage: user.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
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
            trailing: Text(
              'community.likes_count'.tr(args: ['${user.totalLikes}']),
            ),
          ),
        );
      },
    );
  }
}

class _TagResultsList extends StatelessWidget {
  final List<String> tags;
  final ValueChanged<String> onTagTap;

  const _TagResultsList({required this.tags, required this.onTagTap});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const _SearchEmptyBody();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: tags
              .map(
                (tag) => ActionChip(
                  label: Text(tag),
                  onPressed: () => onTagTap(tag),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SearchEmptyBody extends StatelessWidget {
  const _SearchEmptyBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'community.no_search_results'.tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
