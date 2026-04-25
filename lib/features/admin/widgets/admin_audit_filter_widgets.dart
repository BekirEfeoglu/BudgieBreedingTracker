import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../providers/admin_providers.dart';

/// Filter bar with search and date pickers.
class AuditFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final AuditLogFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DateTime> onStartDatePicked;
  final ValueChanged<DateTime> onEndDatePicked;
  final VoidCallback onClear;

  const AuditFilterBar({
    super.key,
    required this.controller,
    required this.filter,
    required this.onSearchChanged,
    required this.onStartDatePicked,
    required this.onEndDatePicked,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'admin.search_logs'.tr(),
              prefixIcon: AppIcon(AppIcons.search, size: 18, semanticsLabel: 'common.search'.tr()),
              suffixIcon: filter.hasFilter
                  ? AppIconButton(
                      tooltip: 'common.clear'.tr(),
                      semanticLabel: 'common.clear'.tr(),
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: onClear,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AuditDateChip(
                  label: filter.startDate != null
                      ? DateFormat.yMd(
                          Localizations.localeOf(context).languageCode,
                        ).format(filter.startDate!)
                      : 'admin.start_date'.tr(),
                  isActive: filter.startDate != null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: filter.startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) onStartDatePicked(date);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AuditDateChip(
                  label: filter.endDate != null
                      ? DateFormat.yMd(
                          Localizations.localeOf(context).languageCode,
                        ).format(filter.endDate!)
                      : 'admin.end_date'.tr(),
                  isActive: filter.endDate != null,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: filter.endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) onEndDatePicked(date);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Date chip for audit filter bar.
class AuditDateChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const AuditDateChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: 'calendar.title'.tr(),
              child: Icon(
                LucideIcons.calendar,
                size: 14,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
