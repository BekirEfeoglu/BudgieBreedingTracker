import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../data/providers/action_feedback_providers.dart';
import '../providers/community_create_providers.dart';

part 'community_create_post_widgets.dart';

/// Screen for creating a new community post.
class CommunityCreatePostScreen extends ConsumerStatefulWidget {
  final CommunityPostType initialPostType;

  const CommunityCreatePostScreen({
    super.key,
    this.initialPostType = CommunityPostType.general,
  });

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
  late CommunityPostType _postType;

  static const _draftKey = 'community_post_draft';
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _postType = widget.initialPostType == CommunityPostType.unknown
        ? CommunityPostType.general
        : widget.initialPostType;
    _titleController.addListener(_scheduleDraftSave);
    _contentController.addListener(_scheduleDraftSave);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkDraft());
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _contentController.dispose();
    _titleController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // ── Draft helpers ──────────────────────────────────────────────────────────

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 2), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode({
      'title': _titleController.text,
      'content': _contentController.text,
      'postType': _postType.toJson(),
      'tags': _tags,
    });
    await prefs.setString(_draftKey, data);
  }

  Future<Map<String, dynamic>?> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  Future<void> _checkDraft() async {
    final draft = await _loadDraft();
    if (draft == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('community.draft_found'.tr()),
        content: Text('community.draft_found_hint'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('community.draft_discard'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('community.draft_continue'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _titleController.text = draft['title'] as String? ?? '';
      _contentController.text = draft['content'] as String? ?? '';
      final typeStr = draft['postType'] as String? ?? 'general';
      _postType = CommunityPostType.values.firstWhere(
        (e) => e.toJson() == typeStr,
        orElse: () => CommunityPostType.general,
      );
      _tags
        ..clear()
        ..addAll(List<String>.from(draft['tags'] as List? ?? []));
      setState(() {});
    } else {
      await _clearDraft();
    }
  }

  // ── Image helpers ──────────────────────────────────────────────────────────

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

  // ── Tag helpers ────────────────────────────────────────────────────────────

  static const _maxTagLength = 50;
  static const _maxTagCount = 10;

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase();
    if (tag.isEmpty || tag.length > _maxTagLength) return;
    if (_tags.length >= _maxTagCount || _tags.contains(tag)) return;
    setState(() {
      _tags.add(tag);
      _tagController.clear();
    });
    _scheduleDraftSave();
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    _scheduleDraftSave();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    AppHaptics.mediumImpact();
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(createPostProvider);
    final theme = Theme.of(context);

    ref.listen<CreatePostState>(createPostProvider, (_, state) async {
      if (!mounted) return;
      if (state.isSuccess) {
        ref.read(createPostProvider.notifier).reset();
        await _clearDraft();
        if (!mounted) return;
        Navigator.of(context).pop();
        ActionFeedbackService.show('community.post_success'.tr());
      }
      if (state.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error ?? 'community.post_error'.tr()),
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final hasContent = _titleController.text.isNotEmpty ||
            _contentController.text.isNotEmpty ||
            _tags.isNotEmpty ||
            _selectedImages.isNotEmpty;
        if (!hasContent) {
          Navigator.pop(context);
          return;
        }
        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('community.unsaved_changes'.tr()),
            content: Text('community.unsaved_changes_hint'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('community.stay'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('community.exit'.tr()),
              ),
            ],
          ),
        );
        if (shouldLeave == true && mounted) {
          await _clearDraft();
          if (!mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
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
                onChanged: (type) {
                  setState(() => _postType = type);
                  _scheduleDraftSave();
                },
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
                maxLength: 5000,
                enabled: !formState.isLoading,
                decoration: InputDecoration(
                  hintText: _contentHint,
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
      ),
    );
  }

  String get _contentHint => switch (_postType) {
    CommunityPostType.photo => 'community.quick_hint'.tr(),
    CommunityPostType.question => 'community.quick_hint'.tr(),
    CommunityPostType.guide => 'community.quick_hint'.tr(),
    _ => 'community.content_label'.tr(),
  };
}
