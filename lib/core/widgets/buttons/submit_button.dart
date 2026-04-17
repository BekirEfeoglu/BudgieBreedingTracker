import 'package:flutter/material.dart';

/// Submit button that honors loading state and explicit enabled/disabled.
///
/// Passing `onPressed: null` disables the button. Use this instead of
/// unconditionally-enabled buttons — users should see "can't submit yet"
/// reflected in the button state, not discover it when they tap.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    if (icon != null && !isLoading) {
      return FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: icon!,
        label: child,
      );
    }

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}
