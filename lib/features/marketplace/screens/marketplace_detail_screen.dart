import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../core/widgets/error_state.dart' as app;
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import '../../../router/route_names.dart';
import '../../../features/messaging/providers/messaging_form_providers.dart';
import '../../community/widgets/community_image_viewer.dart';
import '../providers/marketplace_form_providers.dart';
import '../providers/marketplace_providers.dart';
import '../widgets/marketplace_seller_card.dart';

class MarketplaceDetailScreen extends ConsumerStatefulWidget {
  final String listingId;

  const MarketplaceDetailScreen({super.key, required this.listingId});

  @override
  ConsumerState<MarketplaceDetailScreen> createState() =>
      _MarketplaceDetailScreenState();
}

class _MarketplaceDetailScreenState
    extends ConsumerState<MarketplaceDetailScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final listingAsync = ref.watch(
      marketplaceListingByIdProvider((id: widget.listingId, userId: userId)),
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('marketplace.listing_detail'.tr()),
      ),
      body: listingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => app.ErrorState(
          message: '${'marketplace.listing_error'.tr()}: $error',
          onRetry: () => ref.invalidate(
            marketplaceListingByIdProvider(
                (id: widget.listingId, userId: userId)),
          ),
        ),
        data: (listing) {
          if (listing == null) {
            return app.ErrorState(
              message: 'error.not_found'.tr(),
            );
          }

          final isOwner = listing.userId == userId;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (listing.imageUrls.isNotEmpty) ...[
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: listing.imageUrls.length,
                      itemBuilder: (context, index) => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CommunityImageViewer(
                              imageUrl: listing.imageUrls[index],
                            ),
                          ),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: listing.imageUrls[index],
                          fit: BoxFit.cover,
                          memCacheWidth: 960,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(LucideIcons.imageOff),
                        ),
                      ),
                    ),
                  ),
                  if (listing.imageUrls.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          listing.imageUrls.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentPage
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                Padding(
                  padding: AppSpacing.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        listing.title,
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (listing.price != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          listing.priceDisplay,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.eye,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'marketplace.view_count'
                                .tr(args: ['${listing.viewCount}']),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        listing.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _InfoRow(
                        label: 'marketplace.species_label'.tr(),
                        value: listing.species,
                      ),
                      if (listing.mutation != null)
                        _InfoRow(
                          label: 'marketplace.mutation_label'.tr(),
                          value: listing.mutation!,
                        ),
                      _InfoRow(
                        label: 'marketplace.gender_label'.tr(),
                        value: listing.gender.name,
                      ),
                      if (listing.age != null)
                        _InfoRow(
                          label: 'marketplace.age_label'.tr(),
                          value: listing.age!,
                        ),
                      _InfoRow(
                        label: 'marketplace.city_label'.tr(),
                        value: listing.city,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      MarketplaceSellerCard(
                        sellerId: listing.userId,
                        username: listing.username,
                        avatarUrl: listing.avatarUrl,
                        isVerifiedBreeder: listing.isVerifiedBreeder,
                        memberSince: listing.createdAt,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (!isOwner)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final notifier = ref.read(
                                messagingFormStateProvider.notifier,
                              );
                              final conversationId =
                                  await notifier.startDirectConversation(
                                userId1: userId,
                                userId2: listing.userId,
                              );
                              if (!context.mounted) return;
                              if (conversationId != null) {
                                context.push(
                                  '${AppRoutes.messages}/$conversationId',
                                );
                              }
                            },
                            icon: const Icon(LucideIcons.messageCircle),
                            label: Text('marketplace.message_seller'.tr()),
                          ),
                        ),
                      if (isOwner) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(
                              '${AppRoutes.marketplace}/form?editId=${listing.id}',
                            ),
                            icon: const Icon(LucideIcons.edit),
                            label: Text('marketplace.edit_listing'.tr()),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final confirmed = await showConfirmDialog(
                                context,
                                title: 'common.delete'.tr(),
                                message: 'marketplace.confirm_delete'.tr(),
                                isDestructive: true,
                              );
                              if (confirmed == true) {
                                await ref
                                    .read(
                                      marketplaceFormStateProvider.notifier,
                                    )
                                    .deleteListing(listing.id);
                                if (!context.mounted) return;
                                context.pop();
                              }
                            },
                            icon: const Icon(LucideIcons.trash2),
                            label: Text('common.delete'.tr()),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
