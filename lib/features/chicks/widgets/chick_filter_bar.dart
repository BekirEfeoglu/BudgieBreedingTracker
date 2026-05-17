import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/fade_scrollable_chip_bar.dart';
import 'package:budgie_breeding_tracker/shared/providers/chicks.dart';

/// Horizontal scrollable filter bar with choice chips for chicks.
///
/// Chips are grouped into two sections separated by a [VerticalDivider]:
/// health status (Tümü, Sağlıklı, Hasta, Vefat) and development stage
/// (Yeme Düşmemiş, Yeni Doğan, Yuva, Tüylenen, Genç). The selected chip
/// scrolls into view automatically.
class ChickFilterBar extends ConsumerStatefulWidget {
  const ChickFilterBar({super.key});

  @override
  ConsumerState<ChickFilterBar> createState() => _ChickFilterBarState();
}

class _ChickFilterBarState extends ConsumerState<ChickFilterBar> {
  static const _healthFilters = [
    ChickFilter.all,
    ChickFilter.healthy,
    ChickFilter.sick,
    ChickFilter.deceased,
  ];

  static const _stageFilters = [
    ChickFilter.unweaned,
    ChickFilter.newborn,
    ChickFilter.nestling,
    ChickFilter.fledgling,
    ChickFilter.juvenile,
  ];

  final Map<ChickFilter, GlobalKey> _keys = {
    for (final f in ChickFilter.values) f: GlobalKey(),
  };

  void _scrollToSelected(ChickFilter filter) {
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

  Widget _buildChip(ChickFilter filter, ChickFilter selected) {
    return Padding(
      key: _keys[filter],
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(filter.label),
        selected: selected == filter,
        visualDensity: VisualDensity.compact,
        onSelected: (_) {
          ref.read(chickFilterProvider.notifier).state = filter;
          _scrollToSelected(filter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(chickFilterProvider);

    return FadeScrollableChipBar(
      children: [
        ..._healthFilters.map((f) => _buildChip(f, selected)),
        const VerticalDivider(width: 24, indent: 8, endIndent: 8),
        ..._stageFilters.map((f) => _buildChip(f, selected)),
      ],
    );
  }
}
