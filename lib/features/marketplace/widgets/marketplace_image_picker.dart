import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';

class MarketplaceImagePicker extends StatelessWidget {
  const MarketplaceImagePicker({
    super.key,
    required this.imagePaths,
    required this.onChanged,
  });

  static const int maxImages = 3;

  final List<String> imagePaths;
  final ValueChanged<List<String>> onChanged;

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final remaining = maxImages - imagePaths.length;
    if (remaining <= 0) return;

    final picked = await picker.pickMultiImage(
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (picked.isEmpty) return;

    final newPaths = picked.take(remaining).map((f) => f.path).toList();
    onChanged([...imagePaths, ...newPaths]);
  }

  void _removeImage(int index) {
    final updated = List<String>.from(imagePaths)..removeAt(index);
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'marketplace.add_photos'.tr(),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'marketplace.photo_count'.tr(args: ['${imagePaths.length}']),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...List.generate(imagePaths.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _ImageTile(
                    path: imagePaths[index],
                    isCover: index == 0,
                    onRemove: () => _removeImage(index),
                  ),
                );
              }),
              if (imagePaths.length < maxImages)
                _AddButton(onTap: () => _pickImages(context)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.path,
    required this.isCover,
    required this.onRemove,
  });

  final String path;
  final bool isCover;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Image.file(
              File(path),
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 100,
                height: 100,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  LucideIcons.imageOff,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          if (isCover)
            Positioned(
              bottom: AppSpacing.xs,
              left: AppSpacing.xs,
              right: AppSpacing.xs,
              child: _CoverBadge(),
            ),
          Positioned(
            top: AppSpacing.xs,
            right: AppSpacing.xs,
            child: _RemoveButton(onTap: onRemove),
          ),
        ],
      ),
    );
  }
}

class _CoverBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        'marketplace.cover_photo'.tr(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontSize: 9,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.85),
          shape: BoxShape.circle,
        ),
        child: Icon(
          LucideIcons.x,
          size: 12,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.plus,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
