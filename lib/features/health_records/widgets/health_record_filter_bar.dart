import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/fade_scrollable_chip_bar.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';

/// Horizontal scrollable filter bar with choice chips for health records.
class HealthRecordFilterBar extends ConsumerStatefulWidget {
  const HealthRecordFilterBar({super.key});

  @override
  ConsumerState<HealthRecordFilterBar> createState() =>
      _HealthRecordFilterBarState();
}

class _HealthRecordFilterBarState extends ConsumerState<HealthRecordFilterBar> {
  static const _primaryFilters = [HealthRecordFilter.all];

  static const _typeFilters = [
    HealthRecordFilter.checkup,
    HealthRecordFilter.illness,
    HealthRecordFilter.injury,
    HealthRecordFilter.vaccination,
    HealthRecordFilter.medication,
    HealthRecordFilter.death,
  ];

  final Map<HealthRecordFilter, GlobalKey> _keys = {
    for (final filter in HealthRecordFilter.values) filter: GlobalKey(),
  };

  void _scrollToSelected(HealthRecordFilter filter) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[filter]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildChip(HealthRecordFilter filter, HealthRecordFilter selected) {
    return Padding(
      key: _keys[filter],
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(filter.label),
        selected: selected == filter,
        visualDensity: VisualDensity.compact,
        onSelected: (_) {
          ref.read(healthRecordFilterProvider.notifier).state = filter;
          _scrollToSelected(filter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(healthRecordFilterProvider);

    return FadeScrollableChipBar(
      children: [
        ..._primaryFilters.map((filter) => _buildChip(filter, selected)),
        const VerticalDivider(width: 24, indent: 8, endIndent: 8),
        ..._typeFilters.map((filter) => _buildChip(filter, selected)),
      ],
    );
  }
}
