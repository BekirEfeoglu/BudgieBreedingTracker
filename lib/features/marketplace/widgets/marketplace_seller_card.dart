import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../router/route_names.dart';

class MarketplaceSellerCard extends StatelessWidget {
  final String sellerId;
  final String username;
  final String? avatarUrl;
  final bool isVerifiedBreeder;
  final DateTime? memberSince;
  final int activeListingCount;

  const MarketplaceSellerCard({
    super.key,
    required this.sellerId,
    required this.username,
    this.avatarUrl,
    this.isVerifiedBreeder = false,
    this.memberSince,
    this.activeListingCount = 0,
  });

  int _monthsSince(DateTime? date) {
    if (date == null) return 0;
    final now = DateTime.now();
    return (now.year - date.year) * 12 + (now.month - date.month);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = _monthsSince(memberSince);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('${AppRoutes.marketplace}/seller/$sellerId'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _SellerAvatar(avatarUrl: avatarUrl, username: username),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            username,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerifiedBreeder) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(
                            LucideIcons.badgeCheck,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    if (memberSince != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'marketplace.seller_member_since'
                            .tr(args: ['$months']),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'marketplace.seller_active_listings'
                        .tr(args: ['$activeListingCount']),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SellerAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String username;

  const _SellerAvatar({required this.avatarUrl, required this.username});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Icon(LucideIcons.user),
            errorWidget: (context, url, error) => const Icon(LucideIcons.user),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        LucideIcons.user,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
