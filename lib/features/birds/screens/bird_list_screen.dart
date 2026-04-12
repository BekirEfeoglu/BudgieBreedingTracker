import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/sort_bottom_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_card.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_search_bar.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_bell_button.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_button.dart';

/// Main screen listing all birds with search, filter, and sort support.
class BirdListScreen extends ConsumerWidget {
  const BirdListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));
    final currentSort = ref.watch(birdSortProvider);

    void navigateWithAd(String route) {
      final isPremium = ref.read(isPremiumProvider);
      if (isPremium) {
        context.push(route);
        return;
      }
      ref
          .read(adServiceProvider)
          .showInterstitialAd(
            onAdClosed: () {
              if (context.mounted) context.push(route);
            },
          );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            birdsAsync.whenOrNull(
              data: (allBirds) => AppScreenTitle(
                title: '${'birds.title'.tr()} (${allBirds.length})',
                iconAsset: AppIcons.bird,
              ),
            ) ??
            AppScreenTitle(title: 'birds.title'.tr(), iconAsset: AppIcons.bird),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.arrowUpDown),
            tooltip: 'common.sort'.tr(),
            onPressed: () {
              showSortBottomSheet<BirdSort>(
                context: context,
                values: BirdSort.values,
                current: currentSort,
                labelOf: (sort) => sort.label,
                onSelected: (sort) =>
                    ref.read(birdSortProvider.notifier).state = sort,
              );
            },
          ),
          const NotificationBellButton(),
          const ProfileMenuButton(),
        ],
      ),
      body: Column(
        children: [
          const BirdSearchBar(),
          const Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),
          const SizedBox(height: AppSpacing.xs),
          const BirdFilterBar(),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: AdBannerWidget(
              isPremiumProvider: isPremiumProvider,
              adBannerLoader: () => defaultAdBannerLoader(ref),
            ),
          ),
          Expanded(
            child: birdsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ErrorState(
                    message: 'common.data_load_error'.tr(),
                    onRetry: () => ref.invalidate(birdsStreamProvider(userId)),
                  ),
                ),
              ),
              data: (allBirds) {
                final birds = ref.watch(
                  sortedAndFilteredBirdsProvider(allBirds),
                );

                if (allBirds.isEmpty) {
                  return EmptyState(
                    icon: const AppIcon(AppIcons.bird),
                    title: 'birds.no_birds'.tr(),
                    subtitle: 'birds.no_birds_hint'.tr(),
                    actionLabel: 'birds.add_bird'.tr(),
                    onAction: () => context.push('/birds/form'),
                  );
                }

                if (birds.isEmpty) {
                  return EmptyState(
                    icon: const AppIcon(AppIcons.search),
                    title: 'common.no_results'.tr(),
                    subtitle: 'common.no_results_hint'.tr(),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(birdsStreamProvider(userId));
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.xxxl * 2,
                        ),
                        itemCount: birds.length,
                        itemBuilder: (context, index) {
                          return BirdCard(
                            key: ValueKey(birds[index].id),
                            bird: birds[index],
                            onTap: () =>
                                navigateWithAd('/birds/${birds[index].id}'),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FabButton(
        icon: const AppIcon(AppIcons.add),
        tooltip: 'birds.new_bird'.tr(),
        onPressed: () => context.push('/birds/form'),
      ),
    );
  }
}
