part of 'backup_screen.dart';

extension _PortableBackupActions on BackupScreen {
  Future<void> _handlePortableBackup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (ref.read(exportLoadingProvider)) return;

    final password = await _showBackupPasswordDialog(
      context,
      confirmPassword: true,
    );
    if (password == null || !context.mounted) return;

    ref.read(exportLoadingProvider.notifier).set(true);
    File? backupFile;
    try {
      final userId = ref.read(currentUserIdProvider);
      final result = await ref
          .read(backupServiceProvider)
          .createBackup(userId, encrypt: true, password: password);
      if (!result.success || result.filePath == null) {
        if (context.mounted) {
          context.showSnackBar(
            result.error ?? 'backup.portable_create_error'.tr(),
            isError: true,
          );
        }
        return;
      }

      backupFile = File(result.filePath!);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          subject: 'backup.portable_share_subject'.tr(),
        ),
      );
      if (context.mounted) {
        context.showSnackBar(
          'backup.portable_create_success'.tr(
            namedArgs: {'count': '${result.recordCount}'},
          ),
        );
      }
    } catch (e, st) {
      AppLogger.error('BackupScreen portable backup failed', e, st);
      await Sentry.captureException(e, stackTrace: st);
      if (context.mounted) {
        context.showSnackBar(
          'backup.portable_create_error'.tr(),
          isError: true,
        );
      }
    } finally {
      if (backupFile != null) {
        try {
          if (await backupFile.exists()) await backupFile.delete();
        } catch (e) {
          AppLogger.warning('BackupScreen portable backup cleanup failed: $e');
        }
      }
      ref.read(exportLoadingProvider.notifier).set(false);
    }
  }

  Future<void> _handlePortableRestore(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (ref.read(exportLoadingProvider)) return;

    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: false,
    );
    final filePath = selection?.files.firstOrNull?.path;
    if (filePath == null || !context.mounted) return;

    ref.read(exportLoadingProvider.notifier).set(true);
    try {
      final service = ref.read(backupServiceProvider);
      final userId = ref.read(currentUserIdProvider);
      String? password;
      var preview = await service.previewBackup(userId, filePath);

      if (preview.requiresPassword) {
        if (!context.mounted) return;
        password = await _showBackupPasswordDialog(
          context,
          confirmPassword: false,
        );
        if (password == null) return;
        preview = await service.previewBackup(
          userId,
          filePath,
          password: password,
        );
      }

      if (!preview.success) {
        if (context.mounted) {
          context.showSnackBar(
            preview.error ?? 'backup.error_invalid_format'.tr(),
            isError: true,
          );
        }
        return;
      }

      if (!context.mounted) return;
      final confirmed = await _showRestorePreviewDialog(
        context,
        preview,
        ref.read(dateFormatProvider),
      );
      if (!confirmed) return;

      final restore = await service.restoreBackup(
        userId,
        filePath,
        password: password,
      );
      if (!context.mounted) return;
      if (restore.success) {
        context.showSnackBar(
          'backup.restore_success'.tr(
            namedArgs: {'count': '${restore.recordCount}'},
          ),
        );
      } else {
        context.showSnackBar(
          restore.error ?? 'backup.restore_error'.tr(),
          isError: true,
        );
      }
    } catch (e, st) {
      AppLogger.error('BackupScreen portable restore failed', e, st);
      await Sentry.captureException(e, stackTrace: st);
      if (context.mounted) {
        context.showSnackBar('backup.restore_error'.tr(), isError: true);
      }
    } finally {
      ref.read(exportLoadingProvider.notifier).set(false);
    }
  }

  Future<String?> _showBackupPasswordDialog(
    BuildContext context, {
    required bool confirmPassword,
  }) async {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    var obscurePassword = true;
    var obscureConfirmation = true;

    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              confirmPassword
                  ? 'backup.password_create_title'.tr()
                  : 'backup.password_restore_title'.tr(),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('backup.password_hint'.tr()),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'backup.password'.tr(),
                      suffixIcon: AppIconButton(
                        onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword,
                        ),
                        icon: Icon(
                          obscurePassword
                              ? LucideIcons.eye
                              : LucideIcons.eyeOff,
                        ),
                        semanticLabel: obscurePassword
                            ? 'backup.password_show'.tr()
                            : 'backup.password_hide'.tr(),
                      ),
                    ),
                    validator: (value) {
                      if ((value?.length ?? 0) <
                          PortableBackupCodec.minimumPasswordLength) {
                        return 'backup.password_min_length'.tr(
                          args: [
                            '${PortableBackupCodec.minimumPasswordLength}',
                          ],
                        );
                      }
                      return null;
                    },
                  ),
                  if (confirmPassword) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: confirmationController,
                      obscureText: obscureConfirmation,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'backup.password_confirm'.tr(),
                        suffixIcon: AppIconButton(
                          onPressed: () => setDialogState(
                            () => obscureConfirmation = !obscureConfirmation,
                          ),
                          icon: Icon(
                            obscureConfirmation
                                ? LucideIcons.eye
                                : LucideIcons.eyeOff,
                          ),
                          semanticLabel: obscureConfirmation
                              ? 'backup.password_show'.tr()
                              : 'backup.password_hide'.tr(),
                        ),
                      ),
                      validator: (value) => value == passwordController.text
                          ? null
                          : 'backup.password_mismatch'.tr(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('common.cancel'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(dialogContext).pop(passwordController.text);
                  }
                },
                child: Text('common.confirm'.tr()),
              ),
            ],
          ),
        ),
      );
    } finally {
      passwordController.dispose();
      confirmationController.dispose();
    }
  }

  Future<bool> _showRestorePreviewDialog(
    BuildContext context,
    BackupPreview preview,
    AppDateFormat dateFormat,
  ) async {
    final createdAt = preview.createdAt == null
        ? 'backup.preview_unknown_date'.tr()
        : dateFormat.formatter(withTime: true).format(preview.createdAt!);
    final counts = preview.entityCounts.entries
        .where((entry) => entry.value > 0)
        .toList(growable: false);

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('backup.preview_title'.tr()),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'backup.preview_summary'.tr(
                      namedArgs: {
                        'count': '${preview.recordCount}',
                        'date': createdAt,
                      },
                    ),
                  ),
                  if (counts.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    for (final entry in counts)
                      Text(
                        'backup.preview_entity'.tr(
                          namedArgs: {
                            'name': 'backup.entity_${entry.key}'.tr(),
                            'count': '${entry.value}',
                          },
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'backup.preview_merge_warning'.tr(),
                    style: Theme.of(dialogContext).textTheme.bodyMedium
                        ?.copyWith(
                          color: Theme.of(dialogContext).colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('common.cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('backup.restore_confirm'.tr()),
              ),
            ],
          ),
        ) ??
        false;
  }
}
