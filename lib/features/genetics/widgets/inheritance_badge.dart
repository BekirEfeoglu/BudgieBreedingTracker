import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mutation_database.dart';

/// Small badge showing inheritance type abbreviation with color coding.
///
/// - AR (blue) - Autosomal Recessive
/// - AD (green) - Autosomal Dominant
/// - AID (orange) - Autosomal Incomplete Dominant
/// - SLR (pink) - Sex-Linked Recessive
/// - SLC (purple) - Sex-Linked Codominant
class InheritanceBadge extends StatelessWidget {
  final InheritanceType type;

  const InheritanceBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        type.badge,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _badgeColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (type) {
      InheritanceType.autosomalRecessive =>
        isDark
            ? AppColors.inheritAutosomalRecessiveDark
            : AppColors.inheritAutosomalRecessive,
      InheritanceType.autosomalDominant =>
        isDark
            ? AppColors.inheritAutosomalDominantDark
            : AppColors.inheritAutosomalDominant,
      InheritanceType.autosomalIncompleteDominant =>
        isDark
            ? AppColors.inheritAutosomalIncompleteDominantDark
            : AppColors.inheritAutosomalIncompleteDominant,
      InheritanceType.sexLinkedRecessive =>
        isDark
            ? AppColors.inheritSexLinkedRecessiveDark
            : AppColors.inheritSexLinkedRecessive,
      InheritanceType.sexLinkedCodominant =>
        isDark
            ? AppColors.inheritSexLinkedCodominantDark
            : AppColors.inheritSexLinkedCodominant,
    };
  }
}
