import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../../gamification/providers/gamification_providers.dart';

/// Profile-centric AppBar for the community screen.
class CommunityAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CommunityAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final userLevelAsync = ref.watch(userLevelProvider(userId));
    final theme = Theme.of(context);

    final initials = userId.length >= 2
        ? userId.substring(0, 2).toUpperCase()
        : userId.toUpperCase();

    return AppBar(
      titleSpacing: AppSpacing.sm,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary,
                ],
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'community.title'.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                userLevelAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (level) {
                    if (level == null) return const SizedBox.shrink();
                    return Text(
                      'Lv.${level.level} · ${level.title.isNotEmpty ? level.title.tr() : ''}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _ActionIcon(
          icon: LucideIcons.store,
          tooltip: 'marketplace.title'.tr(),
          onPressed: () => context.push(AppRoutes.marketplace),
        ),
        _ActionIcon(
          icon: LucideIcons.messageCircle,
          tooltip: 'messaging.title'.tr(),
          onPressed: () => context.push(AppRoutes.messages),
        ),
        _ActionIcon(
          icon: LucideIcons.bell,
          tooltip: 'notifications.title'.tr(),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        _ActionIcon(
          icon: LucideIcons.search,
          tooltip: 'community.search'.tr(),
          onPressed: () => context.push(AppRoutes.communitySearch),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, size: 18),
          tooltip: tooltip,
          onPressed: onPressed,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          padding: const EdgeInsets.all(7),
        ),
      ),
    );
  }
}
