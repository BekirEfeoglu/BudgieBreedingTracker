import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/animations/shimmer_shine_animation.dart';
import '../../../core/widgets/app_icon.dart';

/// Circular avatar with optional image URL, fallback to icon.
///
/// Shows a loading spinner overlay when [isUploading] is true.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.radius = 48,
    this.onTap,
    this.isUploading = false,
    this.isPremium = false,
  });

  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;
  final bool isUploading;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Ana avatar widget'ını ayrı değişkende tutalım.
    final Widget avatarCore = CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      backgroundImage: imageUrl != null
          ? CachedNetworkImageProvider(
              imageUrl!,
              maxWidth: (radius * 4).toInt(),
              maxHeight: (radius * 4).toInt(),
            )
          : null,
      child: imageUrl == null
          ? AppIcon(
              AppIcons.profile,
              size: radius,
              color: theme.colorScheme.onPrimaryContainer,
            )
          : null,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSpacing.touchTargetMin,
        minHeight: AppSpacing.touchTargetMin,
      ),
      child: GestureDetector(
        onTap: isUploading ? null : onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isPremium)
              ShimmerShineAnimation(
                isActive: true,
                duration: const Duration(seconds: 3),
                shineColor: theme.colorScheme.surface,
                child: Container(
                  width: (radius * 2) + 8,
                  height: (radius * 2) + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.accent,
                        AppColors.primary,
                        AppColors.accent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            // Biraz beyaz aralık (Border gibi)
            if (isPremium)
              Container(
                width: (radius * 2) + 4,
                height: (radius * 2) + 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surface,
                ),
              ),
            avatarCore,
            if (isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.shadowColor.withValues(alpha: 0.4),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
