import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_colors.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/utils/navigation_throttle.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';

/// List-based ancestor view, organized by generation via ExpansionTile.
class AncestorListView extends StatelessWidget {
  final Bird rootBird;
  final Map<String, Bird> ancestors;
  final int maxDepth;
  final Set<String> commonAncestorIds;
  final bool isRootChick;

  const AncestorListView({
    super.key,
    required this.rootBird,
    required this.ancestors,
    this.maxDepth = 5,
    this.commonAncestorIds = const {},
    this.isRootChick = false,
  });

  @override
  Widget build(BuildContext context) {
    // Build generations map: depth → list of birds
    final generations = <int, List<Bird>>{};
    _collectByGeneration(rootBird, 0, generations);

    final sortedGens = generations.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: sortedGens.map((gen) {
          final birds = generations[gen]!;
          final label = _generationLabel(gen);
          return ExpansionTile(
            initiallyExpanded: gen <= 1,
            title: Text(
              '$label (${birds.length})',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            children: birds.map((bird) {
              final isCommon = commonAncestorIds.contains(bird.id);
              final isChickEntity = isRootChick && bird.id == rootBird.id;
              return _AncestorListTile(
                bird: bird,
                isCommonAncestor: isCommon,
                isChick: isChickEntity,
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  void _collectByGeneration(
    Bird? bird,
    int depth,
    Map<int, List<Bird>> generations,
  ) {
    if (bird == null || depth > maxDepth) return;
    generations.putIfAbsent(depth, () => []).add(bird);

    final father = bird.fatherId != null ? ancestors[bird.fatherId] : null;
    final mother = bird.motherId != null ? ancestors[bird.motherId] : null;
    _collectByGeneration(father, depth + 1, generations);
    _collectByGeneration(mother, depth + 1, generations);
  }

  String _generationLabel(int gen) => switch (gen) {
    0 => 'genealogy.root'.tr(),
    1 => 'genealogy.parents_gen'.tr(),
    2 => 'genealogy.grandparents'.tr(),
    3 => 'genealogy.great_grandparents'.tr(),
    _ => 'genealogy.generation'.tr(args: [gen.toString()]),
  };
}

class _AncestorListTile extends StatelessWidget {
  final Bird bird;
  final bool isCommonAncestor;
  final bool isChick;

  const _AncestorListTile({
    required this.bird,
    this.isCommonAncestor = false,
    this.isChick = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genderColor = switch (bird.gender) {
      BirdGender.male => AppColors.genderMale,
      BirdGender.female => AppColors.genderFemale,
      BirdGender.unknown => AppColors.neutral400,
    };

    return ListTile(
      dense: true,
      leading: AppIcon(
        switch (bird.gender) {
          BirdGender.male => AppIcons.male,
          BirdGender.female => AppIcons.female,
          BirdGender.unknown => AppIcons.bird,
        },
        size: 18,
        color: genderColor,
      ),
      title: Text(
        bird.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: isCommonAncestor ? AppColors.warning : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: bird.ringNumber != null
          ? Text(bird.ringNumber!, style: theme.textTheme.labelSmall)
          : null,
      trailing: isCommonAncestor
          ? Tooltip(
              message: 'genealogy.common_ancestor_hint'.tr(),
              child: const AppIcon(
                AppIcons.warning,
                size: 18,
                color: AppColors.warning,
              ),
            )
          : null,
      onTap: () {
        if (!NavigationThrottle.canNavigate()) return;
        final path = isChick ? '/chicks/${bird.id}' : '/birds/${bird.id}';
        context.push(path);
      },
    );
  }
}
