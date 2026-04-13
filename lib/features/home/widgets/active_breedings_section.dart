import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/breeding_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/status_badge.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_detail_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/section_header.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Section showing active breeding pairs on the dashboard.
class ActiveBreedingsSection extends ConsumerWidget {
  final List<BreedingPair> pairs;

  const ActiveBreedingsSection({super.key, required this.pairs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'home.active_breedings_section'.tr(),
            icon: const AppIcon(AppIcons.breedingActive),
            onViewAll: () => context.go(AppRoutes.breeding),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (pairs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'home.no_active_breedings'.tr(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...pairs.map((pair) => _BreedingPairTile(pair: pair)),
        ],
      ),
    );
  }
}

class _BreedingPairTile extends ConsumerWidget {
  final BreedingPair pair;

  const _BreedingPairTile({required this.pair});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maleAsync = pair.maleId != null
        ? ref.watch(birdByIdProvider(pair.maleId!))
        : null;
    final femaleAsync = pair.femaleId != null
        ? ref.watch(birdByIdProvider(pair.femaleId!))
        : null;

    final maleName = maleAsync?.value?.name ?? 'common.unknown'.tr();
    final femaleName = femaleAsync?.value?.name ?? 'common.unknown'.tr();

    final dateText = pair.pairingDate != null
        ? ref.watch(dateFormatProvider).formatter().format(pair.pairingDate!)
        : '';
    final daysActive = pair.pairingDate != null
        ? DateTime.now().difference(pair.pairingDate!).inDays
        : null;
    final dateDisplay = daysActive != null && dateText.isNotEmpty
        ? '$dateText · ${'home.days_active'.tr(args: [daysActive.toString()])}'
        : dateText;

    final accentColor = _statusColor(pair.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/breeding/${pair.id}'),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.radiusLg),
                    bottomLeft: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$maleName \u2642 - $femaleName \u2640',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (dateDisplay.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                dateDisplay,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      StatusBadge(
                        label: _statusLabel(pair.status),
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(BreedingStatus status) => switch (status) {
    BreedingStatus.active => 'breeding.active'.tr(),
    BreedingStatus.ongoing => 'breeding.in_progress'.tr(),
    BreedingStatus.completed => 'breeding.completed'.tr(),
    BreedingStatus.cancelled => 'breeding.cancelled'.tr(),
    BreedingStatus.unknown => 'common.unknown'.tr(),
  };

  Color _statusColor(BreedingStatus status) => switch (status) {
    BreedingStatus.active => AppColors.success,
    BreedingStatus.ongoing => AppColors.warning,
    BreedingStatus.completed => AppColors.primaryLight,
    BreedingStatus.cancelled || BreedingStatus.unknown => AppColors.neutral400,
  };
}
