import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';

/// Parents section for bird detail screen showing father and mother cards.
class BirdDetailParents extends ConsumerWidget {
  final Bird bird;

  const BirdDetailParents({super.key, required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bird.fatherId == null && bird.motherId == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('birds.parents'.tr(), style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (bird.fatherId != null)
                Expanded(
                  child: _ParentCard(
                    parentId: bird.fatherId!,
                    label: 'birds.father'.tr(),
                    icon: const AppIcon(AppIcons.male),
                  ),
                ),
              if (bird.fatherId != null && bird.motherId != null)
                const SizedBox(width: AppSpacing.sm),
              if (bird.motherId != null)
                Expanded(
                  child: _ParentCard(
                    parentId: bird.motherId!,
                    label: 'birds.mother'.tr(),
                    icon: const AppIcon(AppIcons.female),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParentCard extends ConsumerWidget {
  final String parentId;
  final String label;
  final Widget icon;

  const _ParentCard({
    required this.parentId,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parentAsync = ref.watch(birdByIdProvider(parentId));

    return parentAsync.when(
      loading: () =>
          InfoCard(icon: icon, title: 'common.loading'.tr(), subtitle: label),
      error: (_, __) =>
          InfoCard(icon: icon, title: 'birds.unknown'.tr(), subtitle: label),
      data: (parent) => InfoCard(
        icon: icon,
        title: parent?.name ?? 'birds.unknown'.tr(),
        subtitle: label,
        onTap: parent != null
            ? () => context.push('/birds/${parent.id}')
            : null,
      ),
    );
  }
}
