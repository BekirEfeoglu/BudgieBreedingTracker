import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/genetics/parent_genotype.dart';

/// Small badge showing the allele state (V/T/S) with tap to toggle.
/// Minimum 32x28px touch target for accessibility (inside FilterChip context).
class AlleleStateBadge extends StatelessWidget {
  final AlleleState state;
  final bool canToggle;
  final bool isDosageBased;
  final VoidCallback onToggle;

  const AlleleStateBadge({
    super.key,
    required this.state,
    required this.canToggle,
    this.isDosageBased = false,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      AlleleState.visual => AppColors.alleleVisualAdaptive(context),
      AlleleState.carrier => AppColors.alleleCarrierAdaptive(context),
      AlleleState.split => AppColors.alleleSplitAdaptive(context),
    };

    // For dosage-based (AD + AID): visual=DF, carrier=SF
    // For others: visual=V, carrier=T, split=S
    final String label;
    if (isDosageBased) {
      label = switch (state) {
        AlleleState.visual => 'genetics.allele_df_short'.tr(),
        AlleleState.carrier => 'genetics.allele_sf_short'.tr(),
        AlleleState.split => 'genetics.allele_sf_short'.tr(),
      };
    } else {
      label = switch (state) {
        AlleleState.visual => 'genetics.allele_visual_short'.tr(),
        AlleleState.carrier => 'genetics.allele_carrier_short'.tr(),
        AlleleState.split => 'genetics.allele_split_short'.tr(),
      };
    }

    return Semantics(
      button: canToggle,
      label: 'genetics.toggle_allele_state'.tr(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canToggle ? onToggle : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: color.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
