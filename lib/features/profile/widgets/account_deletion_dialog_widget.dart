part of 'account_deletion_dialog.dart';

/// Confirmation dialog for account deletion requiring password verification.
class AccountDeletionDialog extends StatefulWidget {
  const AccountDeletionDialog({super.key});

  /// Show the dialog and return the password if user confirmed, null otherwise.
  static Future<String?> show(BuildContext context) async {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AccountDeletionDialog(),
    );
  }

  @override
  State<AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<AccountDeletionDialog> {
  final _passwordController = TextEditingController();
  bool _canDelete = false;
  bool _obscurePassword = true;

  void _onFieldChanged() {
    final passwordOk = _passwordController.text.isNotEmpty;
    final canDelete = passwordOk;
    if (canDelete != _canDelete) {
      setState(() => _canDelete = canDelete);
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onFieldChanged);
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          AppIcon(
            AppIcons.warning,
            color: theme.colorScheme.error,
            semanticsLabel: 'profile.delete_account'.tr(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('profile.delete_account'.tr()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'profile.delete_account_warning'.tr(),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.info,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'profile.delete_account_timeline'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'profile.delete_account_password_hint'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: 'auth.password'.tr(),
              suffixIcon: AppIconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                ),
                semanticLabel: _obscurePassword
                    ? 'auth.show_password'.tr()
                    : 'auth.hide_password'.tr(),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('common.cancel'.tr()),
        ),
        FilledButton(
          onPressed: _canDelete
              ? () => Navigator.of(context).pop(_passwordController.text)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text('profile.delete_account'.tr()),
        ),
      ],
    );
  }
}
