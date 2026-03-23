import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';

/// Horizontal photo strip for bird detail; tapping opens a full-screen gallery.
class BirdPhotoGallery extends StatelessWidget {
  final List<String> photoUrls;
  final ValueChanged<String>? onDeletePhoto;

  const BirdPhotoGallery({
    super.key,
    required this.photoUrls,
    this.onDeletePhoto,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('birds.photos'.tr(), style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => _PhotoThumbnail(
                url: photoUrls[index],
                onTap: () => _openGallery(context, index),
                onDelete: onDeletePhoto != null
                    ? () => onDeletePhoto!(photoUrls[index])
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openGallery(BuildContext context, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenGallery(
          photoUrls: photoUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final String url;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _PhotoThumbnail({
    required this.url,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: CachedNetworkImage(
                imageUrl: url,
                width: 120,
                height: 120,
                memCacheWidth: 240,
                memCacheHeight: 240,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(
                        AppIcons.bird,
                        size: 36,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Icon(
                        LucideIcons.wifiOff,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (onDelete != null)
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  width: AppSpacing.touchTargetMin,
                  height: AppSpacing.touchTargetMin,
                  child: GestureDetector(
                    onTap: onDelete,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.85,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                      ),
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

class _FullScreenGallery extends StatefulWidget {
  final List<String> photoUrls;
  final int initialIndex;

  const _FullScreenGallery({
    required this.photoUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int _currentIndex;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.galleryBackground(context);
    final fgColor = Theme.of(context).colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        title: Text(
          '${_currentIndex + 1} / ${widget.photoUrls.length}',
          style: TextStyle(color: fgColor),
        ),
      ),
      body: PhotoViewGallery.builder(
        itemCount: widget.photoUrls.length,
        pageController: _pageController,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(widget.photoUrls[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            heroAttributes: PhotoViewHeroAttributes(
              tag: widget.photoUrls[index],
            ),
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: BoxDecoration(color: bgColor),
        loadingBuilder: (_, __) =>
            const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
