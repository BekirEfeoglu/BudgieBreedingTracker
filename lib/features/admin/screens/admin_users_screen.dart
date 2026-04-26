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
import '../../../core/utils/logger.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../router/route_names.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_notification_sheet.dart';

part 'admin_users_screen_toolbar.dart';
part 'admin_users_screen_list.dart';
part 'admin_users_screen_card.dart';
part 'admin_users_screen_bulk_actions.dart';

enum _UserStatusFilter { all, active, inactive }

enum _UserSortOption { newest, oldest, nameAsc, emailAsc }

extension _UserStatusFilterQuery on _UserStatusFilter {
  bool? get queryValue => switch (this) {
    _UserStatusFilter.active => true,
    _UserStatusFilter.inactive => false,
    _UserStatusFilter.all => null,
  };
}

extension _UserSortOptionQuery on _UserSortOption {
  String get sortField => switch (this) {
    _UserSortOption.newest || _UserSortOption.oldest => 'created_at',
    _UserSortOption.nameAsc => 'full_name',
    _UserSortOption.emailAsc => 'email',
  };

  bool get sortAscending => switch (this) {
    _UserSortOption.oldest ||
    _UserSortOption.nameAsc ||
    _UserSortOption.emailAsc => true,
    _UserSortOption.newest => false,
  };
}

/// Admin users list screen with search and user cards.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
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

  AdminUsersQuery get _buildQuery => AdminUsersQuery(
    searchTerm: _query,
    isActiveFilter: _statusFilter.queryValue,
    sortField: _sortOption.sortField,
    sortAscending: _sortOption.sortAscending,
    limit: ref.read(adminUsersLimitProvider),
  );

  Future<void> _refreshUsers() async {
    try {
      ref.invalidate(adminUsersProvider(_buildQuery));
      await ref.read(adminUsersProvider(_buildQuery).future);
    } catch (e, st) {
      AppLogger.error('AdminUsersScreen._refreshUsers', e, st);
      // Error state is handled by the provider/UI.
    }
  }

  void _resetPagination() {
    ref.read(adminUsersLimitProvider.notifier).state =
        AdminConstants.usersPageSize;
  }

  void _onSearchChanged(String raw) {
    final normalized = raw.trim();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AdminConstants.searchDebounceDuration, () {
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
      _resetPagination();
    }
  }

  void _toggleSelection(String userId) {
    ref.read(adminUserSelectionProvider.notifier).toggle(userId);
  }

  void _selectAllVisible(List<AdminUser> users) {
    ref
        .read(adminUserSelectionProvider.notifier)
        .selectAll(users.map((u) => u.id).toList());
  }

  void _clearSelection() {
    ref.read(adminUserSelectionProvider.notifier).clear();
  }

  Future<void> _handleQuickAction(String action, String userId) async {
    switch (action) {
      case 'activate':
        final confirmed = await showConfirmDialog(
          context,
          title: 'admin.confirm_activate'.tr(),
          message: 'admin.confirm_activate_desc'.tr(),
        );
        if (confirmed != true) return;
        await ref
            .read(adminActionsProvider.notifier)
            .toggleUserActive(userId, true);
      case 'deactivate':
        final confirmed = await showConfirmDialog(
          context,
          title: 'admin.confirm_deactivate'.tr(),
          message: 'admin.confirm_deactivate_desc'.tr(),
          isDestructive: true,
        );
        if (confirmed != true) return;
        await ref
            .read(adminActionsProvider.notifier)
            .toggleUserActive(userId, false);
      case 'grant_premium':
        final confirmed = await showConfirmDialog(
          context,
          title: 'admin.confirm_grant_premium'.tr(),
          message: 'admin.confirm_grant_premium_desc'.tr(),
        );
        if (confirmed != true) return;
        await ref.read(adminActionsProvider.notifier).grantPremium(userId);
      case 'revoke_premium':
        final confirmed = await showConfirmDialog(
          context,
          title: 'admin.confirm_revoke_premium'.tr(),
          message: 'admin.confirm_revoke_premium_desc'.tr(),
          isDestructive: true,
        );
        if (confirmed != true) return;
        await ref.read(adminActionsProvider.notifier).revokePremium(userId);
    }
    if (mounted) _refreshUsers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = ref.watch(adminUsersLimitProvider);
    final usersQuery = _buildQuery.copyWith(limit: limit);
    final usersAsync = ref.watch(adminUsersProvider(usersQuery));

    ref.listen<AdminActionState>(adminActionsProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(adminActionsProvider.notifier).reset();
      }
      if (state.error != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    final selectedIds = ref.watch(adminUserSelectionProvider);
    final isSelectionMode = selectedIds.isNotEmpty;
    final selectedCount = selectedIds.length;

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
            onStatusFilterChanged: (value) {
              setState(() => _statusFilter = value);
              _resetPagination();
            },
            onSortChanged: (value) {
              setState(() => _sortOption = value);
              _resetPagination();
            },
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const LoadingState(),
              error: (error, _) => ErrorState(
                message: 'common.data_load_error'.tr(),
                onRetry: () => ref.invalidate(adminUsersProvider(usersQuery)),
              ),
              data: (users) {
                final activeUsers = users.where((user) => user.isActive).length;
                final inactiveUsers = users.length - activeUsers;
                final hasMore = users.length >= limit;
                final hasFilter =
                    _query.isNotEmpty || _statusFilter != _UserStatusFilter.all;

                return Column(
                  children: [
                    if (isSelectionMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.2,
                        ),
                        child: Row(
                          children: [
                            AppIconButton(
                              icon: const Icon(LucideIcons.x),
                              tooltip: 'admin.clear_selection'.tr(),
                              semanticLabel: 'admin.clear_selection'.tr(),
                              onPressed: _clearSelection,
                            ),
                            Text(
                              'admin.selected_count'.tr(
                                args: ['$selectedCount'],
                              ),
                              style: theme.textTheme.titleSmall,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _selectAllVisible(users),
                              child: Text('admin.select_all'.tr()),
                            ),
                          ],
                        ),
                      ),
                    _UsersSummaryBar(
                      totalUsers: users.length,
                      visibleUsers: users.length,
                      activeUsers: activeUsers,
                      inactiveUsers: inactiveUsers,
                    ),
                    Expanded(
                      child: _UsersList(
                        users: users,
                        hasMore: hasMore,
                        hasFilter: hasFilter,
                        onRefresh: _refreshUsers,
                        onClearFilter: _clearFilters,
                        onToggleSelection: _toggleSelection,
                        selectedIds: selectedIds,
                        isSelectionMode: isSelectionMode,
                        onQuickAction: _handleQuickAction,
                        onLoadMore: () {
                          ref.read(adminUsersLimitProvider.notifier).state +=
                              AdminConstants.usersPageSize;
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
      bottomNavigationBar: isSelectionMode
          ? _BulkActionBar(
              selectedIds: selectedIds,
              onClearSelection: _clearSelection,
            )
          : null,
    );
  }
}
