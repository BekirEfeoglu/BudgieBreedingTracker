import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/services/action_feedback_service.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Shows action feedback at the bell icon (success/info) or
  /// a SnackBar at the bottom (error — needs immediate attention).
  ///
  /// Falls back to SnackBar when [ActionFeedbackService] has no active
  /// listener (e.g. on auth screens without a bell button).
  void showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (isError) {
      ScaffoldMessenger.of(this).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: colorScheme.error),
      );
    } else if (ActionFeedbackService.hasListeners) {
      ActionFeedbackService.show(
        message,
        type: isSuccess ? ActionFeedbackType.success : ActionFeedbackType.info,
      );
    } else {
      // Fallback: no bell button on current screen — use SnackBar
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
}
