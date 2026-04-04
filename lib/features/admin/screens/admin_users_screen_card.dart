part of 'admin_users_screen.dart';

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onSelectionToggle;
  final void Function(String action, String userId)? onQuickAction;

  const _UserCard({
    required this.user,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectionToggle,
    this.onQuickAction,
  });

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
    final isProtected = _isProtectedRole(user.role);

    return Card(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: isSelectionMode
            ? onSelectionToggle
            : () => context.push(
                  AppRoutes.adminUserDetail.replaceFirst(':userId', user.id),
                ),
        onLongPress: onSelectionToggle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => onSelectionToggle?.call(),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
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
                        if (user.isPremium || isProtected) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _PremiumBadge(
                            role: user.role,
                            isPremium: user.isPremium,
                          ),
                        ],
                        if (!user.isActive) ...[
                          const SizedBox(width: AppSpacing.xs),
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
                      const SizedBox(height: AppSpacing.xs / 2),
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
              const SizedBox(width: AppSpacing.xs),
              if (!isSelectionMode)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
                  icon: Icon(
                    LucideIcons.moreVertical,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                  onSelected: (action) =>
                      onQuickAction?.call(action, user.id),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: user.isActive ? 'deactivate' : 'activate',
                      child: Row(
                        children: [
                          Icon(
                            user.isActive
                                ? LucideIcons.userMinus
                                : LucideIcons.userCheck,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            user.isActive
                                ? 'admin.deactivate_user'.tr()
                                : 'admin.activate_user'.tr(),
                          ),
                        ],
                      ),
                    ),
                    if (!isProtected) ...[
                      PopupMenuItem(
                        value: user.isPremium
                            ? 'revoke_premium'
                            : 'grant_premium',
                        child: Row(
                          children: [
                            AppIcon(
                              AppIcons.premium,
                              size: 16,
                              color: user.isPremium
                                  ? AppColors.error
                                  : AppColors.accent,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              user.isPremium
                                  ? 'admin.revoke_premium'.tr()
                                  : 'admin.grant_premium'.tr(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isProtectedRole(String? role) {
    if (role == null) return false;
    final r = role.toLowerCase().trim();
    return r == 'founder' || r == 'admin';
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy', locale).format(date);
  }
}

class _PremiumBadge extends StatelessWidget {
  final String? role;
  final bool isPremium;
  const _PremiumBadge({this.role, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = role?.toLowerCase().trim();
    final isFounder = r == 'founder';
    final isAdmin = r == 'admin';

    final label = isFounder
        ? 'Founder'
        : isAdmin
            ? 'Admin'
            : 'Premium';
    final color = isFounder
        ? AppColors.accent
        : isAdmin
            ? AppColors.info
            : AppColors.budgieYellow;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
