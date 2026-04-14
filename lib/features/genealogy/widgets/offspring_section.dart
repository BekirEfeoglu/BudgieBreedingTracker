import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/utils/navigation_throttle.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_gender_icon.dart'; // Cross-feature import: genealogy↔birds parent-child relationship
import 'package:budgie_breeding_tracker/features/genealogy/providers/offspring_providers.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';

/// Displays offspring birds and chicks with filter chips.
class OffspringSection extends StatefulWidget {
  final List<Bird> birds;
  final List<Chick> chicks;

  const OffspringSection({
    super.key,
    required this.birds,
    required this.chicks,
  });

  @override
  State<OffspringSection> createState() => _OffspringSectionState();
}

class _OffspringSectionState extends State<OffspringSection> {
  OffspringFilter _filter = OffspringFilter.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = widget.birds.length + widget.chicks.length;

    if (totalCount == 0) {
      return Padding(
        padding: AppSpacing.screenPadding,
        child: Text(
          'genealogy.no_offspring'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final filteredBirds = filterOffspringBirds(widget.birds, _filter);
    final filteredChicks = filterOffspringChicks(widget.chicks, _filter);
    final filteredTotal = filteredBirds.length + filteredChicks.length;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          // Header with count
          Text(
            '${'genealogy.offspring'.tr()} ($totalCount)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: OffspringFilter.values.map((filter) {
                final isSelected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: FilterChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filter = filter),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
          // Filtered results
          if (filteredTotal == 0) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'common.no_results'.tr(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          // Bird offspring
          if (filteredBirds.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'genealogy.offspring_birds'.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...filteredBirds.map(
              (bird) => _OffspringCard(
                name: bird.name,
                ringNumber: bird.ringNumber,
                gender: bird.gender,
                status: bird.status,
                age: bird.age,
                onTap: () {
                  if (!NavigationThrottle.canNavigate()) return;
                  context.push('/birds/${bird.id}');
                },
              ),
            ),
          ],
          // Chick offspring
          if (filteredChicks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'genealogy.offspring_chicks'.tr(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...filteredChicks.map((chick) {
              final name =
                  chick.name ??
                  'chicks.unnamed_chick'.tr(
                    args: [chick.ringNumber ?? chick.id.substring(0, 6)],
                  );
              return _OffspringCard(
                name: name,
                ringNumber: chick.ringNumber,
                gender: chick.gender,
                onTap: () {
                  if (!NavigationThrottle.canNavigate()) return;
                  context.push('/chicks/${chick.id}');
                },
              );
            }),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// A small card for each offspring, showing name, ring, gender, status, age.
class _OffspringCard extends StatelessWidget {
  final String name;
  final String? ringNumber;
  final BirdGender gender;
  final BirdStatus? status;
  final ({int years, int months, int days})? age;
  final VoidCallback onTap;

  const _OffspringCard({
    required this.name,
    this.ringNumber,
    required this.gender,
    this.status,
    this.age,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genderColor = birdGenderColor(gender);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              AppIcon(
                switch (gender) {
                  BirdGender.male => AppIcons.male,
                  BirdGender.female => AppIcons.female,
                  BirdGender.unknown => AppIcons.bird,
                },
                size: 18,
                color: genderColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ringNumber != null)
                      Text(
                        ringNumber!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (age != null)
                Text(
                  'genealogy.age_short'.tr(
                    args: [age!.years.toString(), age!.months.toString()],
                  ),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (status != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color get _statusColor => switch (status) {
    BirdStatus.alive => AppColors.success,
    BirdStatus.dead => AppColors.error,
    BirdStatus.sold => AppColors.warning,
    _ => AppColors.neutral400,
  };
}
