import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/fade_scrollable_chip_bar.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';

/// Horizontal scrollable filter bar with choice chips for birds.
///
/// Chips are grouped into two sections separated by a [VerticalDivider]:
/// gender (Tümü, Erkek, Dişi) and status (Sağ, Ölü, Satıldı). The selected
/// chip scrolls into view automatically.
class BirdFilterBar extends ConsumerStatefulWidget {
  const BirdFilterBar({super.key});

  @override
  ConsumerState<BirdFilterBar> createState() => _BirdFilterBarState();
}

class _BirdFilterBarState extends ConsumerState<BirdFilterBar> {
  static const _genderFilters = [
    BirdFilter.all,
    BirdFilter.male,
    BirdFilter.female,
  ];

  static const _statusFilters = [
    BirdFilter.alive,
    BirdFilter.dead,
    BirdFilter.sold,
  ];

  final Map<BirdFilter, GlobalKey> _keys = {
    for (final f in BirdFilter.values) f: GlobalKey(),
  };

  void _scrollToSelected(BirdFilter filter) {
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

  Widget _buildChip(BirdFilter filter, BirdFilter selected) {
    return Padding(
      key: _keys[filter],
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(filter.label),
        selected: selected == filter,
        visualDensity: VisualDensity.compact,
        onSelected: (_) {
          ref.read(birdFilterProvider.notifier).state = filter;
          _scrollToSelected(filter);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(birdFilterProvider);

    return FadeScrollableChipBar(
      children: [
        ..._genderFilters.map((f) => _buildChip(f, selected)),
        const VerticalDivider(width: 24, indent: 8, endIndent: 8),
        ..._statusFilters.map((f) => _buildChip(f, selected)),
      ],
    );
  }
}
