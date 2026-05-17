import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/sort_bottom_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_card.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_grid_card.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_search_bar.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/cage_ledger_sheet.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/app_shell.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

part 'bird_list_selection_cards.dart';

// IMPROVED: converted to ConsumerStatefulWidget to support bulk selection mode
/// Main screen listing all birds with search, filter, sort, and bulk actions.
class BirdListScreen extends ConsumerStatefulWidget {
  const BirdListScreen({super.key});

  @override
  ConsumerState<BirdListScreen> createState() => _BirdListScreenState();
}

class _BirdListScreenState extends ConsumerState<BirdListScreen> {
  static const double _listBottomInset = AppSpacing.xxxl * 4;

  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _navigateWithAd(String route) {
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) {
      context.push(route);
      return;
    }
    ref
        .read(adServiceProvider)
        .showInterstitialAd(
          onAdClosed: () {
            if (mounted) context.push(route);
          },
        );
  }

  void _showCageLedger(List<Bird> birds) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => CageLedgerSheet(
        birds: birds,
        onBirdTap: (bird) {
          Navigator.of(sheetContext).pop();
          _navigateWithAd('${AppRoutes.birds}/${bird.id}');
        },
      ),
    );
  }

  Future<void> _bulkDelete() async {
    final count = _selectedIds.length;
    final confirmed = await showConfirmDialog(
      context,
      title: 'common.confirm_delete'.tr(),
      message: 'birds.bulk_delete_confirm'.tr(args: ['$count']),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(birdFormStateProvider.notifier);
    final failures = <String>[];
    for (final id in _selectedIds.toList()) {
      if (!mounted) return;
      try {
        await notifier.deleteBird(id);
      } catch (e, st) {
        AppLogger.error('[BirdListScreen] bulkDelete failed for $id', e, st);
        failures.add(id);
      }
    }
    if (!mounted) return;
    if (failures.isEmpty) {
      _clearSelection();
    } else {
      setState(() {
        _selectedIds
          ..clear()
          ..addAll(failures);
      });
    }
  }

  Future<void> _bulkMarkAsDead() async {
    final count = _selectedIds.length;
    final confirmed = await showConfirmDialog(
      context,
      title: 'birds.mark_dead'.tr(),
      message: 'birds.bulk_mark_dead_confirm'.tr(args: ['$count']),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(birdFormStateProvider.notifier);
    final failures = <String>[];
    for (final id in _selectedIds.toList()) {
      if (!mounted) return;
      try {
        await notifier.markAsDead(id);
      } catch (e, st) {
        AppLogger.error(
          '[BirdListScreen] bulkMarkAsDead failed for $id',
          e,
          st,
        );
        failures.add(id);
      }
    }
    if (!mounted) return;
    if (failures.isEmpty) {
      _clearSelection();
    } else {
      setState(() {
        _selectedIds
          ..clear()
          ..addAll(failures);
      });
    }
  }

  Future<void> _bulkMarkAsSold() async {
    final count = _selectedIds.length;
    final confirmed = await showConfirmDialog(
      context,
      title: 'birds.mark_sold'.tr(),
      message: 'birds.bulk_mark_sold_confirm'.tr(args: ['$count']),
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(birdFormStateProvider.notifier);
    final failures = <String>[];
    for (final id in _selectedIds.toList()) {
      if (!mounted) return;
      try {
        await notifier.markAsSold(id);
      } catch (e, st) {
        AppLogger.error(
          '[BirdListScreen] bulkMarkAsSold failed for $id',
          e,
          st,
        );
        failures.add(id);
      }
    }
    if (!mounted) return;
    if (failures.isEmpty) {
      _clearSelection();
    } else {
      setState(() {
        _selectedIds
          ..clear()
          ..addAll(failures);
      });
    }
  }

  Future<void> _bulkMarkAsGifted() async {
    final count = _selectedIds.length;
    final confirmed = await showConfirmDialog(
      context,
      title: 'birds.mark_gifted'.tr(),
      message: 'birds.bulk_mark_gifted_confirm'.tr(args: ['$count']),
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(birdFormStateProvider.notifier);
    final failures = <String>[];
    for (final id in _selectedIds.toList()) {
      if (!mounted) return;
      try {
        await notifier.markAsGifted(id);
      } catch (e, st) {
        AppLogger.error(
          '[BirdListScreen] bulkMarkAsGifted failed for $id',
          e,
          st,
        );
        failures.add(id);
      }
    }
    if (!mounted) return;
    if (failures.isEmpty) {
      _clearSelection();
    } else {
      setState(() {
        _selectedIds
          ..clear()
          ..addAll(failures);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));
    final currentSort = ref.watch(birdSortProvider);
    final viewMode = ref.watch(birdListViewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text(
                'common.selection_count'.tr(args: ['${_selectedIds.length}']),
                style: Theme.of(context).textTheme.titleMedium,
              )
            : birdsAsync.whenOrNull(
                    data: (allBirds) => AppScreenTitle(
                      title: '${'birds.title'.tr()} (${allBirds.length})',
                      iconAsset: AppIcons.bird,
                    ),
                  ) ??
                  AppScreenTitle(
                    title: 'birds.title'.tr(),
                    iconAsset: AppIcons.bird,
                  ),
        leading: _isSelectionMode
            ? AppIconButton(
                icon: const Icon(LucideIcons.x),
                semanticLabel: 'common.cancel'.tr(),
                onPressed: _clearSelection,
              )
            : null,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: _isSelectionMode
            ? [
                AppIconButton(
                  icon: const AppIcon(AppIcons.delete),
                  tooltip: 'common.delete'.tr(),
                  semanticLabel: 'common.delete'.tr(),
                  onPressed: _bulkDelete,
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'dead') _bulkMarkAsDead();
                    if (action == 'sold') _bulkMarkAsSold();
                    if (action == 'gifted') _bulkMarkAsGifted();
                  },
                  itemBuilder: (_) => _buildSelectionActionItems(),
                ),
              ]
            : [
                AppIconButton(
                  icon: const AppIcon(AppIcons.nest),
                  tooltip: 'birds.cage_ledger'.tr(),
                  semanticLabel: 'birds.cage_ledger'.tr(),
                  onPressed: () {
                    final birds = birdsAsync.value ?? const <Bird>[];
                    _showCageLedger(birds);
                  },
                ),
                AppIconButton(
                  icon: Icon(
                    viewMode == BirdListViewMode.list
                        ? LucideIcons.layoutGrid
                        : LucideIcons.list,
                  ),
                  tooltip: viewMode == BirdListViewMode.list
                      ? 'birds.grid_view'.tr()
                      : 'birds.list_view'.tr(),
                  semanticLabel: viewMode == BirdListViewMode.list
                      ? 'birds.grid_view'.tr()
                      : 'birds.list_view'.tr(),
                  onPressed: () {
                    final nextMode = viewMode == BirdListViewMode.list
                        ? BirdListViewMode.grid
                        : BirdListViewMode.list;
                    ref
                        .read(birdListViewModeProvider.notifier)
                        .setMode(nextMode);
                  },
                ),
                AppIconButton(
                  icon: const Icon(LucideIcons.arrowUpDown),
                  tooltip: 'common.sort'.tr(),
                  semanticLabel: 'common.sort'.tr(),
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
          if (!_isSelectionMode) ...[
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
          ],
          Expanded(
            child: birdsAsync.when(
              loading: () => const LoadingState(),
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
                    onAction: () => context.push('${AppRoutes.birds}/form'),
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
                    constraints: BoxConstraints(
                      maxWidth: viewMode == BirdListViewMode.grid ? 1000 : 800,
                    ),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(birdsStreamProvider(userId));
                      },
                      child: viewMode == BirdListViewMode.grid
                          ? GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                AppSpacing.sm,
                                AppSpacing.lg,
                                _listBottomInset,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 180,
                                    mainAxisExtent: 230,
                                    mainAxisSpacing: AppSpacing.sm,
                                    crossAxisSpacing: AppSpacing.sm,
                                  ),
                              itemCount: birds.length,
                              itemBuilder: (context, index) {
                                final bird = birds[index];
                                final isSelected = _selectedIds.contains(
                                  bird.id,
                                );
                                return _SelectableBirdGridCard(
                                  key: ValueKey(bird.id),
                                  bird: bird,
                                  isSelected: isSelected,
                                  isSelectionMode: _isSelectionMode,
                                  onTap: _isSelectionMode
                                      ? () => _toggleSelection(bird.id)
                                      : () => _navigateWithAd(
                                          '${AppRoutes.birds}/${bird.id}',
                                        ),
                                  onLongPress: () {
                                    AppHaptics.mediumImpact();
                                    _toggleSelection(bird.id);
                                  },
                                );
                              },
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                                bottom: _listBottomInset,
                              ),
                              itemCount: birds.length,
                              itemBuilder: (context, index) {
                                final bird = birds[index];
                                final isSelected = _selectedIds.contains(
                                  bird.id,
                                );
                                return _SelectableBirdCard(
                                  key: ValueKey(bird.id),
                                  bird: bird,
                                  isSelected: isSelected,
                                  isSelectionMode: _isSelectionMode,
                                  onTap: _isSelectionMode
                                      ? () => _toggleSelection(bird.id)
                                      : () => _navigateWithAd(
                                          '${AppRoutes.birds}/${bird.id}',
                                        ),
                                  onLongPress: () {
                                    AppHaptics.mediumImpact();
                                    _toggleSelection(bird.id);
                                  },
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
      floatingActionButton: _isSelectionMode
          ? null
          : FabButton(
              icon: const AppIcon(AppIcons.add),
              tooltip: 'birds.new_bird'.tr(),
              onPressed: () => context.push('${AppRoutes.birds}/form'),
            ),
    );
  }
}
