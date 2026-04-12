part of 'community_create_post_screen.dart';

class _PostTypeSelector extends StatelessWidget {
  final CommunityPostType selected;
  final bool enabled;
  final ValueChanged<CommunityPostType> onChanged;

  const _PostTypeSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  static const _types = [
    CommunityPostType.general,
    CommunityPostType.photo,
    CommunityPostType.question,
    CommunityPostType.guide,
    CommunityPostType.tip,
    CommunityPostType.showcase,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _types.map((type) {
        final label = switch (type) {
          CommunityPostType.general => 'community.post_type_general'.tr(),
          CommunityPostType.photo => 'community.post_type_photo'.tr(),
          CommunityPostType.question => 'community.post_type_question'.tr(),
          CommunityPostType.guide => 'community.post_type_guide'.tr(),
          CommunityPostType.tip => 'community.post_type_tip'.tr(),
          CommunityPostType.showcase => 'community.post_type_showcase'.tr(),
          _ => 'community.post_type_general'.tr(),
        };

        return ChoiceChip(
          label: Text(label),
          selected: selected == type,
          onSelected: enabled ? (_) => onChanged(type) : null,
        );
      }).toList(),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File file;
  final bool enabled;
  final VoidCallback onRemove;

  const _ImagePreview({
    required this.file,
    required this.enabled,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.file(
            file,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 120,
              height: 120,
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Icon(LucideIcons.imageOff),
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.xs,
          right: AppSpacing.xs,
          child: IconButton.filled(
            onPressed: enabled ? onRemove : null,
            icon: const Icon(LucideIcons.x, size: 14),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.scrim,
              foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
              minimumSize: const Size(28, 28),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
