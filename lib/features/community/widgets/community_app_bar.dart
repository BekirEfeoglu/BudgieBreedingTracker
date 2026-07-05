import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../domain/services/gamification/level_calculator.dart';
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
                  // Every user is at least Lv.1 — fall back to it (with the
                  // level-1 title) so the badge always shows, like the design.
                  data: (level) {
                    final lvl = level?.level ?? 1;
                    final titleKey = (level != null && level.title.isNotEmpty)
                        ? level.title
                        : LevelCalculator.titleForLevel(lvl);
                    return _LevelBadge(level: lvl, titleKey: titleKey);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _ActionIcon(
          icon: const Icon(LucideIcons.messageCircle, size: 18),
          tooltip: 'messaging.title'.tr(),
          onPressed: () => context.push(AppRoutes.messages),
        ),
        const NotificationBellButton(),
        _ActionIcon(
          icon: const AppIcon(AppIcons.search, size: 18),
          tooltip: 'community.search'.tr(),
          onPressed: () => context.push(AppRoutes.communitySearch),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}

/// Amber "★ Lv.X · Title" badge under the "Topluluk" app-bar title.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.titleKey});

  final int level;
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = titleKey.tr();
    final label = title.isEmpty
        ? '${'community.level_prefix'.tr()}$level'
        : '${'community.level_prefix'.tr()}$level · $title';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.star, size: 12, color: AppColors.accent),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.warningTextAdaptive(context),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final Widget icon;
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
          icon: icon,
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
    // Gradient ring around the avatar (blue → amber), matching the design's
    // profile chip. The image / initials sit inside the ring.
    return Container(
      width: AppSpacing.touchTargetMin,
      height: AppSpacing.touchTargetMin,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, AppColors.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
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
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final String initials;
  final ThemeData theme;

  const _InitialsCircle({required this.initials, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: theme.colorScheme.primaryContainer,
      child: Center(
        child: Text(
          initials,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
