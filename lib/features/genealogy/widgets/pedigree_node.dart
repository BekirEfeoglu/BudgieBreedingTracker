import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/utils/navigation_throttle.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

/// Single node in the pedigree tree displaying bird info.
///
/// Supports tappable navigation, root emphasis, status indicator,
/// color mutation chip, and age display.
class PedigreeNode extends StatelessWidget {
  final Bird? bird;
  final String placeholder;
  final bool isRoot;
  final bool isCommonAncestor;
  final int siblingCount;
  final int depth;
  final VoidCallback? onTap;

  const PedigreeNode({
    super.key,
    this.bird,
    this.placeholder = '?',
    this.isRoot = false,
    this.isCommonAncestor = false,
    this.siblingCount = 0,
    this.depth = 0,
    this.onTap,
  });

  static const _normalWidth = 130.0;
  static const _rootWidth = 160.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bird == null) {
      return _buildEmptyNode(theme);
    }

    final width = isRoot ? _rootWidth : _normalWidth;

    Widget nodeWidget = GestureDetector(
      onTap:
          onTap ??
          () {
            if (!NavigationThrottle.canNavigate()) return;
            context.push('/birds/${bird!.id}');
          },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isCommonAncestor
              ? AppColors.warning.withValues(alpha: 0.12)
              : _genderBackgroundColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isCommonAncestor ? AppColors.warning : _genderBorderColor,
            width: isCommonAncestor ? 2.5 : (isRoot ? 2.5 : 1.5),
          ),
          boxShadow: [
            if (isCommonAncestor)
              BoxShadow(
                color: AppColors.warning.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: (isRoot ? _genderBorderColor : theme.shadowColor)
                    .withValues(alpha: isRoot ? 0.15 : 0.06),
                blurRadius: isRoot ? 6 : 3,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _genderIconWidget,
                const SizedBox(height: AppSpacing.xs),
                Text(
                  bird!.name,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bird!.ringNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    bird!.ringNumber!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (bird!.colorMutation != null) ...[
                  const SizedBox(height: 3),
                  _buildMutationChip(theme),
                ],
                if (_ageText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _ageText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (siblingCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'genealogy.siblings_count'.tr(
                      args: [siblingCount.toString()],
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
            // Status indicator dot (top-right)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 1,
                  ),
                ),
              ),
            ),
            // Generation depth badge (top-left)
            if (depth >= 2)
              Positioned(
                top: -6,
                left: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'G$depth',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Pulse animation for common ancestors
    if (isCommonAncestor) {
      nodeWidget = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: nodeWidget,
      );
    }

    return nodeWidget;
  }

  Widget _buildEmptyNode(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: _normalWidth,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.neutral800 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.neutral600 : AppColors.neutral300,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.userPlus,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            placeholder,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMutationChip(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: _genderBorderColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        bird!.colorMutation!.name,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: _genderBorderColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget get _genderIconWidget => switch (bird?.gender) {
    BirdGender.male => const AppIcon(
      AppIcons.male,
      size: 16,
      color: AppColors.genderMale,
    ),
    BirdGender.female => const AppIcon(
      AppIcons.female,
      size: 16,
      color: AppColors.genderFemale,
    ),
    _ => const Icon(
      LucideIcons.helpCircle,
      size: 16,
      color: AppColors.genderUnknown,
    ),
  };

  Color get _genderBackgroundColor => switch (bird?.gender) {
    BirdGender.male => AppColors.genderMale,
    BirdGender.female => AppColors.genderFemale,
    _ => AppColors.genderUnknown,
  };

  Color get _genderBorderColor => switch (bird?.gender) {
    BirdGender.male => AppColors.genderMale,
    BirdGender.female => AppColors.genderFemale,
    _ => AppColors.neutral400,
  };

  Color get _statusColor => switch (bird?.status) {
    BirdStatus.alive => AppColors.success,
    BirdStatus.dead => AppColors.error,
    BirdStatus.sold => AppColors.warning,
    _ => AppColors.neutral400,
  };

  String? get _ageText {
    final age = bird?.age;
    if (age == null) return null;
    return 'genealogy.age_short'.tr(
      args: [age.years.toString(), age.months.toString()],
    );
  }
}
