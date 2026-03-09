import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../router/route_names.dart';
import '../providers/admin_providers.dart';

enum _UserStatusFilter { all, active, inactive }

enum _UserSortOption { newest, oldest, nameAsc, emailAsc }

/// Admin users list screen with search and user cards.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  static const _searchDebounce = Duration(milliseconds: 350);

  late final TextEditingController _searchController;
  Timer? _debounceTimer;

  String _query = '';
  _UserStatusFilter _statusFilter = _UserStatusFilter.all;
  _UserSortOption _sortOption = _UserSortOption.newest;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshUsers() async {
    try {
      ref.invalidate(adminUsersProvider(_query));
      await ref.read(adminUsersProvider(_query).future);
    } catch (_) {
      // Error state is handled by the provider/UI.
    }
  }

  void _resetPagination() {
    ref.read(adminUsersLimitProvider.notifier).state = kAdminPageSize;
  }

  void _onSearchChanged(String raw) {
    final normalized = raw.trim();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_searchDebounce, () {
      if (!mounted || normalized == _query) return;
      setState(() => _query = normalized);
      _resetPagination();
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    if (_query.isEmpty) return;
    setState(() => _query = '');
    _resetPagination();
  }

  void _clearFilters() {
    _clearSearch();
    if (_statusFilter != _UserStatusFilter.all) {
      setState(() => _statusFilter = _UserStatusFilter.all);
    }
  }

  List<AdminUser> _applyFiltersAndSort(List<AdminUser> users) {
    final filtered = switch (_statusFilter) {
      _UserStatusFilter.active => users.where((user) => user.isActive).toList(),
      _UserStatusFilter.inactive =>
        users.where((user) => !user.isActive).toList(),
      _UserStatusFilter.all => List<AdminUser>.from(users),
    };

    int compareByName(AdminUser a, AdminUser b) {
      final aName = _displayName(a).toLowerCase();
      final bName = _displayName(b).toLowerCase();
      return aName.compareTo(bName);
    }

    int compareByEmail(AdminUser a, AdminUser b) =>
        a.email.toLowerCase().compareTo(b.email.toLowerCase());

    filtered.sort((a, b) {
      final compare = switch (_sortOption) {
        _UserSortOption.newest => b.createdAt.compareTo(a.createdAt),
        _UserSortOption.oldest => a.createdAt.compareTo(b.createdAt),
        _UserSortOption.nameAsc => compareByName(a, b),
        _UserSortOption.emailAsc => compareByEmail(a, b),
      };
      if (compare != 0) return compare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  String _displayName(AdminUser user) {
    final fullName = user.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;
    return user.email;
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_query));
    final limit = ref.watch(adminUsersLimitProvider);

    return Scaffold(
      body: Column(
        children: [
          _UsersToolbar(
            searchController: _searchController,
            query: _query,
            statusFilter: _statusFilter,
            sortOption: _sortOption,
            onSearchChanged: _onSearchChanged,
            onClearSearch: _clearSearch,
            onStatusFilterChanged: (value) =>
                setState(() => _statusFilter = value),
            onSortChanged: (value) => setState(() => _sortOption = value),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const LoadingState(),
              error: (error, _) => ErrorState(
                message: 'common.data_load_error'.tr(),
                onRetry: () => ref.invalidate(adminUsersProvider(_query)),
              ),
              data: (users) {
                final filteredUsers = _applyFiltersAndSort(users);
                final activeUsers = users.where((user) => user.isActive).length;
                final inactiveUsers = users.length - activeUsers;
                final hasMore = users.length >= limit;
                final hasFilter =
                    _query.isNotEmpty || _statusFilter != _UserStatusFilter.all;

                return Column(
                  children: [
                    _UsersSummaryBar(
                      totalUsers: users.length,
                      visibleUsers: filteredUsers.length,
                      activeUsers: activeUsers,
                      inactiveUsers: inactiveUsers,
                    ),
                    Expanded(
                      child: _UsersList(
                        users: filteredUsers,
                        hasMore: hasMore,
                        hasFilter: hasFilter,
                        onRefresh: _refreshUsers,
                        onClearFilter: _clearFilters,
                        onLoadMore: () {
                          ref.read(adminUsersLimitProvider.notifier).state +=
                              kAdminPageSize;
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String query;
  final _UserStatusFilter statusFilter;
  final _UserSortOption sortOption;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<_UserStatusFilter> onStatusFilterChanged;
  final ValueChanged<_UserSortOption> onSortChanged;

  const _UsersToolbar({
    required this.searchController,
    required this.query,
    required this.statusFilter,
    required this.sortOption,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onStatusFilterChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'admin.search_users'.tr(),
              prefixIcon: const AppIcon(AppIcons.search),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: onClearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusChip(
                        label: 'common.all'.tr(),
                        selected: statusFilter == _UserStatusFilter.all,
                        onTap: () =>
                            onStatusFilterChanged(_UserStatusFilter.all),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusChip(
                        label: 'common.active'.tr(),
                        selected: statusFilter == _UserStatusFilter.active,
                        onTap: () =>
                            onStatusFilterChanged(_UserStatusFilter.active),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusChip(
                        label: 'admin.inactive'.tr(),
                        selected: statusFilter == _UserStatusFilter.inactive,
                        onTap: () =>
                            onStatusFilterChanged(_UserStatusFilter.inactive),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PopupMenuButton<_UserSortOption>(
                tooltip: 'common.sort'.tr(),
                initialValue: sortOption,
                onSelected: onSortChanged,
                itemBuilder: (context) => _UserSortOption.values.map((option) {
                  final selected = option == sortOption;
                  return PopupMenuItem<_UserSortOption>(
                    value: option,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: selected
                              ? const Icon(LucideIcons.check, size: 16)
                              : null,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _sortLabel(option),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.arrowUpDown,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'common.sort'.tr(),
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _sortLabel(_UserSortOption option) {
    return switch (option) {
      _UserSortOption.newest => 'breeding.sort_newest'.tr(),
      _UserSortOption.oldest => 'breeding.sort_oldest'.tr(),
      _UserSortOption.nameAsc => 'birds.sort_name_asc'.tr(),
      _UserSortOption.emailAsc => 'auth.email'.tr(),
    };
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _UsersSummaryBar extends StatelessWidget {
  final int totalUsers;
  final int visibleUsers;
  final int activeUsers;
  final int inactiveUsers;

  const _UsersSummaryBar({
    required this.totalUsers,
    required this.visibleUsers,
    required this.activeUsers,
    required this.inactiveUsers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usersLabel = visibleUsers == totalUsers
        ? '${'admin.total_users'.tr()}: $totalUsers'
        : '${'admin.users'.tr()}: $visibleUsers / $totalUsers';
    final activityLabel =
        '${'common.active'.tr()}: $activeUsers   ${'admin.inactive'.tr()}: $inactiveUsers';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            usersLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            activityLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersList extends StatelessWidget {
  final List<AdminUser> users;
  final bool hasMore;
  final bool hasFilter;
  final Future<void> Function() onRefresh;
  final VoidCallback? onClearFilter;
  final VoidCallback? onLoadMore;

  const _UsersList({
    required this.users,
    required this.hasFilter,
    required this.onRefresh,
    this.hasMore = false,
    this.onClearFilter,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxxl,
          ),
          children: [
            EmptyState(
              icon: const Icon(LucideIcons.userX),
              title: hasFilter
                  ? 'common.no_results'.tr()
                  : 'admin.no_users_found'.tr(),
              subtitle: hasFilter ? 'common.no_results_hint'.tr() : null,
              actionLabel: hasFilter ? 'admin.clear_filter'.tr() : null,
              onAction: hasFilter ? onClearFilter : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        itemCount: users.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == users.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(LucideIcons.chevronDown, size: 16),
                  label: Text('admin.load_more'.tr()),
                ),
              ),
            );
          }
          return _UserCard(user: users[index]);
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AdminUser user;

  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = user.avatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final fullName = user.fullName?.trim();
    final displayName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : user.email;
    final showEmail = displayName.toLowerCase() != user.email.toLowerCase();

    return Card(
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.adminUserDetail.replaceFirst(':userId', user.id),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: hasAvatar
                    ? CachedNetworkImageProvider(
                        avatarUrl,
                        maxWidth: 88,
                        maxHeight: 88,
                      )
                    : null,
                child: !hasAvatar
                    ? AppIcon(
                        AppIcons.users,
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!user.isActive) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusFull,
                              ),
                            ),
                            child: Text(
                              'admin.inactive'.tr(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (showEmail) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${'admin.joined'.tr()}: ${_formatDate(context, user.createdAt)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy', locale).format(date);
  }
}
