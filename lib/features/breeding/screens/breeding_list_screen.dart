import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_bell_button.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_button.dart';

/// Main screen listing all breeding pairs with filter and search support.
class BreedingListScreen extends ConsumerStatefulWidget {
  const BreedingListScreen({super.key});

  @override
  ConsumerState<BreedingListScreen> createState() => _BreedingListScreenState();
}

class _BreedingListScreenState extends ConsumerState<BreedingListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final pairsAsync = ref.watch(breedingPairsStreamProvider(userId));
    final searchQuery = ref.watch(breedingSearchQueryProvider);

    void navigateWithAd(String route) {
      final isPremium = ref.read(isPremiumProvider);
      if (isPremium) {
        context.push(route);
        return;
      }
      ref.read(adServiceProvider).showInterstitialAd(
        onAdClosed: () {
          if (context.mounted) context.push(route);
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('breeding.title'.tr()),
        actions: const [NotificationBellButton(), ProfileMenuButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'breeding.search_hint'.tr(),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: AppIcon(AppIcons.search, size: 20),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(breedingSearchQueryProvider.notifier).state =
                              '';
                        },
                      )
                    : null,
                isDense: true,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
              ),
              onChanged: (value) {
                ref.read(breedingSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
          const SizedBox(height: AppSpacing.xs),
          const BreedingFilterBar(),
          const SizedBox(height: AppSpacing.sm),
          Center(child: AdBannerWidget(isPremiumProvider: isPremiumProvider)),
          Expanded(
            child: pairsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => ErrorState(
                message: 'common.data_load_error'.tr(),
                onRetry: () =>
                    ref.invalidate(breedingPairsStreamProvider(userId)),
              ),
              data: (allPairs) {
                final pairs = ref.watch(
                    searchedAndFilteredBreedingPairsProvider(allPairs));

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
                final incubationMap =
                    ref.watch(incubationByPairMapProvider(userId));
                final eggMap =
                    ref.watch(eggsByIncubationMapProvider(userId));

                return RefreshIndicator(
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

