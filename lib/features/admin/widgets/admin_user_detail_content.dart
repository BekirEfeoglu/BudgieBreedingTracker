import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../providers/admin_providers.dart';
import 'admin_user_detail_sections.dart';

/// Main content body for the user detail screen.
class UserDetailContent extends StatelessWidget {
  final AdminUserDetail detail;
  final VoidCallback? onGrantPremium;
  final VoidCallback? onRevokePremium;

  const UserDetailContent({
    super.key,
    required this.detail,
    this.onGrantPremium,
    this.onRevokePremium,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserDetailProfileHeader(detail: detail),
          const SizedBox(height: AppSpacing.lg),
          UserDetailSubscriptionSection(
            detail: detail,
            onGrantPremium: onGrantPremium,
            onRevokePremium: onRevokePremium,
          ),
          const SizedBox(height: AppSpacing.lg),
          UserDetailStatsRow(detail: detail),
          const SizedBox(height: AppSpacing.xxl),
          UserDetailActivityLogSection(logs: detail.activityLogs),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}

/// Profile header with avatar, name, email, and join date.
class UserDetailProfileHeader extends StatelessWidget {
  final AdminUserDetail detail;
  const UserDetailProfileHeader({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: detail.avatarUrl != null
                  ? CachedNetworkImageProvider(
                      detail.avatarUrl!,
                      maxWidth: 128,
                      maxHeight: 128,
                    )
                  : null,
              child: detail.avatarUrl == null
                  ? AppIcon(
                      AppIcons.users,
                      size: 28,
                      color: theme.colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.fullName ?? 'admin.no_name'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    detail.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${'admin.joined'.tr()} ${_formatDate(context, detail.createdAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('dd MMM yyyy', locale).format(date);
  }
}

/// Subscription section with plan info and grant/revoke buttons.
class UserDetailSubscriptionSection extends StatelessWidget {
  final AdminUserDetail detail;
  final VoidCallback? onGrantPremium;
  final VoidCallback? onRevokePremium;

  const UserDetailSubscriptionSection({
    super.key,
    required this.detail,
    this.onGrantPremium,
    this.onRevokePremium,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = (detail.subscriptionPlan ?? 'free').toLowerCase();
    final status = (detail.subscriptionStatus ?? 'active').toLowerCase();
    final isRoleBasedPremium = status == 'founder' || status == 'admin';
    final isActive =
        isRoleBasedPremium || status == 'active' || status == 'trial';
    final isPremium = plan == 'premium';
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin.subscription'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                AppIcon(
                  AppIcons.premium,
                  size: 20,
                  color: isPremium
                      ? AppColors.accent
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _planLabel(plan),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isActive ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (detail.subscriptionUpdatedAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${'admin.subscription_updated'.tr()} ${DateFormat('dd MMM yyyy HH:mm', Localizations.localeOf(context).languageCode).format(detail.subscriptionUpdatedAt!)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
            if (isRoleBasedPremium) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'admin.role_based_premium'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: isPremium
                    ? OutlinedButton.icon(
                        onPressed: onRevokePremium,
                        icon: const Icon(LucideIcons.xCircle, size: 18),
                        label: Text('admin.revoke_premium'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: onGrantPremium,
                        icon: const AppIcon(AppIcons.premium, size: 18),
                        label: Text('admin.grant_premium'.tr()),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _planLabel(String plan) {
    return switch (plan) {
      'premium' => 'premium.pro'.tr(),
      'free' => 'premium.free'.tr(),
      _ => plan.toUpperCase(),
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'founder' => 'profile.role_founder'.tr(),
      'admin' => 'profile.role_admin'.tr(),
      'active' => 'common.active'.tr(),
      'trial' => 'premium.trial_badge'.tr(),
      'free' => 'premium.free'.tr(),
      _ => status,
    };
  }
}

/// Stats row showing bird count and log entries.
class UserDetailStatsRow extends StatelessWidget {
  final AdminUserDetail detail;
  const UserDetailStatsRow({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            icon: const AppIcon(AppIcons.bird),
            color: AppColors.budgieGreen,
            value: '${detail.birdsCount}',
            label: 'admin.birds'.tr(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatItem(
            icon: const AppIcon(AppIcons.audit),
            color: AppColors.info,
            value: '${detail.activityLogs.length}',
            label: 'admin.log_entries'.tr(),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final Widget icon;
  final Color color;
  final String value;
  final String label;
  const _StatItem({
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
              ),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
