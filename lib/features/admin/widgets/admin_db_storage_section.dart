import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/admin_database_providers.dart';
import '../providers/admin_maintenance_models.dart';

/// Shows storage bucket usage information.
class DatabaseStorageSection extends ConsumerWidget {
  const DatabaseStorageSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncUsage = ref.watch(storageUsageProvider);

    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.storage_usage'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            asyncUsage.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text(
                '${'common.data_load_error'.tr()}: $e',
                style: theme.textTheme.bodySmall,
              ),
              data: (usages) => Column(
                children: usages
                    .map((u) => _BucketRow(usage: u))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketRow extends StatelessWidget {
  final BucketUsage usage;
  const _BucketRow({required this.usage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(LucideIcons.hardDrive, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(usage.bucketName, style: theme.textTheme.bodyMedium),
          ),
          Text(
            '${usage.fileCount} ${'admin.file_count'.tr()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            _formatSize(usage.totalSizeBytes),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}
