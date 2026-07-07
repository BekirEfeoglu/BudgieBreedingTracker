import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
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
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    // Clear the field only after the comment is accepted. Clearing eagerly
    // (before this fire-and-forget call resolved) wiped the user's draft when
    // the submit was rejected async — moderation, cooldown, or network — and
    // they had to retype it. Mirrors the messaging input-bar fix.
    final replyToComment = ref.read(replyToCommentProvider);
    final accepted = await ref
        .read(commentFormProvider.notifier)
        .addComment(
          postId: widget.postId,
          content: text,
          parentId: replyToComment?.id,
        );
    if (!mounted || !accepted) return;
    _controller.clear();
    if (replyToComment != null) {
      ref.read(replyToCommentProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(commentFormProvider);
    final replyToComment = ref.watch(replyToCommentProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isFocused = _focusNode.hasFocus;
    final hasText = _controller.text.trim().isNotEmpty;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: isFocused
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.dividerColor,
              width: isFocused ? 1.5 : 1.0,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToComment != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.reply,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'community.replying_to'.tr(
                          namedArgs: {'user': replyToComment.username},
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AppIconButton(
                      onPressed: () {
                        ref.read(replyToCommentProvider.notifier).state = null;
                      },
                      icon: Icon(
                        LucideIcons.x,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      semanticLabel: 'common.cancel'.tr(),
                    ),
                  ],
                ),
              ),
            SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !formState.isLoading,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: replyToComment != null
                            ? 'community.add_reply'.tr()
                            : 'community.add_comment'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXl,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        isDense: true,
                      ),
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) {
                            if (currentLength < 800) return null;
                            final isNearLimit = currentLength >= 950;
                            return Text(
                              '$currentLength/$maxLength',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isNearLimit
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (formState.isLoading)
                    SizedBox.square(
                      dimension: AppSpacing.touchTargetMin,
                      child: Center(
                        child: SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            semanticsLabel: 'common.loading'.tr(),
                          ),
                        ),
                      ),
                    )
                  else
                    AnimatedOpacity(
                      opacity: hasText ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 150),
                      child: AnimatedScale(
                        scale: hasText ? 1.0 : 0.9,
                        duration: const Duration(milliseconds: 150),
                        child: AppIconButton(
                          onPressed: hasText ? _submit : null,
                          icon: Icon(
                            LucideIcons.send,
                            color: theme.colorScheme.primary,
                          ),
                          semanticLabel: 'community.send_comment'.tr(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
