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
    final limit = ref.watch(adminUsersLimitProvider);
    final usersAsync = ref.watch(
      adminUsersProvider(
        AdminUsersQuery(searchTerm: _query, limit: limit),
      ),
    );

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
    );
  }
}
