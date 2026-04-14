import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/providers/health_record_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_card.dart'; // Cross-feature import: bird detail shows health records

/// Health history section for bird detail screen showing recent records.
class BirdDetailHealth extends ConsumerWidget {
  final String birdId;

  const BirdDetailHealth({super.key, required this.birdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(healthRecordsByBirdProvider(birdId));

    return recordsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text(
              'health_records.load_error'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () =>
                  ref.invalidate(healthRecordsByBirdProvider(birdId)),
              icon: const AppIcon(AppIcons.sync, size: 18),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
      data: (records) {
        if (records.isEmpty) return const SizedBox.shrink();

        final sorted = List.of(records)
          ..sort((a, b) => b.date.compareTo(a.date));
        final display = sorted.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'health_records.health_history'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (records.length > 3)
                    TextButton(
                      onPressed: () => context.push('/health-records'),
                      child: Text('health_records.view_all_records'.tr()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ...display.map((r) => HealthRecordCard(record: r)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/health-records/form?birdId=$birdId'),
                icon: const AppIcon(AppIcons.add, size: 18),
                label: Text('health_records.add_record'.tr()),
              ),
            ),
          ],
        );
      },
    );
  }
}
