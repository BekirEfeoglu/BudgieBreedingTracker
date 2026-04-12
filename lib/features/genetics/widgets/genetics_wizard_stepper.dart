import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';

/// Horizontal step indicator with 3 steps for genetics wizard.
class GeneticsWizardStepper extends StatelessWidget {
  final int currentStep;
  final bool canAdvance;
  final ValueChanged<int> onStepTap;

  const GeneticsWizardStepper({
    super.key,
    required this.currentStep,
    required this.canAdvance,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget connector(int afterStep) => Expanded(
      child: Container(
        height: 2,
        color: currentStep > afterStep
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _StepDot(
            step: 0,
            label: 'genetics.step_parents'.tr(),
            isActive: currentStep == 0,
            isCompleted: currentStep > 0,
            onTap: () => onStepTap(0),
          ),
          connector(0),
          _StepDot(
            step: 1,
            label: 'genetics.step_genotype'.tr(),
            isActive: currentStep == 1,
            isCompleted: currentStep > 1,
            onTap: canAdvance ? () => onStepTap(1) : null,
          ),
          connector(1),
          _StepDot(
            step: 2,
            label: 'genetics.step_results'.tr(),
            isActive: currentStep == 2,
            isCompleted: false,
            onTap: canAdvance ? () => onStepTap(2) : null,
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _StepDot({
    required this.step,
    required this.label,
    required this.isActive,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = isActive || isCompleted
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$label, ${step + 1}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSpacing.touchTargetMin,
            minHeight: AppSpacing.touchTargetMin,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? theme.colorScheme.primary
                      : isCompleted
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          LucideIcons.check,
                          size: 14,
                          color: theme.colorScheme.primary,
                        )
                      : Text(
                          '${step + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isActive
                                ? theme.colorScheme.onPrimary
                                : color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive || isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
