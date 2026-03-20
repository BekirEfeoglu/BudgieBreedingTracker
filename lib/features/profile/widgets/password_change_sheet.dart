import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/profile_providers.dart';
import 'password_change_form.dart';

/// Shows a bottom sheet for changing the user's password.
void showPasswordChangeSheet(BuildContext context, {required WidgetRef ref}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (ctx) => const _PasswordChangeSheetContent(),
  );
}

class _PasswordChangeSheetContent extends ConsumerWidget {
  const _PasswordChangeSheetContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(passwordChangeStateProvider);

    ref.listen<PasswordChangeState>(passwordChangeStateProvider, (_, s) {
      if (s.isSuccess) {
        ref.read(passwordChangeStateProvider.notifier).reset();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile.password_changed'.tr())),
        );
      }
      if (s.error != null) {
        final errorKey = s.error == 'password_incorrect'
            ? 'profile.password_incorrect'
            : 'profile.password_change_error';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorKey.tr())));
      }
    });

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'profile.change_password'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PasswordChangeForm(
            isLoading: state.isLoading,
            onSubmit:
                ({
                  required String currentPassword,
                  required String newPassword,
                }) async {
                  ref
                      .read(passwordChangeStateProvider.notifier)
                      .changePassword(
                        currentPassword: currentPassword,
                        newPassword: newPassword,
                      );
                },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
