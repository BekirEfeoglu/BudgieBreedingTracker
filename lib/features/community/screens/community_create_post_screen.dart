import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../providers/community_create_providers.dart';

part 'community_create_post_widgets.dart';

/// Screen for creating a new community post.
class CommunityCreatePostScreen extends ConsumerStatefulWidget {
  const CommunityCreatePostScreen({super.key});

  @override
  ConsumerState<CommunityCreatePostScreen> createState() =>
      _CommunityCreatePostScreenState();
}

class _CommunityCreatePostScreenState
    extends ConsumerState<CommunityCreatePostScreen> {
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();
  final _tagController = TextEditingController();
  final _selectedImages = <XFile>[];
  final _tags = <String>[];
  CommunityPostType _postType = CommunityPostType.general;

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (images.isNotEmpty && mounted) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  void _submit() {
    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('community.content_or_image_required'.tr())),
      );
      return;
    }

    ref
        .read(createPostProvider.notifier)
        .createPost(
          content: content,
          postType: _postType,
          title: _titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : null,
          tags: _tags,
          images: _selectedImages,
        );
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createPostProvider);
    final theme = Theme.of(context);

    ref.listen<CreatePostState>(createPostProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(createPostProvider.notifier).reset();
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('community.post_success'.tr())));
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('community.post_error'.tr())));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('community.create_post'.tr()),
        actions: [
          TextButton(
            onPressed: formState.isLoading ? null : _submit,
            child: formState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('community.share_action'.tr()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post type selector
            _PostTypeSelector(
              selected: _postType,
              enabled: !formState.isLoading,
              onChanged: (type) => setState(() => _postType = type),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Title field (optional)
            TextField(
              controller: _titleController,
              maxLength: 200,
              enabled: !formState.isLoading,
              decoration: InputDecoration(
                labelText: 'community.post_title_label'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Content field
            TextField(
              controller: _contentController,
              maxLines: 8,
              maxLength: 1000,
              enabled: !formState.isLoading,
              decoration: InputDecoration(
                hintText: 'community.content_label'.tr(),
                border: InputBorder.none,
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),

            // Tags input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    enabled: !formState.isLoading,
                    decoration: InputDecoration(
                      labelText: 'community.add_tags'.tr(),
                      hintText: 'community.tag_hint'.tr(),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  onPressed: formState.isLoading ? null : _addTag,
                  icon: const Icon(LucideIcons.plus, size: 18),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        onDeleted: formState.isLoading
                            ? null
                            : () => _removeTag(tag),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            // Image previews
            if (_selectedImages.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, index) => _ImagePreview(
                    file: File(_selectedImages[index].path),
                    enabled: !formState.isLoading,
                    onRemove: () => _removeImage(index),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            OutlinedButton.icon(
              onPressed: formState.isLoading ? null : _pickImages,
              icon: const Icon(LucideIcons.image),
              label: Text('community.add_photo'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
