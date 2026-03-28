import 'dart:io';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/logger.dart';

/// Protected tables that cannot be reset.
const protectedTables = {
  'admin_users',
  'admin_logs',
  'system_settings',
  'system_status',
  'subscription_plans',
  'profiles',
};

/// Saves a JSON backup file to the app documents directory.
Future<void> saveBackupFile(
  BuildContext context,
  String tableName,
  String jsonContent,
) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(p.join(dir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'backup_${tableName}_$timestamp.json';
    final file = File(p.join(backupDir.path, fileName));
    await file.writeAsString(jsonContent);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin.backup_saved'.tr(args: [fileName])),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'admin.backup_path'.tr(),
            textColor: Theme.of(context).colorScheme.surface,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(file.path),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                ),
              );
            },
          ),
        ),
      );
    }
  } catch (e) {
    AppLogger.error('saveBackupFile', e, StackTrace.current);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin.backup_save_error'.tr(args: [e.toString()])),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
