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
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/sort_bottom_sheet.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/shared/providers/chicks.dart';
import 'package:budgie_breeding_tracker/domain/services/premium/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_card.dart';
import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_filter_bar.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_search_bar.dart';
import 'package:budgie_breeding_tracker/shared/widgets/app_shell.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

// IMPROVED: converted to ConsumerStatefulWidget to support bulk selection mode
/// Main screen listing all chicks with search, filter, and bulk actions.
class ChickListScreen extends ConsumerStatefulWidget {
  const ChickListScreen({super.key});

  @override
  ConsumerState<ChickListScreen> createState() => _ChickListScreenState();
}

class _ChickListScreenState extends ConsumerState<ChickListScreen> {
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

  void _clearSelection() => setState(() => _selectedIds.clear());

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      context.pop();
      return;
    }
    context.push(AppRoutes.more);
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
      message: 'chicks.bulk_delete_confirm'.tr(args: ['$count']),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(chickFormStateProvider.notifier);
    final failures = <String>[];
    for (final id in _selectedIds.toList()) {
      if (!mounted) return;
      try {
        await notifier.deleteChick(id);
      } catch (_) {
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

  Future<void> _bulkMarkAsDeceased() async {
    final count = _selectedIds.length;
    final confirmed = await showConfirmDialog(
      context,
      title: 'chicks.mark_dead'.tr(),
      message: 'chicks.bulk_mark_deceased_confirm'.tr(args: ['$count']),
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;

    final notifier = ref.read(chickFormStateProvider.notifier);
    final failures = <String>[];
    for (final id in _selectedIds.toList()) {
      if (!mounted) return;
      try {
        await notifier.markAsDeceased(id);
      } catch (_) {
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
    final chicksAsync = ref.watch(chicksStreamProvider(userId));
    final parentsByEggAsync = ref.watch(chickParentsByEggProvider(userId));

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? AppIconButton(
                icon: const Icon(LucideIcons.x),
                semanticLabel: 'common.cancel'.tr(),
                onPressed: _clearSelection,
              )
            : AppIconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                tooltip: 'common.back'.tr(),
                semanticLabel: 'common.back'.tr(),
                onPressed: _handleBack,
              ),
        title: _isSelectionMode
            ? Text(
                'common.selection_count'.tr(args: ['${_selectedIds.length}']),
                style: Theme.of(context).textTheme.titleMedium,
              )
            : AppScreenTitle(
                title: 'chicks.title'.tr(),
                iconAsset: AppIcons.chick,
              ),
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
                    if (action == 'deceased') _bulkMarkAsDeceased();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'deceased',
                      child: Text('chicks.mark_dead'.tr()),
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
          if (!_isSelectionMode) ...[
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
          ],
          Expanded(
            child: chicksAsync.when(
              loading: () => const LoadingState(),
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
                    onAction: () => context.push(AppRoutes.chickForm),
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
                          final chick = chicks[index];
                          final isSelected = _selectedIds.contains(chick.id);
                          return _SelectableChickCard(
                            key: ValueKey(chick.id),
                            chick: chick,
                            parents: chick.eggId == null
                                ? null
                                : parentsByEgg[chick.eggId!],
                            isSelected: isSelected,
                            isSelectionMode: _isSelectionMode,
                            onTap: _isSelectionMode
                                ? () => _toggleSelection(chick.id)
                                : () => _navigateWithAd(
                                    '${AppRoutes.chicks}/${chick.id}',
                                  ),
                            onLongPress: () {
                              AppHaptics.mediumImpact();
                              _toggleSelection(chick.id);
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
              tooltip: 'chicks.new_chick'.tr(),
              onPressed: () => context.push(AppRoutes.chickForm),
            ),
    );
  }
}

/// Wraps [ChickCard] with selection mode visuals (checkbox, border highlight).
class _SelectableChickCard extends StatelessWidget {
  final Chick chick;
  final ChickParentsInfo? parents;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SelectableChickCard({
    super.key,
    required this.chick,
    required this.parents,
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
              child: ChickCard(
                chick: chick,
                resolveParents: false,
                parents: parents,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
