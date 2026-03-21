import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/genetics/screens/genetics_color_audit_samples.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/bird_color_simulation.dart';

class GeneticsColorAuditScreen extends StatelessWidget {
  const GeneticsColorAuditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(title: Text('genetics.color_audit_title'.tr())),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          children: const [
            GeneticsPrimaryColorAuditBoard(),
            SizedBox(height: AppSpacing.lg),
            GeneticsAdvancedColorAuditBoard(),
          ],
        ),
      ),
    );
  }
}

class GeneticsPrimaryColorAuditBoard extends StatelessWidget {
  const GeneticsPrimaryColorAuditBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return GeneticsColorAuditBoard(
      title: 'genetics.color_audit_primary_title'.tr(),
      subtitle: 'genetics.color_audit_primary_subtitle'.tr(),
      samples: primaryAuditSamples,
      minTileWidth: 88,
      birdSize: 64,
    );
  }
}

class GeneticsAdvancedColorAuditBoard extends StatelessWidget {
  const GeneticsAdvancedColorAuditBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return GeneticsColorAuditBoard(
      title: 'genetics.color_audit_advanced_title'.tr(),
      subtitle: 'genetics.color_audit_advanced_subtitle'.tr(),
      samples: advancedAuditSamples,
      minTileWidth: 106,
      birdSize: 80,
    );
  }
}

class GeneticsColorAuditBoard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AuditSample> samples;
  final double minTileWidth;
  final double birdSize;

  const GeneticsColorAuditBoard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.samples,
    required this.minTileWidth,
    required this.birdSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.xxl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = (constraints.maxWidth / minTileWidth)
                    .floor()
                    .clamp(2, 5);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: samples.length,
                  itemBuilder: (context, index) {
                    final sample = samples[index];
                    return _AuditSampleCard(
                      sample: sample,
                      birdSize: birdSize,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditSampleCard extends StatelessWidget {
  final AuditSample sample;
  final double birdSize;

  const _AuditSampleCard({required this.sample, required this.birdSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BirdColorSimulation(
              visualMutations: sample.visualMutations,
              phenotype: sample.phenotype,
              height: birdSize,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              sample.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                height: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              sample.note,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 9,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
