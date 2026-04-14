import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/sort_bottom_sheet.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/data/providers/premium_shared_providers.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/egg_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_search_bar.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_bell_button.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_button.dart';

/// Main screen listing all breeding pairs with filter and search support.
class BreedingListScreen extends ConsumerWidget {
  const BreedingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));

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
        title: AppScreenTitle(
          title: 'breeding.title'.tr(),
          iconAsset: AppIcons.breeding,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.arrowUpDown),
            tooltip: 'common.sort'.tr(),
            onPressed: () {
              final currentSort = ref.read(breedingSortProvider);
              showSortBottomSheet<BreedingSort>(
                context: context,
                values: BreedingSort.values,
                current: currentSort,
                labelOf: (s) => s.label,
                onSelected: (s) =>
                    ref.read(breedingSortProvider.notifier).state = s,
              );
            },
          ),
          const NotificationBellButton(),
          const ProfileMenuButton(),
        ],
      ),
      body: Column(
        children: [
          const BreedingSearchBar(),
          const Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),
          const SizedBox(height: AppSpacing.xs),
          const BreedingFilterBar(),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: AdBannerWidget(
              isPremiumProvider: isPremiumProvider,
              adBannerLoader: () => defaultAdBannerLoader(ref),
            ),
          ),
          Expanded(
            child: pairsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ErrorState(
                    message: 'common.data_load_error'.tr(),
                    onRetry: () =>
                        ref.invalidate(breedingPairsStreamProvider(userId)),
                  ),
                ),
              ),
              data: (allPairs) {
                final pairs = ref.watch(
                  sortedAndFilteredBreedingPairsProvider(allPairs),
                );

                if (allPairs.isEmpty) {
                  return EmptyState(
                    icon: const AppIcon(AppIcons.breeding),
                    title: 'breeding.no_breedings'.tr(),
                    subtitle: 'breeding.no_breedings_hint'.tr(),
                    actionLabel: 'breeding.add_breeding_label'.tr(),
                    onAction: () => context.push('/breeding/form'),
                  );
                }

                if (pairs.isEmpty) {
                  return EmptyState(
                    icon: const Icon(LucideIcons.searchX),
                    title: 'breeding.no_results'.tr(),
                    subtitle: 'breeding.no_results_hint'.tr(),
                  );
                }

                // Bulk-fetch incubation and egg maps (single stream each)
                final incubationMap = ref.watch(
                  incubationByPairMapProvider(userId),
                );
                final eggMap = ref.watch(eggsByIncubationMapProvider(userId));

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(breedingPairsStreamProvider(userId));
                        ref.invalidate(allIncubationsStreamProvider(userId));
                        ref.invalidate(eggsStreamProvider(userId));
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.xxxl * 2,
                        ),
                        itemCount: pairs.length,
                        itemBuilder: (context, index) {
                          final pair = pairs[index];
                          final incubation = incubationMap[pair.id];
                          final eggs = incubation != null
                              ? eggMap[incubation.id] ?? const <Egg>[]
                              : const <Egg>[];
                          return BreedingCard(
                            key: ValueKey(pair.id),
                            pair: pair,
                            incubation: incubation,
                            eggs: eggs,
                            onTap: () => navigateWithAd('/breeding/${pair.id}'),
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
        tooltip: 'breeding.new_breeding'.tr(),
        onPressed: () => context.push('/breeding/form'),
      ),
    );
  }
}
