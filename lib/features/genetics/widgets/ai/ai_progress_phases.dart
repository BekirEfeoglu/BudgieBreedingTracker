import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/local_ai_providers.dart';

class AiProgressPhases extends StatelessWidget {
  const AiProgressPhases({super.key, required this.phase});

  final AiAnalysisPhase phase;

  @override
  Widget build(BuildContext context) {
    final showContent = !phase.isIdle;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: showContent
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PhaseRow(
                    label: 'genetics.ai_phase_preparing'.tr(),
                    status: _stepStatus(AiAnalysisPhase.preparing),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PhaseRow(
                    label: 'genetics.ai_phase_analyzing'.tr(),
                    status: _stepStatus(AiAnalysisPhase.analyzing),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _PhaseRow(
                    label: phase.isError
                        ? 'genetics.ai_phase_error'.tr()
                        : 'genetics.ai_phase_complete'.tr(),
                    status: _stepStatus(AiAnalysisPhase.complete),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  _StepStatus _stepStatus(AiAnalysisPhase step) {
    if (phase.isError && step == AiAnalysisPhase.complete) {
      return _StepStatus.error;
    }
    if (phase.isComplete && step == AiAnalysisPhase.complete) {
      return _StepStatus.done;
    }
    if (phase.index > step.index) return _StepStatus.done;
    if (phase == step) return _StepStatus.active;
    return _StepStatus.pending;
  }
}

enum _StepStatus { pending, active, done, error }

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.label, required this.status});

  final String label;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, color) = switch (status) {
      _StepStatus.done => (
          Icon(LucideIcons.checkCircle2, size: 18, color: theme.colorScheme.primary),
          theme.colorScheme.primary,
        ),
      _StepStatus.active => (
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          theme.colorScheme.primary,
        ),
      _StepStatus.error => (
          Icon(LucideIcons.xCircle, size: 18, color: theme.colorScheme.error),
          theme.colorScheme.error,
        ),
      _StepStatus.pending => (
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
    };

    return Row(
      children: [
        icon,
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: status == _StepStatus.active
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
