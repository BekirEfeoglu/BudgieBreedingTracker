import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_calculation_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/ancestor_list_view.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/family_stats_section.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/family_tree_view.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/genetic_info_card.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/offspring_section.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/pedigree_export_button.dart';

enum TreeViewMode { tree, list }

class TreeViewModeNotifier extends Notifier<TreeViewMode> {
  @override
  TreeViewMode build() => TreeViewMode.tree;
}

final treeViewModeProvider =
    NotifierProvider<TreeViewModeNotifier, TreeViewMode>(TreeViewModeNotifier.new);

/// Main tree content: tree view + stats + offspring + export.
class TreeContent extends ConsumerStatefulWidget {
  final String entityId;
  final bool isChick;

  const TreeContent({super.key, required this.entityId, required this.isChick});

  @override
  ConsumerState<TreeContent> createState() => _TreeContentState();
}

class _TreeContentState extends ConsumerState<TreeContent> {
  final _treeViewKey = GlobalKey<FamilyTreeViewState>();

  @override
  Widget build(BuildContext context) {
    final ancestorsAsync = widget.isChick
        ? ref.watch(chickAncestorsProvider(widget.entityId))
        : ref.watch(ancestorsProvider(widget.entityId));

    final offspringAsync =
        widget.isChick ? null : ref.watch(offspringProvider(widget.entityId));

    return ancestorsAsync.when(
      loading: () => const _GenealogySkeletonLoader(),
      error: (error, _) => ErrorState(
        message: 'genealogy.tree_error'.tr(),
        onRetry: () {
          if (widget.isChick) {
            ref.invalidate(chickAncestorsProvider(widget.entityId));
          } else {
            ref.invalidate(ancestorsProvider(widget.entityId));
            ref.invalidate(offspringProvider(widget.entityId));
          }
        },
      ),
      data: (ancestors) {
        final rootBird = ancestors[widget.entityId];
        if (rootBird == null) {
          return Center(child: Text('genealogy.bird_not_found'.tr()));
        }

        final offspringBirds = offspringAsync?.whenOrNull(
          data: (offspring) => offspring.birds,
        );
        final offspringChicks = offspringAsync?.whenOrNull(
          data: (offspring) => offspring.chicks,
        );

        final maxDepth = ref.watch(pedigreeDepthProvider);
        final entityParams = (entityId: widget.entityId, isChick: widget.isChick);
        final statsAsync = ref.watch(ancestorStatsProvider(entityParams));
        final inbreedingAsync = ref.watch(inbreedingDataProvider(entityParams));
        final ancestorStats = statsAsync.value ??
            calculateAncestorStats(widget.entityId, ancestors, maxDepth: maxDepth);
        final inbreedingData = inbreedingAsync.value ??
            calculateInbreedingForBird(widget.entityId, ancestors);
        final screenSize = MediaQuery.of(context).size;
        final isLandscape = screenSize.width > screenSize.height;
        final viewMode = ref.watch(treeViewModeProvider);
        // Dynamic height based on depth — adapt for iPad landscape
        final baseHeight = isLandscape ? screenSize.height * 0.85 : screenSize.height;
        final treeMaxHeight = switch (maxDepth) {
          <= 3 => baseHeight * 0.45,
          <= 5 => baseHeight * 0.60,
          _ => baseHeight * 0.70,
        };

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // View mode toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SegmentedButton<TreeViewMode>(
                  segments: [
                    ButtonSegment(
                      value: TreeViewMode.tree,
                      label: Text('genealogy.tree_view'.tr()),
                      icon: const AppIcon(AppIcons.genealogy, size: 16),
                    ),
                    ButtonSegment(
                      value: TreeViewMode.list,
                      label: Text('genealogy.list_view'.tr()),
                      icon: const Icon(LucideIcons.list, size: 16),
                    ),
                  ],
                  selected: {viewMode},
                  onSelectionChanged: (s) => ref
                      .read(treeViewModeProvider.notifier)
                      .state = s.first,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Tree or list view with animated transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeIn,
                switchOutCurve: Curves.easeOut,
                child: viewMode == TreeViewMode.tree
                    ? ConstrainedBox(
                        key: const ValueKey('tree'),
                        constraints: BoxConstraints(
                          minHeight: 200,
                          maxHeight: treeMaxHeight,
                        ),
                        child: FamilyTreeView(
                          key: _treeViewKey,
                          rootBird: rootBird,
                          ancestors: ancestors,
                          offspringBirds: offspringBirds ?? [],
                          maxDepth: maxDepth,
                          commonAncestorIds: inbreedingData.commonAncestorIds,
                          isRootChick: widget.isChick,
                        ),
                      )
                    : AncestorListView(
                        key: const ValueKey('list'),
                        rootBird: rootBird,
                        ancestors: ancestors,
                        maxDepth: maxDepth,
                        commonAncestorIds: inbreedingData.commonAncestorIds,
                        isRootChick: widget.isChick,
                      ),
              ),
              // Family stats
              FamilyStatsSection(
                ancestorStats: ancestorStats,
                inbreedingData: inbreedingData,
                offspringBirds: offspringBirds ?? [],
                offspringChicks: offspringChicks ?? [],
              ),
              // Genetic info (if bird has mutation data)
              if (rootBird.mutations != null &&
                  rootBird.mutations!.isNotEmpty)
                GeneticInfoCard(
                  mutations: rootBird.mutations!
                      .map((m) => GeneticMutation(
                            name: m,
                            allele: rootBird.genotypeInfo?[m],
                            isVisible:
                                rootBird.genotypeInfo?[m] == 'visual',
                          ))
                      .toList(),
                ),
              // Offspring section
              if (offspringAsync != null)
                offspringAsync.when(
                  loading: () => const Padding(
                    padding: AppSpacing.screenPadding,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                  error: (_, __) => Padding(
                    padding: AppSpacing.screenPadding,
                    child: ErrorState(
                      message: 'genealogy.offspring_load_error'.tr(),
                      onRetry: () =>
                          ref.invalidate(offspringProvider(widget.entityId)),
                    ),
                  ),
                  data: (offspring) => OffspringSection(
                    birds: offspring.birds,
                    chicks: offspring.chicks,
                  ),
                ),
              // Pedigree export (PDF + Image)
              PedigreeExportButton(
                rootBird: rootBird,
                ancestors: ancestors,
                maxDepth: maxDepth,
                onCaptureImage: viewMode == TreeViewMode.tree
                    ? () => _treeViewKey.currentState?.captureTreeImage() ?? Future.value(null)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Skeleton loader that mimics tree structure during loading.
class _GenealogySkeletonLoader extends StatelessWidget {
  const _GenealogySkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          // Segmented button placeholder
          SkeletonLoader(height: 40, borderRadius: AppSpacing.radiusMd),
          SizedBox(height: AppSpacing.lg),
          // Tree-like skeleton
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Root node
              SkeletonLoader(width: 130, height: 70, borderRadius: AppSpacing.radiusMd),
              SizedBox(width: AppSpacing.md),
              // Branch lines placeholder
              SkeletonLoader(width: 40, height: 2),
              SizedBox(width: AppSpacing.md),
              // Parent nodes
              Column(
                children: [
                  SkeletonLoader(width: 110, height: 60, borderRadius: AppSpacing.radiusMd),
                  SizedBox(height: AppSpacing.lg),
                  SkeletonLoader(width: 110, height: 60, borderRadius: AppSpacing.radiusMd),
                ],
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          // Stats section skeleton
          SkeletonLoader(height: 20, width: 160),
          SizedBox(height: AppSpacing.md),
          SkeletonLoader(height: 120, borderRadius: AppSpacing.radiusMd),
        ],
      ),
    );
  }
}
