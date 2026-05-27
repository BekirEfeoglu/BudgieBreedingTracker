import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';

/// Destructive confirmation dialog that requires the user to type a
/// specific phrase before the destructive button enables.
///
/// Use for truly irrecoverable actions (truncate a table, wipe all
/// user data) where a one-tap `showConfirmDialog` is too forgiving.
/// The dialog returns `true` only if the user typed [requiredPhrase]
/// (whitespace-trimmed, case-sensitive by default) and tapped the
/// destructive button.
///
/// Sample usage:
/// ```dart
/// final confirmed = await showTypedConfirmDialog(
///   context,
///   title: 'Reset birds table',
///   message: 'Type the table name to confirm. This drops 36 rows.',
///   requiredPhrase: 'birds',
/// );
/// ```
class TypedConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String requiredPhrase;
  final String? confirmLabel;
  final String? cancelLabel;
  final String? hintText;
  final bool caseSensitive;

  const TypedConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.requiredPhrase,
    this.confirmLabel,
    this.cancelLabel,
    this.hintText,
    this.caseSensitive = true,
  });

  @override
  State<TypedConfirmDialog> createState() => _TypedConfirmDialogState();
}

class _TypedConfirmDialogState extends State<TypedConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final entered = _controller.text.trim();
    final expected = widget.requiredPhrase.trim();
    final matches = widget.caseSensitive
        ? entered == expected
        : entered.toLowerCase() == expected.toLowerCase();
    if (matches != _matches) {
      setState(() => _matches = matches);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: AppSpacing.md),
          // Show the exact phrase the user must reproduce so the
          // dialog stays usable when the message text is long.
          Text(
            widget.requiredPhrase,
            style: theme.textTheme.titleSmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hintText ?? widget.requiredPhrase,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            // Disable autocorrect so OS doesn't "fix" the typed phrase.
            autocorrect: false,
            enableSuggestions: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(widget.cancelLabel ?? 'common.cancel'.tr()),
        ),
        TextButton(
          onPressed: _matches
              ? () {
                  AppHaptics.heavyImpact();
                  Navigator.of(context).pop(true);
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
          child: Text(widget.confirmLabel ?? 'common.confirm'.tr()),
        ),
      ],
    );
  }
}

/// Convenience wrapper that opens [TypedConfirmDialog] and returns
/// `true` only on confirmed match.
Future<bool> showTypedConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String requiredPhrase,
  String? confirmLabel,
  String? cancelLabel,
  String? hintText,
  bool caseSensitive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => TypedConfirmDialog(
      title: title,
      message: message,
      requiredPhrase: requiredPhrase,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      hintText: hintText,
      caseSensitive: caseSensitive,
    ),
  );
  return result == true;
}
