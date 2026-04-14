import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/enums/community_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../data/models/community_post_model.dart';
import '../../../router/route_names.dart';

/// Badge showing the post type (photo, question, guide, etc.).
class PostTypeBadge extends StatelessWidget {
  final CommunityPostType postType;

  const PostTypeBadge({super.key, required this.postType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        switch (postType) {
          CommunityPostType.photo => 'community.post_type_photo'.tr(),
          CommunityPostType.question => 'community.post_type_question'.tr(),
          CommunityPostType.guide => 'community.post_type_guide'.tr(),
          CommunityPostType.tip => 'community.post_type_tip'.tr(),
          CommunityPostType.showcase => 'community.post_type_showcase'.tr(),
          CommunityPostType.general => 'community.post_type_general'.tr(),
          CommunityPostType.unknown => 'community.post_type_general'.tr(),
        },
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Chip linking to a bird's detail page.
class BirdLinkChip extends StatelessWidget {
  final CommunityPost post;

  const BirdLinkChip({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = post.birdName ?? 'community.linked_bird'.tr();

    return ActionChip(
      avatar: const AppIcon(AppIcons.bird, size: 18),
      label: Text(label),
      onPressed: post.birdId == null
          ? null
          : () => context.push(
              AppRoutes.birdDetail.replaceFirst(':id', post.birdId!),
            ),
      side: BorderSide(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
      backgroundColor: theme.colorScheme.surface,
    );
  }
}

/// Wrap of mutation tags and hashtags.
class PostTagWrap extends StatelessWidget {
  final CommunityPost post;

  const PostTagWrap({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final mutationTag in post.mutationTags)
          _TagChip(
            label: mutationTag,
            backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.14),
            foregroundColor: theme.colorScheme.tertiary,
          ),
        for (final tag in post.tags)
          _TagChip(
            label: tag.startsWith('#') ? tag : '#$tag',
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            foregroundColor: theme.colorScheme.primary,
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  const _TagChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Like and comment count summary row.
class EngagementSummary extends StatelessWidget {
  final CommunityPost post;

  const EngagementSummary({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        if (post.likeCount > 0)
          _MetricBadge(
            icon: LucideIcons.heart,
            value: '${post.likeCount}',
            label: 'community.like'.tr(),
            iconColor: theme.colorScheme.primary,
          ),
        if (post.commentCount > 0)
          _MetricBadge(
            icon: LucideIcons.messageCircle,
            value: '${post.commentCount}',
            label: 'community.comment'.tr(),
            iconColor: theme.colorScheme.secondary,
          ),
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _MetricBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Truncated content text with "read more" hint.
class ContentText extends StatelessWidget {
  final String content;
  final bool showFull;
  final int maxLines;

  const ContentText({
    super.key,
    required this.content,
    required this.showFull,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.45);
    final normalizedContent = _normalizeMarkdownPreview(content);

    if (showFull) {
      return _MarkdownContent(
        content: content,
        textStyle: textStyle ?? const TextStyle(height: 1.45),
        boldTextStyle: (textStyle ?? const TextStyle(height: 1.45)).copyWith(
          fontWeight: FontWeight.w700,
        ),
      );
    }

    final mayOverflow =
        normalizedContent.length > maxLines * 45 ||
        '\n'.allMatches(normalizedContent).length >= maxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          normalizedContent,
          style: textStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
        if (mayOverflow) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'community.read_more'.tr(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );
  }
}

class _MarkdownContent extends StatelessWidget {
  final String content;
  final TextStyle textStyle;
  final TextStyle boldTextStyle;

  const _MarkdownContent({
    required this.content,
    required this.textStyle,
    required this.boldTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final lines = content.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          _MarkdownLine(
            line: lines[i],
            textStyle: textStyle,
            boldTextStyle: boldTextStyle,
          ),
          if (i < lines.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _MarkdownLine extends StatelessWidget {
  final String line;
  final TextStyle textStyle;
  final TextStyle boldTextStyle;

  const _MarkdownLine({
    required this.line,
    required this.textStyle,
    required this.boldTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (line.trim().isEmpty) {
      return const SizedBox(height: AppSpacing.sm);
    }

    final lineData = _parseMarkdownLine(line, textStyle, boldTextStyle);
    final richText = Text.rich(
      TextSpan(
        style: lineData.textStyle,
        children: _parseInlineMarkdown(
          lineData.text,
          lineData.textStyle,
          lineData.boldTextStyle,
        ),
      ),
    );

    if (lineData.leading == null) return richText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            lineData.leading!,
            style: lineData.leadingStyle ?? lineData.boldTextStyle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: richText),
      ],
    );
  }
}

List<InlineSpan> _parseInlineMarkdown(
  String text,
  TextStyle textStyle,
  TextStyle boldTextStyle,
) {
  final spans = <InlineSpan>[];
  final pattern = RegExp(r'\*\*(.+?)\*\*|_(.+?)_');
  var start = 0;

  for (final match in pattern.allMatches(text)) {
    if (match.start > start) {
      spans.add(
        TextSpan(text: text.substring(start, match.start), style: textStyle),
      );
    }
    final boldText = match.group(1);
    final italicText = match.group(2);
    if (boldText != null && boldText.isNotEmpty) {
      spans.add(TextSpan(text: boldText, style: boldTextStyle));
    } else if (italicText != null && italicText.isNotEmpty) {
      spans.add(
        TextSpan(
          text: italicText,
          style: textStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    }
    start = match.end;
  }

  if (start < text.length) {
    spans.add(TextSpan(text: text.substring(start), style: textStyle));
  }

  if (spans.isEmpty) {
    spans.add(TextSpan(text: text, style: textStyle));
  }

  return spans;
}

String _normalizeMarkdownPreview(String content) {
  final normalizedLines = content.split('\n').map((line) {
    final lineData = _parseMarkdownLine(
      line,
      const TextStyle(),
      const TextStyle(),
    );
    return lineData.text
        .replaceAllMapped(
          RegExp(r'\*\*(.+?)\*\*'),
          (match) => match.group(1) ?? '',
        )
        .replaceAllMapped(RegExp(r'_(.+?)_'), (match) => match.group(1) ?? '');
  });

  return normalizedLines.join('\n');
}

_ParsedMarkdownLine _parseMarkdownLine(
  String line,
  TextStyle textStyle,
  TextStyle boldTextStyle,
) {
  final trimmedLine = line.trimLeft();
  final headingMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(trimmedLine);
  if (headingMatch != null) {
    final level = headingMatch.group(1)!.length;
    final headingText = headingMatch.group(2)!;
    final headingStyle = switch (level) {
      1 => boldTextStyle.copyWith(fontSize: (textStyle.fontSize ?? 16) + 6),
      2 => boldTextStyle.copyWith(fontSize: (textStyle.fontSize ?? 16) + 4),
      _ => boldTextStyle.copyWith(fontSize: (textStyle.fontSize ?? 16) + 2),
    };
    return _ParsedMarkdownLine(
      text: headingText,
      textStyle: headingStyle,
      boldTextStyle: headingStyle,
    );
  }

  final orderedMatch = RegExp(r'^(\d+)\.\s+(.+)$').firstMatch(trimmedLine);
  if (orderedMatch != null) {
    return _ParsedMarkdownLine(
      text: orderedMatch.group(2)!,
      textStyle: textStyle,
      boldTextStyle: boldTextStyle,
      leading: '${orderedMatch.group(1)}.',
      leadingStyle: boldTextStyle,
    );
  }

  final unorderedMatch = RegExp(r'^([-*•])\s+(.+)$').firstMatch(trimmedLine);
  if (unorderedMatch != null) {
    return _ParsedMarkdownLine(
      text: unorderedMatch.group(2)!,
      textStyle: textStyle,
      boldTextStyle: boldTextStyle,
      leading: '•',
      leadingStyle: boldTextStyle,
    );
  }

  final marker = _extractDecorativeMarker(trimmedLine);
  if (marker != null) {
    return _ParsedMarkdownLine(
      text: trimmedLine.substring(marker.length).trimLeft(),
      textStyle: textStyle,
      boldTextStyle: boldTextStyle,
      leading: '•',
      leadingStyle: boldTextStyle,
    );
  }

  return _ParsedMarkdownLine(
    text: line,
    textStyle: textStyle,
    boldTextStyle: boldTextStyle,
  );
}

String? _extractDecorativeMarker(String line) {
  final trimmed = line.trimLeft();
  if (trimmed.isEmpty) return null;

  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.isEmpty) return null;

  final token = parts.first;
  final hasAsciiWordChar = RegExp(r'[A-Za-z0-9]').hasMatch(token);
  if (hasAsciiWordChar) return null;
  if (token.contains('*') || token.contains('#')) return null;
  if (token.length > 4) return null;

  return token;
}

class _ParsedMarkdownLine {
  final String text;
  final TextStyle textStyle;
  final TextStyle boldTextStyle;
  final String? leading;
  final TextStyle? leadingStyle;

  const _ParsedMarkdownLine({
    required this.text,
    required this.textStyle,
    required this.boldTextStyle,
    this.leading,
    this.leadingStyle,
  });
}
