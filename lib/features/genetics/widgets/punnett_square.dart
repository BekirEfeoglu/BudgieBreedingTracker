import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/mendelian_calculator.dart';

/// Table widget showing a Punnett square for selected alleles.
///
/// Uses [PunnettSquareData] from [MendelianCalculator] for structured display
/// with color-coded cells and tooltips.
class PunnettSquareWidget extends StatelessWidget {
  final PunnettSquareData data;

  const PunnettSquareWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sexLinkedColor = isDark
        ? AppColors.inheritSexLinkedRecessiveDark
        : AppColors.inheritSexLinkedRecessive;
    final tableBorderColor = isDark
        ? AppColors.neutral600
        : AppColors.neutral300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(
              AppIcons.punnett,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'genetics.punnett_square'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _localizeLocusName(data.mutationName),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (data.isSexLinked) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + 2,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: sexLinkedColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'genetics.sex_linked'.tr(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: sexLinkedColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(90),
            border: TableBorder.all(color: tableBorderColor, width: 1),
            children: [
              _buildHeaderRow(theme),
              ...data.cells.asMap().entries.map(
                (entry) => _buildDataRow(theme, entry.key, entry.value),
              ),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _buildHeaderRow(ThemeData theme) {
    return TableRow(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      ),
      children: [
        _buildCell(
          theme,
          data.isSexLinked ? '♂ \\ ♀' : '♂ \\ ♀',
          isHeader: true,
        ),
        ...data.motherAlleles.map(
          (a) => _buildCell(theme, '♀ $a', isHeader: true),
        ),
      ],
    );
  }

  TableRow _buildDataRow(ThemeData theme, int rowIndex, List<String> rowData) {
    final fatherAllele = rowIndex < data.fatherAlleles.length
        ? data.fatherAlleles[rowIndex]
        : '?';

    return TableRow(
      children: [
        _buildCell(theme, '♂ $fatherAllele', isHeader: true),
        ...rowData.map((cell) => _buildDataCell(theme, cell)),
      ],
    );
  }

  Widget _buildCell(ThemeData theme, String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: isHeader
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
          : null,
      child: Center(
        child: Text(
          text,
          style: isHeader
              ? theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                )
              : theme.textTheme.labelSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDataCell(ThemeData theme, String genotype) {
    final isDark = theme.brightness == Brightness.dark;
    final cellColor = _genotypeColor(genotype, isDark);

    return Tooltip(
      message: _genotypeDescription(genotype),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        color: cellColor?.withValues(alpha: isDark ? 0.2 : 0.1),
        child: Center(
          child: Text(
            genotype,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: cellColor != null ? FontWeight.w600 : null,
              color: cellColor ?? theme.textTheme.labelSmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  /// Color-codes cells based on genotype content (dark mode aware).
  Color? _genotypeColor(String genotype, bool isDark) {
    if (genotype.contains('W')) {
      // Sex-linked: contains W chromosome
      if (!genotype.contains('+')) {
        return isDark
            ? AppColors.genotypeVisualFemaleDark
            : AppColors.genotypeVisualFemale;
      }
      return null; // Normal female
    }
    // Two mutant alleles → visual expression
    final parts = genotype.split('/');
    if (parts.length == 2 &&
        !parts[0].contains('+') &&
        !parts[1].contains('+')) {
      return isDark
          ? AppColors.genotypeHomozygousMutantDark
          : AppColors.genotypeHomozygousMutant;
    }
    // One mutant allele → carrier
    if (parts.length == 2 &&
        (parts[0].contains('+') != parts[1].contains('+'))) {
      return isDark
          ? AppColors.genotypeHeterozygousCarrierDark
          : AppColors.genotypeHeterozygousCarrier;
    }
    return null;
  }

  String _genotypeDescription(String genotype) {
    final parts = genotype.split('/');
    if (parts.length != 2) return genotype;

    if (genotype.contains('W')) {
      if (!parts[0].contains('+')) {
        return 'genetics.visual_female'.tr();
      }
      return 'genetics.normal_female'.tr();
    }

    if (!parts[0].contains('+') && !parts[1].contains('+')) {
      return 'genetics.homozygous_visual'.tr();
    }
    if (parts[0].contains('+') && parts[1].contains('+')) {
      return 'genetics.homozygous_normal'.tr();
    }
    return 'genetics.heterozygous_carrier'.tr();
  }
}

/// Maps internal locus IDs / English display names to localized strings.
String _localizeLocusName(String name) {
  return switch (name) {
    'Blue Series' => 'genetics.locus_blue_series'.tr(),
    'Dilution' => 'genetics.locus_dilution'.tr(),
    'Crested' => 'genetics.locus_crested'.tr(),
    'Ino Locus' => 'genetics.locus_ino'.tr(),
    'blue_series' => 'genetics.locus_blue_series'.tr(),
    'dilution' => 'genetics.locus_dilution'.tr(),
    'crested' => 'genetics.locus_crested'.tr(),
    'ino_locus' => 'genetics.locus_ino'.tr(),
    _ => name,
  };
}
