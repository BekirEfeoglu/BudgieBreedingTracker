import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/feature_flags.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../data/models/profile_model.dart';
import '../../../data/providers/auth_state_providers.dart';
import '../../../data/providers/profile_stream_providers.dart';
import '../../../domain/services/gamification/level_calculator.dart';
import '../../../router/route_names.dart';
import 'package:budgie_breeding_tracker/shared/providers/gamification.dart';
import 'package:budgie_breeding_tracker/shared/widgets/gamification.dart';
import '../providers/community_providers.dart';
import '../providers/community_search_providers.dart';
import 'community_filter_sheet.dart';

class CommunityAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  const CommunityAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  ConsumerState<CommunityAppBar> createState() => _CommunityAppBarState();
}

class _CommunityAppBarState extends ConsumerState<CommunityAppBar> {
  bool _isSearchActive = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() {
      _isSearchActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    setState(() {
      _isSearchActive = false;
      _searchController.clear();
    });
  }

  void _toggleSearch() {
    if (_isSearchActive) {
      _closeSearch();
    } else {
      _openSearch();
    }
  }

  void _submitSearch(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) return;

    ref.read(communitySearchProvider.notifier).setQuery(query);
    unawaited(
      ref.read(communitySearchHistoryProvider.notifier).addQuery(query),
    );
    _closeSearch();
    context.push(
      '${AppRoutes.communitySearch}?q=${Uri.encodeComponent(query)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentUserIdProvider);
    final userLevelAsync = ref.watch(userLevelProvider(userId));
    final activeTab = ref.watch(communityActiveTabProvider);
    final canPop = Navigator.canPop(context);
    final levelBadge = userLevelAsync.maybeWhen<Widget?>(
      data: (level) {
        final lvl = level?.level ?? 1;
        final titleKey = (level != null && level.title.isNotEmpty)
            ? level.title
            : LevelCalculator.titleForLevel(lvl);
        return _LevelBadge(level: lvl, titleKey: titleKey);
      },
      orElse: () => null,
    );

    return AppBar(
      toolbarHeight: 72,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      automaticallyImplyLeading: false,
      leading: canPop
          ? AppIconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              semanticLabel: 'common.back'.tr(),
              onPressed: () => context.pop(),
            )
          : null,
      leadingWidth: canPop ? 56 : 16,
      titleSpacing: 0,
      title: _isSearchActive
          ? _buildSearchBar(theme)
          : _CommunityAppBarTitle(
              showCommunityIcon: !canPop,
              levelBadge: levelBadge,
            ),
      actions: [
        if (!_isSearchActive && activeTab == CommunityFeedTab.explore)
          _ActionIcon(
            icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
            tooltip: 'common.sort'.tr(),
            onPressed: () => showCommunityFilterSheet(context),
          ),
        if (!_isSearchActive && FeatureFlags.messagingEnabled)
          _ActionIcon(
            icon: const Icon(LucideIcons.messageCircle, size: 18),
            tooltip: 'messaging.title'.tr(),
            onPressed: () => context.push(AppRoutes.messages),
          ),
        _ActionIcon(
          icon: Icon(
            _isSearchActive ? LucideIcons.x : LucideIcons.search,
            size: 18,
          ),
          tooltip: _isSearchActive
              ? 'common.cancel'.tr()
              : 'community.search'.tr(),
          onPressed: _toggleSearch,
        ),
        if (!_isSearchActive) const _CommunityProfileButton(),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: _submitSearch,
        decoration: InputDecoration(
          hintText: 'community.search'.tr(),
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
        ),
      ),
    );
  }
}

class _CommunityAppBarTitle extends StatelessWidget {
  const _CommunityAppBarTitle({
    required this.showCommunityIcon,
    required this.levelBadge,
  });

  final bool showCommunityIcon;
  final Widget? levelBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final showIcon = showCommunityIcon && constraints.maxWidth >= 176;
        final showLevelBadge =
            levelBadge != null &&
            constraints.maxWidth >= (showIcon ? 238 : 188);

        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            if (showIcon) ...[
              const SizedBox(width: AppSpacing.md),
              const AppIcon(AppIcons.community, size: 20),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Text(
                'community.title'.tr(),
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showLevelBadge) ...[
              const SizedBox(width: AppSpacing.sm),
              levelBadge!,
            ],
          ],
        );
      },
    );
  }
}

/// Amber inline pill badge showing "Lv.X" next to the rank icon.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level, required this.titleKey});

  final int level;
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningTextAdaptive(context).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(
          color: AppColors.warningTextAdaptive(context).withValues(alpha: 0.28),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedRankIcon(
            iconAsset: AppIcons.getLevelIcon(titleKey),
            size: 12,
            isAnimated: false,
          ),
          const SizedBox(width: 4),
          Text(
            '${'community.level_prefix'.tr()}$level',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.warningTextAdaptive(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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

class _CommunityProfileButton extends ConsumerWidget {
  const _CommunityProfileButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => _CommunityAvatarButton(userId: userId, profile: null),
      error: (_, __) => _CommunityAvatarButton(userId: userId, profile: null),
      data: (profile) =>
          _CommunityAvatarButton(userId: userId, profile: profile),
    );
  }
}

class _CommunityAvatarButton extends StatelessWidget {
  const _CommunityAvatarButton({required this.userId, required this.profile});

  final String userId;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    final profileDisplayName = profile?.resolvedDisplayName;
    final profileAvatarUrl = profile?.avatarUrl;
    final displayName = profileDisplayName?.trim().isNotEmpty == true
        ? profileDisplayName!
        : userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Tooltip(
        message: 'community.my_profile'.tr(),
        child: Semantics(
          button: true,
          label: 'community.my_profile'.tr(),
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: userId == 'anonymous'
                  ? null
                  : () => context.push(AppRoutes.profile),
              radius: AppSpacing.touchTargetMin / 2,
              containedInkWell: false,
              child: _CommunityAvatar(
                displayName: displayName,
                avatarUrl: profileAvatarUrl,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityAvatar extends StatelessWidget {
  const _CommunityAvatar({required this.displayName, required this.avatarUrl});

  final String displayName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials(displayName);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSpacing.touchTargetMin,
        minHeight: AppSpacing.touchTargetMin,
      ),
      child: Center(
        child: CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primary,
          backgroundImage: avatarUrl != null
              ? CachedNetworkImageProvider(
                  avatarUrl!,
                  maxWidth: 72,
                  maxHeight: 72,
                )
              : null,
          child: avatarUrl == null
              ? Text(
                  initials,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }
}
