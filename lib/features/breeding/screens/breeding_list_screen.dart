import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/sort_bottom_sheet.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/incubation_risk_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/egg_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_card.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_search_bar.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/incubation_risk_card.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/shared/widgets/app_shell.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

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
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          AppIconButton(
            icon: const Icon(LucideIcons.arrowUpDown),
            tooltip: 'common.sort'.tr(),
            semanticLabel: 'common.sort'.tr(),
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
            // skipLoadingOnRefresh keeps the populated list on screen
            // during pull-to-refresh / provider invalidation instead of
            // collapsing back to the spinner (ui-patterns.md).
            child: pairsAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const LoadingState(),
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
                    onAction: () => context.push(AppRoutes.breedingForm),
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

                // The risk summary derives from four streams + DateTime.now().
                // It is rendered by a dedicated leaf widget (item 0) so that a
                // summary change rebuilds only that card, not the whole list.
                // Item 0 is always present and collapses to zero height while
                // the summary is loading / errored, so the index math stays
                // simple (no hasRiskCard offset).
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(breedingPairsStreamProvider(userId));
                        ref.invalidate(allIncubationsStreamProvider(userId));
                        ref.invalidate(eggsStreamProvider(userId));
                        ref.invalidate(chicksStreamProvider(userId));
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.lg,
                        ),
                        itemCount: pairs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _RiskSummaryHeaderCard(userId: userId);
                          }
                          final pair = pairs[index - 1];
                          final incubation = incubationMap[pair.id];
                          final eggs = incubation != null
                              ? eggMap[incubation.id] ?? const <Egg>[]
                              : const <Egg>[];
                          return BreedingCard(
                            key: ValueKey(pair.id),
                            pair: pair,
                            incubation: incubation,
                            eggs: eggs,
                            onTap: () => navigateWithAd(
                              AppRoutes.breedingDetail.replaceFirst(
                                ':id',
                                pair.id,
                              ),
                            ),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: FabButton(
              icon: const AppIcon(AppIcons.add),
              tooltip: 'breeding.new_breeding'.tr(),
              onPressed: () => context.push(AppRoutes.breedingForm),
            ),
          ),
        ),
      ),
    );
  }
}

/// List-header leaf for the incubation risk summary.
///
/// Isolated from the breeding list body so that
/// [incubationRiskSummaryProvider] — which derives from four streams plus
/// `DateTime.now()` and recomputes a full risk reassessment on each emission —
/// rebuilds only this card. The card collapses to zero height while the
/// summary is loading or errored, so the surrounding `ListView` index math
/// can treat it as an always-present item 0.
class _RiskSummaryHeaderCard extends ConsumerWidget {
  const _RiskSummaryHeaderCard({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskSummary = ref
        .watch(incubationRiskSummaryProvider(userId))
        .value;
    if (riskSummary == null) return const SizedBox.shrink();
    return IncubationRiskCard(risks: riskSummary.topRisks(limit: 3));
  }
}
