import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/admin_actions_provider.dart';
import '../providers/admin_providers.dart';

/// Main content body for the security screen.
class SecurityContent extends StatelessWidget {
  final List<SecurityEvent> events;
  const SecurityContent({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return EmptyState(
        icon: const AppIcon(AppIcons.security),
        title: 'admin.no_security_events'.tr(),
        subtitle: 'admin.no_security_events_desc'.tr(),
      );
    }
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: SecuritySummary(events: events),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => SecurityEventItem(event: events[index]),
              childCount: events.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }
}

/// Summary row with failed logins, rate limits, and total events.
class SecuritySummary extends StatelessWidget {
  final List<SecurityEvent> events;
  const SecuritySummary({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final failedLogins = events
        .where((e) => e.eventType.toLowerCase().contains('login_failed'))
        .length;
    final rateLimits = events
        .where((e) => e.eventType.toLowerCase().contains('rate_limit'))
        .length;
    return Row(
      children: [
        Expanded(
          child: SecuritySummaryCard(
            icon: const Icon(LucideIcons.logIn),
            color: AppColors.error,
            value: '$failedLogins',
            label: 'admin.failed_logins'.tr(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: SecuritySummaryCard(
            icon: const AppIcon(AppIcons.security),
            color: AppColors.warning,
            value: '$rateLimits',
            label: 'admin.rate_limits'.tr(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: SecuritySummaryCard(
            icon: const AppIcon(AppIcons.security),
            color: AppColors.info,
            value: '${events.length}',
            label: 'admin.total_events'.tr(),
          ),
        ),
      ],
    );
  }
}

/// Summary card for security metrics.
class SecuritySummaryCard extends StatelessWidget {
  final Widget icon;
  final Color color;
  final String value;
  final String label;
  const SecuritySummaryCard({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: 24),
              child: icon,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Single security event item card with dismiss action.
class SecurityEventItem extends ConsumerWidget {
  final SecurityEvent event;
  const SecurityEventItem({super.key, required this.event});

  ({IconData icon, Color color, String label}) _severity(BuildContext context) {
    final lower = event.eventType.toLowerCase();
    if (lower.contains('suspicious') || lower.contains('attack')) {
      return (icon: LucideIcons.alertOctagon, color: AppColors.error, label: 'admin.severity_high'.tr());
    }
    if (lower.contains('failed') || lower.contains('rate_limit')) {
      return (icon: LucideIcons.alertTriangle, color: AppColors.warning, label: 'admin.severity_medium'.tr());
    }
    return (icon: LucideIcons.info, color: AppColors.info, label: 'admin.severity_low'.tr());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sev = _severity(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(sev.icon, size: 18, color: sev.color),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    event.eventType,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: sev.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    sev.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: sev.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  icon: const Icon(LucideIcons.checkCircle, size: 18),
                  tooltip: 'admin.dismiss_event'.tr(),
                  onPressed: () {
                    ref
                        .read(adminActionsProvider.notifier)
                        .dismissSecurityEvent(event.id);
                  },
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.touchTargetMin,
                    minHeight: AppSpacing.touchTargetMin,
                  ),
                ),
              ],
            ),
            if (event.details != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(event.details!, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: AppSpacing.sm),
            SecurityMetadataRow(event: event),
          ],
        ),
      ),
    );
  }
}

/// Metadata row showing IP address and timestamp.
class SecurityMetadataRow extends StatelessWidget {
  final SecurityEvent event;
  const SecurityMetadataRow({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outline;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(color: outline);
    return Row(
      children: [
        if (event.ipAddress != null) ...[
          Icon(LucideIcons.globe, size: 12, color: outline),
          const SizedBox(width: AppSpacing.xs),
          Text(_maskIp(event.ipAddress!), style: style?.copyWith(fontFamily: 'monospace')),
          const SizedBox(width: AppSpacing.md),
        ],
        Icon(LucideIcons.clock, size: 12, color: outline),
        const SizedBox(width: 4),
        Text(_formatTimestamp(event.createdAt, context), style: style),
      ],
    );
  }

  String _formatTimestamp(DateTime dt, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy HH:mm', locale).format(dt);
  }

  String _maskIp(String ip) {
    final parts = ip.split('.');
    if (parts.length == 4) {
      return '***.***.${parts[2]}.${parts[3]}';
    }
    return ip;
  }
}
