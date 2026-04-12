import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

class AiQuickTags extends StatelessWidget {
  const AiQuickTags({
    super.key,
    required this.selectedTags,
    required this.onTagToggled,
  });

  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;

  static const defaultTags = [
    'genetics.ai_tag_blue_cere',
    'genetics.ai_tag_brown_cere',
    'genetics.ai_tag_young_bird',
    'genetics.ai_tag_head_bars',
    'genetics.ai_tag_ino_mutation',
    'genetics.ai_tag_active_behavior',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: defaultTags.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return FilterChip(
          label: Text(tag.tr()),
          selected: isSelected,
          onSelected: (_) => onTagToggled(tag),
          visualDensity: VisualDensity.compact,
        );
      }).toList(growable: false),
    );
  }
}
