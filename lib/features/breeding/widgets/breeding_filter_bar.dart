import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/fade_scrollable_chip_bar.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

/// Horizontal scrollable filter bar with choice chips for breeding pairs.
///
/// Chips are grouped into two sections separated by a [VerticalDivider]:
/// active states (Tümü, Aktif, Devam Eden) and ended states (Tamamlandı,
/// İptal Edildi). The selected chip scrolls into view automatically.
class BreedingFilterBar extends ConsumerStatefulWidget {
  const BreedingFilterBar({super.key});

  @override
  ConsumerState<BreedingFilterBar> createState() => _BreedingFilterBarState();
}

class _BreedingFilterBarState extends ConsumerState<BreedingFilterBar> {
  static const _activeFilters = [
    BreedingFilter.all,
    BreedingFilter.active,
    BreedingFilter.ongoing,
  ];

  static const _endedFilters = [
    BreedingFilter.completed,
    BreedingFilter.cancelled,
  ];

  final Map<BreedingFilter, GlobalKey> _keys = {
    for (final f in BreedingFilter.values) f: GlobalKey(),
  };

  void _scrollToSelected(BreedingFilter filter) {
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

  Widget _buildChip(BreedingFilter filter, BreedingFilter selected) {
    return Padding(
      key: _keys[filter],
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(filter.label),
        selected: selected == filter,
        visualDensity: VisualDensity.compact,
        onSelected: (_) {
          ref.read(breedingFilterProvider.notifier).state = filter;
          _scrollToSelected(filter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(breedingFilterProvider);

    return FadeScrollableChipBar(
      children: [
        ..._activeFilters.map((f) => _buildChip(f, selected)),
        const VerticalDivider(width: 24, indent: 8, endIndent: 8),
        ..._endedFilters.map((f) => _buildChip(f, selected)),
      ],
    );
  }
}
