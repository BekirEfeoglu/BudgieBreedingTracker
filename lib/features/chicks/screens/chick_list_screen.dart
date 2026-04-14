import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/sort_bottom_sheet.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/premium_shared_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_card.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_search_bar.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_bell_button.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_button.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Main screen listing all chicks with search and filter support.
class ChickListScreen extends ConsumerWidget {
  const ChickListScreen({super.key});

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.push(AppRoutes.more);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final chicksAsync = ref.watch(chicksStreamProvider(userId));
    final parentsByEggAsync = ref.watch(chickParentsByEggProvider(userId));
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
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          tooltip: 'common.back'.tr(),
          onPressed: () => _handleBack(context),
        ),
        title: AppScreenTitle(
          title: 'chicks.title'.tr(),
          iconAsset: AppIcons.chick,
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.arrowUpDown),
            tooltip: 'common.sort'.tr(),
            onPressed: () {
              final currentSort = ref.read(chickSortProvider);
              showSortBottomSheet<ChickSort>(
                context: context,
                values: ChickSort.values,
                current: currentSort,
                labelOf: (s) => s.label,
                onSelected: (s) =>
                    ref.read(chickSortProvider.notifier).setSort(s),
              );
            },
          ),
          const NotificationBellButton(),
          const ProfileMenuButton(),
        ],
      ),
      body: Column(
        children: [
          const ChickSearchBar(),
          const Divider(
            height: 1,
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
          ),
          const SizedBox(height: AppSpacing.xs),
          const ChickFilterBar(),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: AdBannerWidget(
              isPremiumProvider: isPremiumProvider,
              adBannerLoader: () => defaultAdBannerLoader(ref),
            ),
          ),
          Expanded(
            child: chicksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ErrorState(
                    message: 'common.data_load_error'.tr(),
                    onRetry: () {
                      ref.invalidate(chicksStreamProvider(userId));
                      ref.invalidate(chickParentsByEggProvider(userId));
                    },
                  ),
                ),
              ),
              data: (allChicks) {
                final chicks = ref.watch(
                  searchedAndFilteredChicksProvider(allChicks),
                );
                final parentsByEgg = switch (parentsByEggAsync) {
                  AsyncData(:final value) => value,
                  _ => const <String, ChickParentsInfo>{},
                };

                if (allChicks.isEmpty) {
                  return EmptyState(
                    icon: const AppIcon(AppIcons.chick),
                    title: 'chicks.no_chicks'.tr(),
                    subtitle: 'chicks.no_chicks_hint'.tr(),
                    actionLabel: 'chicks.add_chick'.tr(),
                    onAction: () => context.push('/chicks/form'),
                  );
                }

                if (chicks.isEmpty) {
                  return EmptyState(
                    icon: const Icon(LucideIcons.searchX),
                    title: 'common.no_results'.tr(),
                    subtitle: 'common.no_results_hint'.tr(),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(chicksStreamProvider(userId));
                        ref.invalidate(chickParentsByEggProvider(userId));
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.xxxl * 2,
                        ),
                        itemCount: chicks.length,
                        itemBuilder: (context, index) {
                          return ChickCard(
                            key: ValueKey(chicks[index].id),
                            chick: chicks[index],
                            resolveParents: false,
                            parents: chicks[index].eggId == null
                                ? null
                                : parentsByEgg[chicks[index].eggId!],
                            onTap: () =>
                                navigateWithAd('/chicks/${chicks[index].id}'),
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
        tooltip: 'chicks.new_chick'.tr(),
        onPressed: () => context.push('/chicks/form'),
      ),
    );
  }
}
