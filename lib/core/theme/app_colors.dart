import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary - Deep Blue
  static const primary = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF1E3A8A);

  // Secondary - Bright Blue
  static const secondary = Color(0xFF3B82F6);
  static const secondaryLight = Color(0xFF60A5FA);

  // Accent - Amber (CTA)
  static const accent = Color(0xFFF59E0B);
  static const accentLight = Color(0xFFFBBF24);

  // Semantic Colors
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF06B6D4);

  // Neutral
  static const neutral50 = Color(0xFFF8FAFC);
  static const neutral100 = Color(0xFFF1F5F9);
  static const neutral200 = Color(0xFFE2E8F0);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral400 = Color(0xFF94A3B8);
  static const neutral500 = Color(0xFF64748B);
  static const neutral600 = Color(0xFF475569);
  static const neutral700 = Color(0xFF334155);
  static const neutral800 = Color(0xFF1E293B);
  static const neutral900 = Color(0xFF0F172A);
  static const neutral950 = Color(0xFF020617);

  // Bird-themed
  static const budgieGreen = Color(0xFF22C55E);
  static const budgieYellow = Color(0xFFFACC15);
  static const budgieBlue = Color(0xFF3B82F6);

  // Gender Colors
  static const genderMale = Color(0xFF3B82F6);
  static const genderFemale = Color(0xFFEC4899);
  static const genderUnknown = Color(0xFF6B7280);

  // Chick Development Stage Colors
  static const stageNewborn = Color(0xFFEC4899);
  static const stageNestling = Color(0xFFF97316);
  static const stageFledgling = Color(0xFF3B82F6);
  static const stageJuvenile = Color(0xFF22C55E);

  // Incubation Stage Colors
  static const stageNew = Color(0xFF3B82F6);
  static const stageOngoing = Color(0xFFF59E0B);
  static const stageNearHatch = Color(0xFFF97316);
  static const stageCompleted = Color(0xFF22C55E);
  static const stageOverdue = Color(0xFFEF4444);

  // Category Colors
  static const medication = Color(0xFF9333EA);   // purple
  static const feature = Color(0xFFF59E0B);       // amber
  static const teal = Color(0xFF14B8A6);           // teal
  static const amber = Color(0xFFF59E0B);          // amber

  // Health / Event Domain Colors
  static const injury = Color(0xFFF97316);          // orange
  static const vaccination = Color(0xFF9C27B0);     // purple
  static const feeding = Color(0xFF795548);          // brown
  static const deepOrange = Color(0xFFFF5722);       // deep orange

  // Premium Badge Text
  static const premiumBadgeText = Color(0xFF3E2723); // dark brown

  // Premium Gold
  static const premiumGold = Color(0xFFFFD700);
  static const premiumGoldDark = Color(0xFFFFA000);

  // Premium Gradients (centralized)
  static const premiumGradient = LinearGradient(
    colors: [premiumGold, premiumGoldDark],
  );
  static const premiumGradientDiagonal = LinearGradient(
    colors: [premiumGold, premiumGoldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Bird Phenotype Colors (chart/genetics domain colors)
  static const phenotypeAlbino = Color(0xFFF1F5F9);
  static const phenotypeLutino = Color(0xFFFFEB3B);
  static const phenotypeCinnamon = Color(0xFF8D6E63);
  static const phenotypeOpaline = Color(0xFF9C27B0);
  static const phenotypeSpangle = Color(0xFF00BCD4);
  static const phenotypeClearwing = Color(0xFF80CBC4);
  static const phenotypePied = Color(0xFFFFA726);
  static const phenotypeDarkFactor = Color(0xFF5D4037);
  static const phenotypeViolet = Color(0xFF7B1FA2);
  static const phenotypeGrey = Color(0xFF78909C);
  static const phenotypeDilute = Color(0xFFAED581);
  static const phenotypeGreywing = Color(0xFF90A4AE);
  static const phenotypeFallow = Color(0xFFBCAAA4);
  static const phenotypeSlate = Color(0xFF546E7A);
  static const phenotypeLacewing = Color(0xFFFFCC80);
  static const phenotypeCrested = Color(0xFF4DB6AC);
  static const phenotypeSaddleback = Color(0xFFA1887F);
  static const phenotypeTexas = Color(0xFF81D4FA);

  // Bird Color Enum Colors (for birdColorToColor utility)
  static const birdGreen = Color(0xFF4CAF50);
  static const birdBlue = Color(0xFF2196F3);
  static const birdYellow = Color(0xFFFFEB3B);
  static const birdWhite = Color(0xFFF5F5F5);
  static const birdGrey = Color(0xFF9E9E9E);
  static const birdViolet = Color(0xFF9C27B0);
  static const birdLutino = Color(0xFFFFD54F);
  static const birdAlbino = Color(0xFFFFFFFF);
  static const birdCinnamon = Color(0xFF8D6E63);
  static const birdOpaline = Color(0xFF80DEEA);
  static const birdSpangle = Color(0xFF7CB342);
  static const birdPied = Color(0xFFBDBDBD);
  static const birdClearwing = Color(0xFFB3E5FC);
  static const birdOther = Color(0xFFFF9800);

  // Chart Bird Color Variants (higher contrast for charts)
  static const chartGreen = Color(0xFF22C55E);
  static const chartBlue = Color(0xFF3B82F6);
  static const chartYellow = Color(0xFFFACC15);
  static const chartWhite = Color(0xFFE2E8F0);
  static const chartGrey = Color(0xFF94A3B8);
  static const chartViolet = Color(0xFF8B5CF6);
  static const chartLutino = Color(0xFFFBBF24);
  static const chartAlbino = Color(0xFFCBD5E1);
  static const chartCinnamon = Color(0xFFA16207);
  static const chartOpaline = Color(0xFF06B6D4);
  static const chartSpangle = Color(0xFF10B981);
  static const chartPied = Color(0xFFF97316);
  static const chartClearwing = Color(0xFF60A5FA);
  static const chartOther = Color(0xFF64748B);

  // Allele State Colors (light theme)
  static const alleleVisual = Color(0xFF4CAF50);
  static const alleleCarrier = Color(0xFFFFA726);
  static const alleleSplit = Color(0xFF7B1FA2);

  // Allele State Colors (dark theme — brighter for dark backgrounds)
  static const alleleVisualDark = Color(0xFF66BB6A);
  static const alleleCarrierDark = Color(0xFFFFB74D);
  static const alleleSplitDark = Color(0xFFAB47BC);

  // Inheritance Type Colors (light theme)
  static const inheritAutosomalRecessive = Color(0xFF1E88E5);
  static const inheritAutosomalDominant = Color(0xFF43A047);
  static const inheritAutosomalIncompleteDominant = Color(0xFFEF6C00);
  static const inheritSexLinkedRecessive = Color(0xFFE91E63);
  static const inheritSexLinkedCodominant = Color(0xFF7B1FA2);

  // Inheritance Type Colors (dark theme — brighter for contrast)
  static const inheritAutosomalRecessiveDark = Color(0xFF42A5F5);
  static const inheritAutosomalDominantDark = Color(0xFF66BB6A);
  static const inheritAutosomalIncompleteDominantDark = Color(0xFFFFA726);
  static const inheritSexLinkedRecessiveDark = Color(0xFFF06292);
  static const inheritSexLinkedCodominantDark = Color(0xFFCE93D8);

  // Genotype Cell Colors — light theme (Punnett Square)
  static const genotypeVisualFemale = Color(0xFFE91E63);
  static const genotypeHomozygousMutant = Color(0xFF1E88E5);
  static const genotypeHeterozygousCarrier = Color(0xFFFFA726);

  // Genotype Cell Colors — dark theme (Punnett Square)
  static const genotypeVisualFemaleDark = Color(0xFFF06292);
  static const genotypeHomozygousMutantDark = Color(0xFF42A5F5);
  static const genotypeHeterozygousCarrierDark = Color(0xFFFFA726);

  // Audit Severity
  static const severityCritical = Color(0xFF7F1D1D);

  // --- Adaptive helpers (context-aware) ---

  /// Allele state color (adaptive for dark mode).
  static Color alleleStateColor(BuildContext context, String state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (state) {
      'visual' => isDark ? alleleVisualDark : alleleVisual,
      'carrier' => isDark ? alleleCarrierDark : alleleCarrier,
      'split' => isDark ? alleleSplitDark : alleleSplit,
      _ => neutral400,
    };
  }

  /// Allele visual color (adaptive).
  static Color alleleVisualAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? alleleVisualDark : alleleVisual;
  }

  /// Allele carrier color (adaptive).
  static Color alleleCarrierAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? alleleCarrierDark : alleleCarrier;
  }

  /// Allele split color (adaptive).
  static Color alleleSplitAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? alleleSplitDark : alleleSplit;
  }

  /// Inheritance type color (adaptive for dark mode).
  static Color inheritanceColor(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (type) {
      'autosomalRecessive' => isDark ? inheritAutosomalRecessiveDark : inheritAutosomalRecessive,
      'autosomalDominant' => isDark ? inheritAutosomalDominantDark : inheritAutosomalDominant,
      'autosomalIncompleteDominant' => isDark ? inheritAutosomalIncompleteDominantDark : inheritAutosomalIncompleteDominant,
      'sexLinkedRecessive' => isDark ? inheritSexLinkedRecessiveDark : inheritSexLinkedRecessive,
      'sexLinkedCodominant' => isDark ? inheritSexLinkedCodominantDark : inheritSexLinkedCodominant,
      _ => neutral400,
    };
  }

  /// Whether a color is very light (luminance > 0.85), e.g. albino/white.
  /// Useful for deciding border visibility on light backgrounds.
  static bool isLightColor(Color color) => color.computeLuminance() > 0.85;

  /// Text color on gold/premium gradient backgrounds.
  static Color premiumOnGold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : premiumBadgeText;
  }

  /// Chart axis / label text color.
  static Color chartText(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white70 : Colors.black87;
  }

  /// Chart title text color.
  static Color chartTitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black87;
  }

  /// Subtle overlay (e.g. scrim, barrier).
  static Color overlay(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
  }

  /// Skeleton loader base color.
  static Color skeletonBase(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutral800 : neutral300;
  }

  /// Skeleton loader highlight color.
  static Color skeletonHighlight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutral700 : neutral100;
  }

  /// Skeleton loader surface color.
  static Color skeletonSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? neutral800 : Colors.white;
  }

  /// Fullscreen gallery background.
  static Color galleryBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.black : neutral900;
  }

  /// Subtitle / secondary text color.
  static Color subtitleText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// Status color helper.
  static Color statusColor(BuildContext context, String status) {
    return switch (status) {
      'alive' || 'active' || 'healthy' || 'completed' => success,
      'dead' || 'deceased' || 'cancelled' || 'error' => error,
      'sold' || 'pending' || 'warning' => warning,
      'sick' || 'injured' => injury,
      _ => neutral400,
    };
  }
}
