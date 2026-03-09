import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';

String _relativeTime(DateTime dateTime) {
  final diff = DateTime.now().toUtc().difference(dateTime.toUtc());
  if (diff.inMinutes < 1) return 'admin.just_now'.tr();
  if (diff.inMinutes < 60) return 'admin.minutes_ago'.tr(args: [diff.inMinutes.toString()]);
  if (diff.inHours < 24) return 'admin.hours_ago'.tr(args: [diff.inHours.toString()]);
  return 'admin.days_ago'.tr(args: [diff.inDays.toString()]);
}

/// Overview banner showing active settings count and last update time.
class SettingsOverviewBanner extends StatelessWidget {
  final int activeCount;
  final int totalCount;
  final DateTime? lastUpdatedAt;

  const SettingsOverviewBanner({
    super.key,
    required this.activeCount,
    required this.totalCount,
    this.lastUpdatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  '$activeCount/$totalCount',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin.settings_active_count'.tr(args: [
                      activeCount.toString(),
                      totalCount.toString(),
                    ]),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lastUpdatedAt != null)
                    Text(
                      'admin.settings_last_updated'.tr(args: [_relativeTime(lastUpdatedAt!)]),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section card with accent color left border strip.
class AccentSettingsSection extends StatelessWidget {
  final String title;
  final String? description;
  final Widget icon;
  final Color accentColor;
  final int activeCount;
  final int totalCount;
  final List<Widget> children;

  const AccentSettingsSection({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    required this.accentColor,
    required this.activeCount,
    required this.totalCount,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accentColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconTheme(
                    data: IconThemeData(size: 20, color: accentColor),
                    child: icon,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        if (description != null)
                          Text(description!, style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      '$activeCount/$totalCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Enhanced toggle setting with status dot and optional last-updated text.
class EnhancedToggleSetting extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool isUpdating;
  final String? lastUpdated;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  const EnhancedToggleSetting({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.isUpdating = false,
    this.lastUpdated,
    this.showDivider = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                    if (lastUpdated != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(lastUpdated!, style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        )),
                      ),
                  ],
                ),
              ),
              if (isUpdating)
                const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: AppSpacing.lg),
      ],
    );
  }
}

/// Button to reset all settings to defaults.
class ResetDefaultsButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const ResetDefaultsButton({
    super.key,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(LucideIcons.rotateCcw, color: theme.colorScheme.error, size: 20),
        label: Text('admin.reset_defaults'.tr(), style: TextStyle(color: theme.colorScheme.error)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      ),
    );
  }
}
