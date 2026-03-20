import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../providers/admin_providers.dart';

/// Activity log section with list of admin actions.
class UserDetailActivityLogSection extends StatelessWidget {
  final List<AdminLog> logs;
  const UserDetailActivityLogSection({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'admin.activity_log'.tr(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (logs.isEmpty)
          Text('admin.no_activity'.tr(), style: theme.textTheme.bodyMedium)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (_, i) =>
                _LogItem(key: ValueKey(logs[i].id), log: logs[i]),
          ),
      ],
    );
  }
}

class _LogItem extends StatelessWidget {
  final AdminLog log;
  const _LogItem({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.clock, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.action, style: theme.textTheme.bodySmall),
                if (log.details != null)
                  Text(
                    log.details!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            DateFormat(
              'dd MMM HH:mm',
              Localizations.localeOf(context).languageCode,
            ).format(log.createdAt),
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
