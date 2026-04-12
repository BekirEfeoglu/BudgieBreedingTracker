part of 'app_colors.dart';

/// Adaptive color helpers that depend on [BuildContext] brightness.
///
/// Private implementation — accessed via forwarding statics on [AppColors].
abstract class _AdaptiveColors {
  /// Allele state color (adaptive for dark mode).
  static Color alleleStateColor(BuildContext context, String state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (state) {
      'visual' => isDark ? AppColors.alleleVisualDark : AppColors.alleleVisual,
      'carrier' =>
        isDark ? AppColors.alleleCarrierDark : AppColors.alleleCarrier,
      'split' => isDark ? AppColors.alleleSplitDark : AppColors.alleleSplit,
      _ => AppColors.neutral400,
    };
  }

  /// Allele visual color (adaptive).
  static Color alleleVisualAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.alleleVisualDark
        : AppColors.alleleVisual;
  }

  /// Allele carrier color (adaptive).
  static Color alleleCarrierAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.alleleCarrierDark
        : AppColors.alleleCarrier;
  }

  /// Allele split color (adaptive).
  static Color alleleSplitAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColors.alleleSplitDark
        : AppColors.alleleSplit;
  }

  /// Inheritance type color (adaptive for dark mode).
  static Color inheritanceColor(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (type) {
      'autosomalRecessive' => isDark
          ? AppColors.inheritAutosomalRecessiveDark
          : AppColors.inheritAutosomalRecessive,
      'autosomalDominant' => isDark
          ? AppColors.inheritAutosomalDominantDark
          : AppColors.inheritAutosomalDominant,
      'autosomalIncompleteDominant' => isDark
          ? AppColors.inheritAutosomalIncompleteDominantDark
          : AppColors.inheritAutosomalIncompleteDominant,
      'sexLinkedRecessive' => isDark
          ? AppColors.inheritSexLinkedRecessiveDark
          : AppColors.inheritSexLinkedRecessive,
      'sexLinkedCodominant' => isDark
          ? AppColors.inheritSexLinkedCodominantDark
          : AppColors.inheritSexLinkedCodominant,
      _ => AppColors.neutral400,
    };
  }

  /// Whether a color is very light (luminance > 0.85), e.g. albino/white.
  static bool isLightColor(Color color) => color.computeLuminance() > 0.85;

  /// Text color on gold/premium gradient backgrounds.
  static Color premiumOnGold(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : AppColors.premiumBadgeText;
  }

  /// Chart axis / label text color.
  static Color chartText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
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
    return isDark ? AppColors.neutral800 : AppColors.neutral300;
  }

  /// Skeleton loader highlight color.
  static Color skeletonHighlight(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.neutral700 : AppColors.neutral100;
  }

  /// Skeleton loader surface color.
  static Color skeletonSurface(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.neutral800 : Colors.white;
  }

  /// Fullscreen gallery background.
  static Color galleryBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.black : AppColors.neutral900;
  }

  /// Subtitle / secondary text color.
  static Color subtitleText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// AI confidence badge colors (adaptive for dark mode).
  static ({Color background, Color foreground, Color border}) aiConfidenceColors(
    BuildContext context,
    String level,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    return switch (level) {
      'low' => (
        background: theme.colorScheme.errorContainer.withValues(alpha: 0.65),
        foreground: theme.colorScheme.onErrorContainer,
        border: theme.colorScheme.error.withValues(alpha: 0.45),
      ),
      'medium' => (
        background: (isDark ? AppColors.aiConfidenceMediumDark : AppColors.aiConfidenceMedium)
            .withValues(alpha: 0.25),
        foreground: isDark ? AppColors.aiConfidenceMediumDark : const Color(0xFF9A5B00),
        border: (isDark ? AppColors.aiConfidenceMediumDark : AppColors.aiConfidenceMedium)
            .withValues(alpha: 0.55),
      ),
      'high' => (
        background: (isDark ? AppColors.aiConfidenceHighDark : AppColors.aiConfidenceHigh)
            .withValues(alpha: 0.2),
        foreground: isDark ? AppColors.aiConfidenceHighDark : const Color(0xFF166534),
        border: (isDark ? AppColors.aiConfidenceHighDark : AppColors.aiConfidenceHigh)
            .withValues(alpha: 0.55),
      ),
      _ => (
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
        border: theme.colorScheme.outlineVariant,
      ),
    };
  }

  /// Status color helper.
  static Color statusColor(BuildContext context, String status) {
    return switch (status) {
      'alive' || 'active' || 'healthy' || 'completed' => AppColors.success,
      'dead' || 'deceased' || 'cancelled' || 'error' => AppColors.error,
      'sold' || 'pending' || 'warning' => AppColors.warning,
      'sick' || 'injured' => AppColors.injury,
      _ => AppColors.neutral400,
    };
  }
}
