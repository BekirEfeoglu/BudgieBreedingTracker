import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/dialogs/confirm_dialog.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../../../features/breeding/providers/breeding_providers.dart';
import '../../../router/route_names.dart';
import '../../../features/messaging/providers/messaging_form_providers.dart';
import '../providers/marketplace_form_providers.dart';
import '../providers/marketplace_providers.dart';

class MarketplaceDetailScreen extends ConsumerWidget {
  final String listingId;

  const MarketplaceDetailScreen({super.key, required this.listingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final listingAsync = ref.watch(
      marketplaceListingByIdProvider((id: listingId, userId: userId)),
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
            marketplaceListingByIdProvider((id: listingId, userId: userId)),
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
                if (listing.imageUrls.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PageView.builder(
                      itemCount: listing.imageUrls.length,
                      itemBuilder: (context, index) => CachedNetworkImage(
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
                              if (context.mounted &&
                                  conversationId != null) {
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
                                if (context.mounted) context.pop();
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
