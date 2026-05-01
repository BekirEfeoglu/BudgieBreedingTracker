import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import 'package:budgie_breeding_tracker/shared/providers/gamification.dart';
import 'package:budgie_breeding_tracker/shared/widgets/app_shell.dart';
import 'package:budgie_breeding_tracker/shared/providers/profile.dart';

/// Profile-centric AppBar for the community screen.
class CommunityAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CommunityAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(92);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final userLevelAsync = ref.watch(userLevelProvider(userId));
    final profile = ref.watch(userProfileProvider).value;
    final theme = Theme.of(context);

    final displayName = profile?.resolvedDisplayName ?? '';
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : (userId.length >= 2
              ? userId.substring(0, 2).toUpperCase()
              : userId.toUpperCase());

    return AppBar(
      toolbarHeight: 92,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      leading: AppIconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        semanticLabel: 'common.back'.tr(),
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              onTap: () => context.push(AppRoutes.profile),
              child: _ProfileAvatar(
                avatarUrl: profile?.avatarUrl,
                initials: initials,
                theme: theme,
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
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
          icon: LucideIcons.messageCircle,
          tooltip: 'messaging.title'.tr(),
          onPressed: () => context.push(AppRoutes.messages),
        ),
        const NotificationBellButton(),
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.84),
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
          ),
        ),
        child: IconButton(
          icon: Icon(icon, size: 18),
          tooltip: tooltip,
          onPressed: onPressed,
          constraints: const BoxConstraints(
            minWidth: AppSpacing.touchTargetMin,
            minHeight: AppSpacing.touchTargetMin,
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final ThemeData theme;

  const _ProfileAvatar({
    required this.avatarUrl,
    required this.initials,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.touchTargetMin,
      height: AppSpacing.touchTargetMin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: avatarUrl == null
            ? LinearGradient(
                colors: [theme.colorScheme.primary, AppColors.accent],
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null
          ? CachedNetworkImage(
              imageUrl: avatarUrl!,
              fit: BoxFit.cover,
              // Avatars render at ~40-64dp; downsample aggressively to
              // avoid caching full-resolution originals.
              memCacheWidth: 192,
              maxWidthDiskCache: 192,
              placeholder: (_, __) =>
                  _InitialsCircle(initials: initials, theme: theme),
              errorWidget: (_, __, ___) =>
                  _InitialsCircle(initials: initials, theme: theme),
            )
          : _InitialsCircle(initials: initials, theme: theme),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final String initials;
  final ThemeData theme;

  const _InitialsCircle({required this.initials, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
