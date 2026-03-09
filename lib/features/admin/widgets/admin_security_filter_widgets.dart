import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/admin_providers.dart';

/// Filter bar with search and severity filter.
class SecurityFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final SecurityEventFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<SecuritySeverityLevel?> onSeverityChanged;

  const SecurityFilterBar({
    super.key,
    required this.controller,
    required this.filter,
    required this.onSearchChanged,
    required this.onSeverityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
      ),
      child: Column(
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'admin.search_events'.tr(),
              prefixIcon: const AppIcon(AppIcons.search, size: 18),
              suffixIcon: filter.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
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
          SegmentedButton<SecuritySeverityLevel?>(
            segments: [
              ButtonSegment<SecuritySeverityLevel?>(
                value: null,
                label: Text('admin.severity_all'.tr()),
              ),
              ButtonSegment<SecuritySeverityLevel?>(
                value: SecuritySeverityLevel.high,
                label: Text('admin.severity_high'.tr()),
              ),
              ButtonSegment<SecuritySeverityLevel?>(
                value: SecuritySeverityLevel.medium,
                label: Text('admin.severity_medium'.tr()),
              ),
              ButtonSegment<SecuritySeverityLevel?>(
                value: SecuritySeverityLevel.low,
                label: Text('admin.severity_low'.tr()),
              ),
            ],
            selected: {filter.severity},
            onSelectionChanged: (s) => onSeverityChanged(s.first),
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}
