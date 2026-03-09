import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

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
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => _PhotoThumbnail(
                url: photoUrls[index],
                onTap: () => _openGallery(context, index),
                onLongPress: onDeletePhoto != null
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
  final VoidCallback? onLongPress;

  const _PhotoThumbnail({
    required this.url,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 120,
          height: 120,
          memCacheWidth: 240,
          memCacheHeight: 240,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            width: 120,
            height: 120,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(LucideIcons.imageOff, size: 32),
          ),
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
        loadingBuilder: (_, __) => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
