import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/offspring_prediction.dart';

/// Maximum visible results before collapsing with "show more".
const _initialVisibleCount = 6;

/// Tabbed view showing offspring results filtered by sex:
/// All / Male / Female.
class SexSpecificResults extends StatefulWidget {
  final List<OffspringResult> results;
  final bool showGenotype;

  const SexSpecificResults({
    super.key,
    required this.results,
    this.showGenotype = false,
  });

  @override
  State<SexSpecificResults> createState() => _SexSpecificResultsState();
}

class _SexSpecificResultsState extends State<SexSpecificResults>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSexSpecific = widget.results.any(
      (r) => r.sex != OffspringSex.both,
    );

    // If no sex-specific results, just show all
    if (!hasSexSpecific) {
      return _ResultsList(
        results: widget.results,
        showGenotype: widget.showGenotype,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'genetics.all_offspring'.tr()),
            Tab(text: 'genetics.male_offspring'.tr()),
            Tab(text: 'genetics.female_offspring'.tr()),
          ],
          labelStyle: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: theme.textTheme.labelMedium,
          indicatorSize: TabBarIndicatorSize.label,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(_tabController.index),
            child: _buildCurrentTab(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTab() {
    return switch (_tabController.index) {
      1 => _ResultsList(
        results: _filterBySex(widget.results, OffspringSex.male),
        showGenotype: widget.showGenotype,
        emptyMessage: 'genetics.no_male_results'.tr(),
      ),
      2 => _ResultsList(
        results: _filterBySex(widget.results, OffspringSex.female),
        showGenotype: widget.showGenotype,
        emptyMessage: 'genetics.no_female_results'.tr(),
      ),
      _ => _ResultsList(
        results: widget.results,
        showGenotype: widget.showGenotype,
      ),
    };
  }

  List<OffspringResult> _filterBySex(
    List<OffspringResult> results,
    OffspringSex sex,
  ) {
    return results
        .where((r) => r.sex == sex || r.sex == OffspringSex.both)
        .toList();
  }
}

class _ResultsList extends StatefulWidget {
  final List<OffspringResult> results;
  final bool showGenotype;
  final String? emptyMessage;

  const _ResultsList({
    required this.results,
    this.showGenotype = false,
    this.emptyMessage,
  });

  @override
  State<_ResultsList> createState() => _ResultsListState();
}

class _ResultsListState extends State<_ResultsList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return Center(
        child: Text(
          widget.emptyMessage ?? 'genetics.no_results'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final hasMore = widget.results.length > _initialVisibleCount;
    final visibleResults = hasMore && !_expanded
        ? widget.results.take(_initialVisibleCount).toList()
        : widget.results;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          itemCount: visibleResults.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: OffspringPrediction(
              result: visibleResults[index],
              showGenotype: widget.showGenotype,
            ),
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              label: Text(
                _expanded
                    ? 'genetics.show_less_results'.tr()
                    : 'genetics.show_more_results'.tr(
                        args: [widget.results.length.toString()],
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
