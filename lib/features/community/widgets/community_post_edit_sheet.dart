import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../data/models/community_post_model.dart';

/// Bottom sheet for content-only post editing (5-minute window).
/// Returns the new content, or null when dismissed/unchanged.
Future<String?> showCommunityPostEditSheet(
  BuildContext context,
  CommunityPost post,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _PostEditSheet(initialContent: post.content),
  );
}

class _PostEditSheet extends StatefulWidget {
  const _PostEditSheet({required this.initialContent});

  final String initialContent;

  @override
  State<_PostEditSheet> createState() => _PostEditSheetState();
}

class _PostEditSheetState extends State<_PostEditSheet> {
  static const _maxLength = 5000;
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialContent,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || text == widget.initialContent.trim()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'community.edit_post_title'.tr(),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 8,
            maxLength: _maxLength,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: _submit, child: Text('common.save'.tr())),
        ],
      ),
    );
  }
}
