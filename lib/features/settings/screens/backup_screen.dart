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
import '../../../domain/services/import/import_providers.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../domain/services/ads/ad_reward_providers.dart';
import '../../../features/premium/providers/premium_providers.dart';
import '../../../router/route_names.dart';
import '../providers/export_providers.dart';

/// Screen for exporting data as PDF or Excel.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(exportLoadingProvider);
    final lastExport = ref.watch(lastExportDateProvider);

    return Scaffold(
      appBar: AppBar(title: Text('backup.title'.tr())),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          _InfoCard(lastExport: lastExport),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(title: 'backup.export_data'.tr()),
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
          _SectionHeader(title: 'backup.quick_export'.tr()),
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
          _SectionHeader(title: 'backup.import_data'.tr()),
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
            'backup.import_success'.tr(namedArgs: {
              'count': '${importResult.importedCount}',
              'total': '${importResult.totalRows}',
            }),
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
    // Consume reward use if not premium
    if (!isPremium && hasExportReward) {
      ref.read(isExportRewardActiveProvider.notifier).consume();
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({this.lastExport});

  final DateTime? lastExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = lastExport != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(lastExport!)
        : 'backup.never'.tr();

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            AppIcon(
              AppIcons.database,
              size: 36,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'backup.last_export'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(dateText, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  final Widget icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: [
              Container(
                width: AppSpacing.touchTargetMd,
                height: AppSpacing.touchTargetMd,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: IconTheme(
                  data: IconThemeData(color: color),
                  child: icon,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                AppIcon(
                  AppIcons.export,
                  size: 20,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
