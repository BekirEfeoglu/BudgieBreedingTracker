import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/pedigree_node.dart';
import 'package:budgie_breeding_tracker/features/genealogy/widgets/tree_connectors.dart';

/// Bidirectional pedigree tree: offspring on the left, ancestors on the right.
/// Wrapped in an [InteractiveViewer] for zoom and pan.
class FamilyTreeView extends StatefulWidget {
  final Bird rootBird;
  final Map<String, Bird> ancestors;
  final List<Bird> offspringBirds;
  final int maxDepth;
  final Set<String> commonAncestorIds;
  final bool isRootChick;

  const FamilyTreeView({
    super.key,
    required this.rootBird,
    required this.ancestors,
    this.offspringBirds = const [],
    this.maxDepth = 5,
    this.commonAncestorIds = const {},
    this.isRootChick = false,
  });

  @override
  State<FamilyTreeView> createState() => FamilyTreeViewState();
}

class FamilyTreeViewState extends State<FamilyTreeView> {
  final _transformationController = TransformationController();
  final _repaintBoundaryKey = GlobalKey();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  /// Captures the tree as a PNG image for sharing.
  Future<ui.Image?> captureTreeImage() async {
    final boundary =
        _repaintBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    return boundary.toImage(pixelRatio: 3.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Pre-compute sibling counts in O(n) instead of O(n²) per node
    final siblingCounts = _buildSiblingCountMap();

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.3,
          maxScale: 2.5,
          child: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hint text
                  Text(
                    'genealogy.tap_node_hint'.tr(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Left side: offspring
                      if (widget.offspringBirds.isNotEmpty) ...[
                        _buildOffspringColumn(),
                        _buildOffspringConnector(theme),
                      ],
                      // Center + Right: root with ancestors
                      _buildAncestorTree(
                        context,
                        widget.rootBird,
                        0,
                        siblingCounts,
                        theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Reset zoom button (bottom-right)
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: FloatingActionButton.small(
            heroTag: 'zoom_reset',
            onPressed: _resetView,
            tooltip: 'genealogy.zoom_to_fit'.tr(),
            child: const Icon(LucideIcons.maximize2, size: 18),
          ),
        ),
      ],
    );
  }

  /// Builds a column of offspring nodes on the left side.
  Widget _buildOffspringColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: widget.offspringBirds.map((bird) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: PedigreeNode(bird: bird),
        );
      }).toList(),
    );
  }

  /// Connector from offspring column to the root node.
  Widget _buildOffspringConnector(ThemeData theme) {
    final count = widget.offspringBirds.length;
    final connectorHeight = count > 1 ? (count * 70.0) : 70.0;
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(48, connectorHeight),
        painter: OffspringConnectorPainter(
          childCount: count,
          lineColor: theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }

  /// Pre-computes sibling count for each bird in O(n).
  Map<String, int> _buildSiblingCountMap() {
    final fatherChildren = <String, int>{};
    final motherChildren = <String, int>{};

    for (final bird in widget.ancestors.values) {
      if (bird.fatherId != null) {
        fatherChildren[bird.fatherId!] =
            (fatherChildren[bird.fatherId!] ?? 0) + 1;
      }
      if (bird.motherId != null) {
        motherChildren[bird.motherId!] =
            (motherChildren[bird.motherId!] ?? 0) + 1;
      }
    }

    final counts = <String, int>{};
    for (final bird in widget.ancestors.values) {
      final fromFather = bird.fatherId != null
          ? (fatherChildren[bird.fatherId!] ?? 1) - 1
          : 0;
      final fromMother = bird.motherId != null
          ? (motherChildren[bird.motherId!] ?? 1) - 1
          : 0;
      // Use max to avoid double-counting full siblings
      counts[bird.id] = fromFather > fromMother ? fromFather : fromMother;
    }
    return counts;
  }

  /// Recursively builds the tree from left (root) to right (ancestors).
  Widget _buildAncestorTree(
    BuildContext context,
    Bird? bird,
    int depth,
    Map<String, int> siblingCounts,
    ThemeData theme,
  ) {
    if (depth > widget.maxDepth || bird == null) {
      return PedigreeNode(
        bird: bird,
        placeholder: 'genealogy.unknown_parent'.tr(),
        isCommonAncestor:
            bird != null && widget.commonAncestorIds.contains(bird.id),
        depth: depth,
      );
    }

    final father = bird.fatherId != null
        ? widget.ancestors[bird.fatherId]
        : null;
    final mother = bird.motherId != null
        ? widget.ancestors[bird.motherId]
        : null;
    final hasParents = bird.fatherId != null || bird.motherId != null;
    final isRootNode = depth == 0;
    final isCommon = widget.commonAncestorIds.contains(bird.id);
    final siblings = siblingCounts[bird.id] ?? 0;

    // Root node that is a chick should navigate to /chicks/:id
    final VoidCallback? nodeOnTap = (isRootNode && widget.isRootChick)
        ? () => context.push('/chicks/${bird.id}')
        : null;

    if (!hasParents || depth >= widget.maxDepth) {
      return PedigreeNode(
        bird: bird,
        isRoot: isRootNode,
        isCommonAncestor: isCommon,
        siblingCount: siblings,
        onTap: nodeOnTap,
        depth: depth,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        PedigreeNode(
          bird: bird,
          isRoot: isRootNode,
          isCommonAncestor: isCommon,
          siblingCount: siblings,
          onTap: nodeOnTap,
          depth: depth,
        ),
        _buildAncestorConnector(depth, theme),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Generation label for father line
            if (depth == 0)
              GenerationLabel(label: 'genealogy.father_line'.tr()),
            _buildAncestorTree(
              context,
              father,
              depth + 1,
              siblingCounts,
              theme,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildAncestorTree(
              context,
              mother,
              depth + 1,
              siblingCounts,
              theme,
            ),
            // Generation label for mother line
            if (depth == 0)
              GenerationLabel(label: 'genealogy.mother_line'.tr()),
          ],
        ),
      ],
    );
  }

  Widget _buildAncestorConnector(int depth, ThemeData theme) {
    return RepaintBoundary(
      child: CustomPaint(
        size: const Size(48, 70),
        painter: AncestorConnectorPainter(
          depth: depth,
          baseColor: theme.colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
