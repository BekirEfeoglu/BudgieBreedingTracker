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
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../router/route_names.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_providers.dart';

part 'admin_users_screen_toolbar.dart';
part 'admin_users_screen_list.dart';
part 'admin_users_screen_card.dart';

enum _UserStatusFilter { all, active, inactive }

enum _UserSortOption { newest, oldest, nameAsc, emailAsc }

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
        limit: ref.read(adminUsersLimitProvider),
      );

  Future<void> _refreshUsers() async {
    try {
      ref.invalidate(adminUsersProvider(_buildQuery));
      await ref.read(adminUsersProvider(_buildQuery).future);
    } catch (_) {
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
    final theme = Theme.of(context);
    final limit = ref.watch(adminUsersLimitProvider);
    final usersAsync = ref.watch(
      adminUsersProvider(
        AdminUsersQuery(searchTerm: _query, limit: limit),
      ),
    );

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
            onStatusFilterChanged: (value) =>
                setState(() => _statusFilter = value),
            onSortChanged: (value) => setState(() => _sortOption = value),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const LoadingState(),
              error: (error, _) => ErrorState(
                message: 'common.data_load_error'.tr(),
                onRetry: () => ref.invalidate(
                  adminUsersProvider(
                    AdminUsersQuery(searchTerm: _query, limit: limit),
                  ),
                ),
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
                    if (isSelectionMode)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.2),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(LucideIcons.x),
                              tooltip: 'admin.clear_selection'.tr(),
                              onPressed: _clearSelection,
                            ),
                            Text(
                              'admin.selected_count'
                                  .tr(args: ['$selectedCount']),
                              style: theme.textTheme.titleSmall,
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _selectAllVisible(filteredUsers),
                              child: Text('admin.select_all'.tr()),
                            ),
                          ],
                        ),
                      ),
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
                        onToggleSelection: _toggleSelection,
                        selectedIds: selectedIds,
                        isSelectionMode: isSelectionMode,
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

// ─── Bulk Action Bar ─────────────────────────────────────────────────────────

class _BulkActionBar extends ConsumerStatefulWidget {
  final Set<String> selectedIds;
  final VoidCallback onClearSelection;

  const _BulkActionBar({
    required this.selectedIds,
    required this.onClearSelection,
  });

  @override
  ConsumerState<_BulkActionBar> createState() => _BulkActionBarState();
}

class _BulkActionBarState extends ConsumerState<_BulkActionBar> {
  bool _isLoading = false;

  Future<void> _run(
    Future<({int succeeded, int skipped})> Function() action,
    String actionLabel,
  ) async {
    setState(() => _isLoading = true);
    try {
      final result = await action();
      if (!mounted) return;
      final skippedMsg = result.skipped > 0
          ? ' (${result.skipped} ${'admin.protected_users_skipped'.tr(args: [''])})'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$actionLabel: ${result.succeeded}$skippedMsg',
          ),
        ),
      );
      widget.onClearSelection();
    } catch (e, st) {
      AppLogger.error('_BulkActionBar', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.action_error'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onActivate() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_activate'.tr(),
      message: 'admin.confirm_activate_desc'.tr(),
    );
    if (confirmed != true) return;
    await _run(
      () => ref.read(adminActionsProvider.notifier).bulkToggleActive(
            widget.selectedIds,
            activate: true,
          ),
      'admin.bulk_activate'.tr(),
    );
  }

  Future<void> _onDeactivate() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_deactivate'.tr(),
      message: 'admin.confirm_deactivate_desc'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    await _run(
      () => ref.read(adminActionsProvider.notifier).bulkToggleActive(
            widget.selectedIds,
            activate: false,
          ),
      'admin.bulk_deactivate'.tr(),
    );
  }

  Future<void> _onGrantPremium() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_grant_premium'.tr(),
      message: 'admin.confirm_grant_premium_desc'.tr(),
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(adminActionsProvider.notifier)
          .bulkGrantPremium(widget.selectedIds),
      'admin.bulk_grant_premium'.tr(),
    );
  }

  Future<void> _onRevokePremium() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.confirm_revoke_premium'.tr(),
      message: 'admin.confirm_revoke_premium_desc'.tr(),
      isDestructive: true,
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(adminActionsProvider.notifier)
          .bulkRevokePremium(widget.selectedIds),
      'admin.bulk_revoke_premium'.tr(),
    );
  }

  Future<void> _onExport() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.bulk_export'.tr(),
      message: 'common.continue_confirm'.tr(),
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(adminActionsProvider.notifier)
          .bulkExport(widget.selectedIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${'admin.bulk_export'.tr()}: ${widget.selectedIds.length}',
          ),
        ),
      );
      widget.onClearSelection();
    } catch (e, st) {
      AppLogger.error('_BulkActionBar.export', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin.action_error'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onDelete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'admin.bulk_delete'.tr(),
      message: 'admin.bulk_delete_confirm'
          .tr(args: ['${widget.selectedIds.length}']),
      isDestructive: true,
    );
    if (confirmed != true) return;
    await _run(
      () => ref
          .read(adminActionsProvider.notifier)
          .bulkDeleteUserData(widget.selectedIds),
      'admin.bulk_delete'.tr(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFounderAsync = ref.watch(isFounderProvider);
    final isFounder = isFounderAsync.value ?? false;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Icon(LucideIcons.userCheck, size: 16),
                      label: Text('admin.bulk_activate'.tr()),
                      onPressed: _onActivate,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(LucideIcons.userX, size: 16),
                      label: Text('admin.bulk_deactivate'.tr()),
                      onPressed: _onDeactivate,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(LucideIcons.star, size: 16),
                      label: Text('admin.bulk_grant_premium'.tr()),
                      onPressed: _onGrantPremium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(LucideIcons.starOff, size: 16),
                      label: Text('admin.bulk_revoke_premium'.tr()),
                      onPressed: _onRevokePremium,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ActionChip(
                      avatar: const Icon(LucideIcons.download, size: 16),
                      label: Text('admin.bulk_export'.tr()),
                      onPressed: _onExport,
                    ),
                    if (isFounder) ...[
                      const SizedBox(width: AppSpacing.sm),
                      ActionChip(
                        avatar: Icon(
                          LucideIcons.trash2,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          'admin.bulk_delete'.tr(),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                        onPressed: _onDelete,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
