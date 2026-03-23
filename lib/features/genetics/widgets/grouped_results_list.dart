import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';

/// Grouped offspring results list with probability section headers.
/// When multiple results share the same probability, they are grouped
/// under a header showing the percentage and count.
/// Caches grouping computation to avoid recalculating on every rebuild.
class GroupedResultsList extends StatefulWidget {
  final List<OffspringResult> results;
  final bool showGenotype;

  const GroupedResultsList({
    super.key,
    required this.results,
    this.showGenotype = false,
  });

  @override
  State<GroupedResultsList> createState() => _GroupedResultsListState();
}

class _GroupedResultsListState extends State<GroupedResultsList> {
  late Map<String, List<OffspringResult>> _cachedGroups;
  late bool _shouldGroup;

  @override
  void initState() {
    super.initState();
    _computeGroups();
  }

  @override
  void didUpdateWidget(GroupedResultsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.results, widget.results)) {
      _computeGroups();
    }
  }

  void _computeGroups() {
    _cachedGroups = _groupByProbability(widget.results);
    _shouldGroup = _cachedGroups.values.any((g) => g.length > 1);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return Center(
        child: Text(
          'genetics.no_results'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (!_shouldGroup) {
      return _FlatResultsList(
        results: widget.results,
        showGenotype: widget.showGenotype,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in _cachedGroups.entries) ...[
          _ProbabilityGroupHeader(
            percentage: entry.key,
            count: entry.value.length,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entry.value.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: OffspringPrediction(
                result: entry.value[index],
                showGenotype: widget.showGenotype,
                hideProgress: true,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Map<String, List<OffspringResult>> _groupByProbability(
    List<OffspringResult> results,
  ) {
    final groups = <String, List<OffspringResult>>{};
    for (final result in results) {
      final key = (result.probability * 100).toStringAsFixed(1);
      groups.putIfAbsent(key, () => []).add(result);
    }
    return groups;
  }
}

/// Section header showing probability and result count.
class _ProbabilityGroupHeader extends StatelessWidget {
  final String percentage;
  final int count;

  const _ProbabilityGroupHeader({
    required this.percentage,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Text(
              '%$percentage',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'genetics.probability_group_header'.tr(
              args: [count.toString()],
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple flat results list without grouping.
class _FlatResultsList extends StatelessWidget {
  final List<OffspringResult> results;
  final bool showGenotype;

  const _FlatResultsList({
    required this.results,
    this.showGenotype = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: OffspringPrediction(
          result: results[index],
          showGenotype: showGenotype,
        ),
      ),
    );
  }
}
