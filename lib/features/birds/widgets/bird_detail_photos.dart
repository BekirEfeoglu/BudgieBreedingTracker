import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_photo_gallery.dart';

/// Photo section for bird detail screen with gallery and add button.
class BirdDetailPhotos extends ConsumerStatefulWidget {
  final Bird bird;

  const BirdDetailPhotos({super.key, required this.bird});

  @override
  ConsumerState<BirdDetailPhotos> createState() => _BirdDetailPhotosState();
}

class _BirdDetailPhotosState extends ConsumerState<BirdDetailPhotos> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(birdPhotosProvider(widget.bird.id));

    return photosAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'birds.photos_load_error'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _isUploading ? null : () => _addPhoto(context, ref),
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const AppIcon(AppIcons.photo, size: 18),
              label: Text(
                _isUploading
                    ? 'birds.uploading_photo'.tr()
                    : 'birds.add_photo'.tr(),
              ),
            ),
          ],
        ),
      ),
      data: (urls) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (urls.isNotEmpty)
            BirdPhotoGallery(
              photoUrls: urls,
              onDeletePhoto: (url) => _deletePhoto(context, ref, url),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Row(
              children: [
                if (urls.isEmpty) const SizedBox(width: 116),
                Flexible(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppSpacing.touchTargetMin),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _isUploading
                        ? null
                        : () => _addPhoto(context, ref),
                    icon: _isUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const AppIcon(AppIcons.photo, size: 18),
                    label: Text(
                      _isUploading
                          ? 'birds.uploading_photo'.tr()
                          : 'birds.add_photo'.tr(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePhoto(
    BuildContext context,
    WidgetRef ref,
    String url,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'birds.delete_photo'.tr(),
      message: 'birds.confirm_delete_photo'.tr(),
      confirmLabel: 'common.delete'.tr(),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final photoRepo = ref.read(photoRepositoryProvider);
    final photos = await photoRepo.getByEntity(widget.bird.id);
    final photo = photos.where((p) => p.filePath == url).firstOrNull;

    if (photo == null) return;

    try {
      await photoRepo.deleteStorageForPhoto(photo);
    } catch (e) {
      AppLogger.warning('Failed to delete storage file: $e');
    }

    try {
      await photoRepo.remove(photo.id);
      if (context.mounted) {
        ActionFeedbackService.show('birds.photo_deleted'.tr());
      }
    } catch (e) {
      AppLogger.error('[BirdDetailPhotos]', e, StackTrace.current);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('birds.photo_delete_error'.tr())),
        );
      }
    }
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final source = await _pickPhotoSource(context);
    if (source == null) return;

    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
    } catch (e) {
      AppLogger.warning('Failed to pick bird photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('birds.photo_upload_error'.tr())),
        );
      }
      return;
    }

    if (picked == null) return;
    if (!mounted) return;

    setState(() => _isUploading = true);

    final userId = ref.read(currentUserIdProvider);
    final photoRepo = ref.read(photoRepositoryProvider);

    try {
      final url = await photoRepo.uploadBirdPhoto(
        userId: userId,
        birdId: widget.bird.id,
        file: picked,
      );

      await photoRepo.save(
        Photo(
          id: const Uuid().v7(),
          userId: userId,
          entityType: PhotoEntityType.bird,
          entityId: widget.bird.id,
          fileName: picked.name,
          filePath: url,
        ),
      );
    } catch (e) {
      AppLogger.error('[BirdDetailPhotos]', e, StackTrace.current);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('birds.photo_upload_error'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<ImageSource?> _pickPhotoSource(BuildContext context) {
    final theme = Theme.of(context);

    return showModalBottomSheet<ImageSource>(
      context: context,
      constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'birds.add_photo'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: const AppIcon(AppIcons.photo),
                title: Text('birds.photo_source_gallery'.tr()),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: Text('birds.photo_source_camera'.tr()),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
