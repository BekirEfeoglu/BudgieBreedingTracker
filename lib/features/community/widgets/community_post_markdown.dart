import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

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
