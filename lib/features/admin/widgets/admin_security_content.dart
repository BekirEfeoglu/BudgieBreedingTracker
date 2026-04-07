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

part 'admin_security_content_items.dart';

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
          sliver: SliverToBoxAdapter(child: SecuritySummary(events: events)),
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
        .where((e) => e.eventType == SecurityEventType.failedLogin)
        .length;
    final rateLimits = events
        .where((e) => e.eventType == SecurityEventType.rateLimited)
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
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

