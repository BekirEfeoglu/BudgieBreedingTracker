import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Wraps a child widget with [PopScope] to warn about unsaved changes.
///
/// When the user tries to navigate back and [isDirty] returns true,
/// a confirmation dialog is shown before allowing the pop.
class UnsavedChangesScope extends StatelessWidget {
  const UnsavedChangesScope({
    super.key,
    required this.isDirty,
    required this.child,
  });

  /// Whether the form has unsaved changes.
  final bool isDirty;

  /// The child widget (typically a [Scaffold]).
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!isDirty) {
          Navigator.of(context).pop();
          return;
        }
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('common.unsaved_changes'.tr()),
            content: Text('common.unsaved_changes_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('common.cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('common.discard'.tr()),
              ),
            ],
          ),
        );
        if (shouldPop == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
