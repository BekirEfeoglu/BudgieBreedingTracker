import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_constants.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

class AiImagePickerZone extends StatelessWidget {
  const AiImagePickerZone({
    super.key,
    required this.onImageSelected,
    required this.onImageCleared,
    required this.selectedImagePath,
    this.tips = const [],
    this.previewHeight = 140.0,
  });

  final ValueChanged<String> onImageSelected;
  final VoidCallback onImageCleared;
  final String? selectedImagePath;
  final List<String> tips;
  final double previewHeight;

  static const _maxBytes = AppConstants.maxLocalAiImageBytes;
  static final _maxMb = (_maxBytes / (1024 * 1024)).round();

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: source, imageQuality: 85);
    if (result == null) return;
    final file = File(result.path);
    final fileSize = await file.length();
    if (fileSize > _maxBytes) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'genetics.ai_image_too_large_warning'.tr(args: ['$_maxMb']),
          ),
        ),
      );
      return;
    }
    onImageSelected(result.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedImagePath != null) {
      return _buildPreview(context, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropZone(context, theme),
        if (tips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildTips(theme),
        ],
      ],
    );
  }

  Widget _buildDropZone(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.camera,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'genetics.select_image'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _pickImage(ImageSource.camera, context),
                icon: const Icon(LucideIcons.camera, size: 18),
                label: Text('genetics.ai_camera'.tr()),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery, context),
                icon: const Icon(LucideIcons.image, size: 18),
                label: Text('genetics.ai_gallery'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
            child: Image.file(
              File(selectedImagePath!),
              height: previewHeight,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: previewHeight * 0.7,
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Text('common.error'.tr()),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _shortFileName(
                      selectedImagePath!.split(Platform.pathSeparator).last,
                    ),
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ActionChip(
                  onPressed: () => _pickImage(ImageSource.gallery, context),
                  avatar: const Icon(LucideIcons.refreshCw, size: 14),
                  label: Text('genetics.ai_change_image'.tr()),
                ),
                const SizedBox(width: AppSpacing.xs),
                ActionChip(
                  onPressed: onImageCleared,
                  avatar: const Icon(LucideIcons.x, size: 14),
                  label: Text('common.clear'.tr()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTips(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.lightbulb, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'genetics.ai_photo_tips_title'.tr(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('  \u2022 ', style: theme.textTheme.bodySmall),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortFileName(String value) {
    if (value.length <= 32) return value;
    return '${value.substring(0, 14)}...${value.substring(value.length - 14)}';
  }
}
