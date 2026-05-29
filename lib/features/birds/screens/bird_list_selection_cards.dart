part of 'bird_list_screen.dart';

List<PopupMenuEntry<String>> _buildSelectionActionItems() => [
  PopupMenuItem(value: 'dead', child: Text('birds.mark_dead'.tr())),
  PopupMenuItem(value: 'sold', child: Text('birds.mark_sold'.tr())),
  PopupMenuItem(value: 'gifted', child: Text('birds.mark_gifted'.tr())),
];

/// Wraps [BirdGridCard] with selection mode visuals.
class _SelectableBirdGridCard extends StatelessWidget {
  final Bird bird;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SelectableBirdGridCard({
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
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    )
                  : null,
              child: BirdGridCard(bird: bird, onTap: onTap),
            ),
          ),
          if (isSelectionMode)
            Positioned(
              left: AppSpacing.xs,
              top: AppSpacing.xs,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Semantics(
                  selected: isSelected,
                  label: bird.name,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
        ],
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
                padding: const EdgeInsetsDirectional.only(start: AppSpacing.sm),
                child: Semantics(
                  selected: isSelected,
                  label: bird.name,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                    visualDensity: VisualDensity.compact,
                  ),
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
