import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/bird_display_utils.dart';

class SpeciesBreakdownCard extends StatelessWidget {
  const SpeciesBreakdownCard({super.key, required this.data});

  final Map<Species, int> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = data.values.fold<int>(0, (sum, value) => sum + value);

    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: data.entries.map((entry) {
        final ratio = entry.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  speciesIconWidget(entry.key, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      speciesLabel(entry.key),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${entry.value}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
