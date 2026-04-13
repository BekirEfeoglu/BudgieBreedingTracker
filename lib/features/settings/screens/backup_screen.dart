import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/app_screen_title.dart';
import '../../../domain/services/import/import_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../../../domain/services/ads/ad_reward_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/premium_shared_providers.dart';
import '../../../router/route_names.dart';
import '../providers/settings_providers.dart';
import '../providers/export_providers.dart';

part 'backup_screen_widgets.dart';

/// Screen for exporting data as PDF or Excel.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(exportLoadingProvider);
    final lastExport = ref.watch(lastExportDateProvider);
    final dateFormat = ref.watch(dateFormatProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'backup.title'.tr(),
          iconAsset: AppIcons.backup,
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          _InfoCard(lastExport: lastExport, dateFormat: dateFormat),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
            title: 'backup.export_data'.tr(),
            icon: const AppIcon(AppIcons.export),
          ),
          const SizedBox(height: AppSpacing.md),
          _ExportTile(
            icon: const AppIcon(AppIcons.pdf),
            color: AppColors.error,
            title: 'backup.export_pdf'.tr(),
            subtitle: 'backup.export_pdf_desc'.tr(),
            isLoading: isLoading,
            onTap: () => _handleExport(context, ref, 'pdf'),
          ),
          const SizedBox(height: AppSpacing.md),
          _ExportTile(
            icon: const AppIcon(AppIcons.excel),
            color: AppColors.success,
            title: 'backup.export_excel'.tr(),
            subtitle: 'backup.export_excel_desc'.tr(),
            isLoading: isLoading,
            onTap: () => _handleExport(context, ref, 'excel'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionHeader(
            title: 'backup.quick_export'.tr(),
            icon: const AppIcon(AppIcons.bird),
          ),
          const SizedBox(height: AppSpacing.md),
          _ExportTile(
            icon: const AppIcon(AppIcons.bird),
            color: AppColors.budgieGreen,
            title: 'backup.export_birds_pdf'.tr(),
            subtitle: 'backup.export_birds_pdf_desc'.tr(),
            isLoading: isLoading,
            onTap: () => _handleExport(context, ref, 'birds_pdf'),
          ),
          const SizedBox(height: AppSpacing.xxl),
          _SectionHeader(
            title: 'backup.import_data'.tr(),
            icon: const AppIcon(AppIcons.backup),
          ),
          const SizedBox(height: AppSpacing.md),
          _ExportTile(
            icon: const AppIcon(AppIcons.backup),
            color: AppColors.info,
            title: 'backup.import_excel'.tr(),
            subtitle: 'backup.import_excel_desc'.tr(),
            isLoading: isLoading,
            onTap: () => _handleImport(context, ref),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('premium.title'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push(AppRoutes.premium);
            },
            child: Text('premium.upgrade_to_unlock'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport(BuildContext context, WidgetRef ref) async {
    final isPremium = ref.read(isPremiumProvider);
    final hasExportReward = ref.read(isExportRewardActiveProvider);
    if (!isPremium && !hasExportReward) {
      _showPremiumDialog(context, 'premium.backup_required'.tr());
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) {
      if (context.mounted) {
        context.showSnackBar('backup.import_error'.tr(), isError: true);
      }
      return;
    }

    // Consume reward use only when the user proceeds with an actual file.
    if (!isPremium && hasExportReward) {
      ref.read(isExportRewardActiveProvider.notifier).consume();
    }

    ref.read(exportLoadingProvider.notifier).state = true;
    try {
      final importService = ref.read(dataImportServiceProvider);
      final userId = ref.read(currentUserIdProvider);
      final importResult = await importService.importBirdsFromExcel(
        bytes: bytes,
        userId: userId,
        maxTotalBirds: isPremium ? null : AppConstants.freeTierMaxBirds,
      );

      if (context.mounted) {
        if (importResult.importedCount == 0 && importResult.errors.isNotEmpty) {
          context.showSnackBar(importResult.errors.first, isError: true);
        } else {
          context.showSnackBar(
            'backup.import_success'.tr(
              namedArgs: {
                'count': '${importResult.importedCount}',
                'total': '${importResult.totalRows}',
              },
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('BackupScreen', e, StackTrace.current);
      if (context.mounted) {
        context.showSnackBar('backup.import_error'.tr(), isError: true);
      }
    } finally {
      ref.read(exportLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _handleExport(
    BuildContext context,
    WidgetRef ref,
    String type,
  ) async {
    final isPremium = ref.read(isPremiumProvider);
    final hasExportReward = ref.read(isExportRewardActiveProvider);
    if (!isPremium && !hasExportReward) {
      _showPremiumDialog(context, 'premium.export_required'.tr());
      return;
    }
    final actions = ref.read(exportActionsProvider);
    try {
      switch (type) {
        case 'pdf':
          await actions.exportPdf();
        case 'excel':
          await actions.exportExcel();
        case 'birds_pdf':
          await actions.exportBirdsPdf();
      }

      // Consume reward only after a successful export.
      if (!isPremium && hasExportReward) {
        ref.read(isExportRewardActiveProvider.notifier).consume();
      }

      if (context.mounted) {
        context.showSnackBar('backup.export_success'.tr());
      }
    } catch (e) {
      AppLogger.error('BackupScreen', e, StackTrace.current);
      if (context.mounted) {
        context.showSnackBar('backup.export_error'.tr(), isError: true);
      }
    }
  }
}
