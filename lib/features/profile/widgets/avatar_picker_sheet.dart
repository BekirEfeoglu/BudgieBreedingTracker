import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/profile_providers.dart';

/// Shows a bottom sheet for picking an avatar image.
///
/// Options: Gallery, Camera, Remove (if avatar exists).
Future<void> showAvatarPickerSheet(
  BuildContext context, {
  required WidgetRef ref,
  required bool hasAvatar,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (ctx) => _AvatarPickerContent(
      ref: ref,
      hasAvatar: hasAvatar,
    ),
  );
}

class _AvatarPickerContent extends StatelessWidget {
  const _AvatarPickerContent({
    required this.ref,
    required this.hasAvatar,
  });

  final WidgetRef ref;
  final bool hasAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title
            Text(
              'profile.edit_avatar'.tr(),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),

            // Gallery option
            ListTile(
              leading: const AppIcon(AppIcons.photo),
              title: Text('profile.avatar_source_gallery'.tr()),
              onTap: () => _pickImage(context, ImageSource.gallery),
            ),

            // Camera option
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: Text('profile.avatar_source_camera'.tr()),
              onTap: () => _pickImage(context, ImageSource.camera),
            ),

            // Remove option (only if avatar exists)
            if (hasAvatar)
              ListTile(
                leading: AppIcon(AppIcons.delete,
                    color: theme.colorScheme.error),
                title: Text(
                  'profile.avatar_remove'.tr(),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => _confirmRemove(context),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    Navigator.of(context).pop();

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (file != null) {
      HapticFeedback.lightImpact();
      ref.read(avatarUploadStateProvider.notifier).uploadAvatar(file);
    }
  }

  Future<void> _confirmRemove(BuildContext context) async {
    Navigator.of(context).pop();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.avatar_remove'.tr()),
        content: Text('profile.avatar_remove_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(avatarUploadStateProvider.notifier).removeAvatar();
    }
  }
}
