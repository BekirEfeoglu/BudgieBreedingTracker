import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/community_comment_providers.dart';

/// Fixed bottom input bar for adding comments.
class CommunityCommentInput extends ConsumerStatefulWidget {
  final String postId;

  const CommunityCommentInput({super.key, required this.postId});

  @override
  ConsumerState<CommunityCommentInput> createState() =>
      _CommunityCommentInputState();
}

class _CommunityCommentInputState extends ConsumerState<CommunityCommentInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    ref
        .read(commentFormProvider.notifier)
        .addComment(postId: widget.postId, content: text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(commentFormProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !formState.isLoading,
                maxLength: 1000,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'community.add_comment'.tr(),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  isDense: true,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: formState.isLoading ? null : _submit,
              icon: formState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(LucideIcons.send, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
