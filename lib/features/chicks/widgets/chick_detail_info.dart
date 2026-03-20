import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Info section for the chick detail screen: parents, gender, dates, weights.
class ChickDetailInfo extends ConsumerWidget {
  final Chick chick;

  const ChickDetailInfo({super.key, required this.chick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd.MM.yyyy');
    final parentsAsync = ref.watch(chickParentsProvider(chick.eggId));

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('chicks.info'.tr(), style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          // Parent info
          parentsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (parents) {
              if (parents == null) return const SizedBox.shrink();
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InfoCard(
                          icon: const AppIcon(AppIcons.male),
                          title:
                              parents.maleName ?? 'chicks.unknown_gender'.tr(),
                          subtitle: 'chicks.father'.tr(),
                          onTap: parents.maleId != null
                              ? () => context.push('/birds/${parents.maleId}')
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: InfoCard(
                          icon: const AppIcon(AppIcons.female),
                          title:
                              parents.femaleName ??
                              'chicks.unknown_gender'.tr(),
                          subtitle: 'chicks.mother'.tr(),
                          onTap: parents.femaleId != null
                              ? () => context.push('/birds/${parents.femaleId}')
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              );
            },
          ),
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  icon: _genderWidget,
                  title: _genderLabel,
                  subtitle: 'chicks.gender'.tr(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InfoCard(
                  icon: const AppIcon(AppIcons.egg),
                  title: chick.hatchDate != null
                      ? dateFormat.format(chick.hatchDate!)
                      : 'chicks.unknown_gender'.tr(),
                  subtitle: 'chicks.hatch_date'.tr(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: InfoCard(
                  icon: const AppIcon(AppIcons.weight),
                  title: chick.hatchWeight != null
                      ? '${chick.hatchWeight!.toStringAsFixed(1)} g'
                      : 'chicks.unknown_gender'.tr(),
                  subtitle: 'chicks.birth_weight'.tr(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InfoCard(
                  icon: const Icon(LucideIcons.checkCircle2),
                  title: chick.isWeaned
                      ? dateFormat.format(chick.weanDate!)
                      : 'chicks.not_yet'.tr(),
                  subtitle: 'chicks.weaning'.tr(),
                ),
              ),
            ],
          ),
          if (chick.healthStatus == ChickHealthStatus.deceased &&
              chick.deathDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoCard(
              icon: const Icon(LucideIcons.heartCrack),
              title: dateFormat.format(chick.deathDate!),
              subtitle: 'chicks.death_date'.tr(),
            ),
          ],
          if (chick.birdId != null) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoCard(
              icon: const AppIcon(AppIcons.bird),
              title: 'chicks.converted_to_bird'.tr(),
              subtitle: 'chicks.bird_record'.tr(),
              onTap: () => context.push('/birds/${chick.birdId}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget get _genderWidget => switch (chick.gender) {
    BirdGender.male => const AppIcon(AppIcons.male),
    BirdGender.female => const AppIcon(AppIcons.female),
    BirdGender.unknown => const Icon(LucideIcons.helpCircle),
  };

  String get _genderLabel => switch (chick.gender) {
    BirdGender.male => 'chicks.male'.tr(),
    BirdGender.female => 'chicks.female'.tr(),
    BirdGender.unknown => 'chicks.unknown_gender'.tr(),
  };
}

/// Notes section for the chick detail screen.
class ChickDetailNotes extends StatelessWidget {
  final String notes;

  const ChickDetailNotes({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text(
            'common.notes'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(notes, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
