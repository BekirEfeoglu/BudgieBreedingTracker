import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/features/auth/providers/auth_providers.dart';
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
              onPressed:
                  _isUploading ? null : () => _addPhoto(context, ref),
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const AppIcon(AppIcons.photo, size: 18),
              label: Text(_isUploading
                  ? 'birds.uploading_photo'.tr()
                  : 'birds.add_photo'.tr()),
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
            padding: AppSpacing.screenPadding,
            child: OutlinedButton.icon(
              onPressed:
                  _isUploading ? null : () => _addPhoto(context, ref),
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const AppIcon(AppIcons.photo, size: 18),
              label: Text(_isUploading
                  ? 'birds.uploading_photo'.tr()
                  : 'birds.add_photo'.tr()),
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
      final storage = ref.read(storageServiceProvider);
      // Extract storage path from public URL (userId/birdId/filename)
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final segments = uri.pathSegments;
        // URL format: .../object/public/bird-photos/userId/birdId/filename
        final bucketIdx = segments.indexOf(SupabaseConstants.birdPhotosBucket);
        if (bucketIdx >= 0 && bucketIdx + 3 <= segments.length) {
          final storagePath = segments.sublist(bucketIdx + 1).join('/');
          await storage.deleteBirdPhoto(storagePath: storagePath);
        }
      }
    } catch (e) {
      AppLogger.warning('Failed to delete storage file: $e');
    }

    try {
      await photoRepo.remove(photo.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('birds.photo_deleted'.tr())),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('birds.photo_delete_error'.tr())),
        );
      }
    }
  }

  Future<void> _addPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);

    final userId = ref.read(currentUserIdProvider);
    final storage = ref.read(storageServiceProvider);

    try {
      final url = await storage.uploadBirdPhoto(
        userId: userId,
        birdId: widget.bird.id,
        file: picked,
      );

      final photoRepo = ref.read(photoRepositoryProvider);
      await photoRepo.save(Photo(
        id: const Uuid().v4(),
        userId: userId,
        entityType: PhotoEntityType.bird,
        entityId: widget.bird.id,
        fileName: picked.name,
        filePath: url,
      ));
    } catch (_) {
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
}
