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
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_search_bar.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/app_shell.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));
    final currentSort = ref.watch(birdSortProvider);

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
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'dead',
                      child: Text('birds.mark_dead'.tr()),
                    ),
                    PopupMenuItem(
                      value: 'sold',
                      child: Text('birds.mark_sold'.tr()),
                    ),
                  ],
                ),
              ]
            : [
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
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(birdsStreamProvider(userId));
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: _listBottomInset,
                        ),
                        itemCount: birds.length,
                        itemBuilder: (context, index) {
                          final bird = birds[index];
                          final isSelected = _selectedIds.contains(bird.id);
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

/// Wraps [BirdCard] with selection mode visuals (checkbox, border highlight).
class _SelectableBirdCard extends StatelessWidget {
  final Bird bird;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SelectableBirdCard({
    super.key,
    required this.bird,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                border: Border.all(color: theme.colorScheme.primary, width: 2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              )
            : null,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onTap(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            Expanded(
              child: BirdCard(bird: bird, onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}
