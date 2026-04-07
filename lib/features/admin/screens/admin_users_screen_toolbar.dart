part of 'admin_users_screen.dart';

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
                      const SizedBox(width: AppSpacing.sm),
                      _StatusChip(
                        label: 'admin.premium_users'.tr(),
                        selected: statusFilter == _UserStatusFilter.premium,
                        onTap: () =>
                            onStatusFilterChanged(_UserStatusFilter.premium),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _StatusChip(
                        label: 'admin.free_users'.tr(),
                        selected: statusFilter == _UserStatusFilter.free,
                        onTap: () =>
                            onStatusFilterChanged(_UserStatusFilter.free),
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
