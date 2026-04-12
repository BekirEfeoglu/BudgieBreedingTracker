import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/errors/app_exception.dart';
import 'package:budgie_breeding_tracker/domain/services/local_ai/local_ai_service.dart';

/// Shared spinner widget for AI action buttons.
class AiButtonSpinner extends StatelessWidget {
  const AiButtonSpinner({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}

/// Formats AI error objects into user-readable localized messages.
String formatAiError(Object? error) {
  if (error is AppException) {
    final msg = error.message;
    if (msg.startsWith(LocalAiService.errorKeyPrefix)) {
      final parts = msg.split('\x00');
      final key = parts[0];
      return parts.length > 1
          ? key.tr(args: parts.sublist(1))
          : key.tr();
    }
    return msg;
  }
  return error?.toString() ?? 'common.error'.tr();
}
