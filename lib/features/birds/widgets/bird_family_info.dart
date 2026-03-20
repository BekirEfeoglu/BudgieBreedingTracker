import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';

/// Shows offspring and siblings for a given bird in the detail screen.
class BirdFamilyInfo extends ConsumerWidget {
  final Bird bird;

  const BirdFamilyInfo({super.key, required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final birdsAsync = ref.watch(birdsStreamProvider(userId));

    return birdsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allBirds) {
        final offspring = allBirds
            .where((b) => b.fatherId == bird.id || b.motherId == bird.id)
            .toList();

        final siblings = _findSiblings(allBirds);

        if (offspring.isEmpty && siblings.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'birds.family_info'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (offspring.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _FamilySubSection(
                  title: 'birds.offspring'.tr(),
                  icon: const AppIcon(AppIcons.chick, size: 16),
                  birds: offspring,
                ),
              ],
              if (siblings.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _FamilySubSection(
                  title: 'birds.siblings'.tr(),
                  icon: const AppIcon(AppIcons.users, size: 16),
                  birds: siblings,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Bird> _findSiblings(List<Bird> allBirds) {
    if (bird.fatherId == null && bird.motherId == null) return [];

    return allBirds.where((b) {
      if (b.id == bird.id) return false;
      // Share at least one parent
      final sameFather = bird.fatherId != null && b.fatherId == bird.fatherId;
      final sameMother = bird.motherId != null && b.motherId == bird.motherId;
      return sameFather || sameMother;
    }).toList();
  }
}

class _FamilySubSection extends StatelessWidget {
  final String title;
  final Widget icon;
  final List<Bird> birds;

  const _FamilySubSection({
    required this.title,
    required this.icon,
    required this.birds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTheme(
              data: IconThemeData(size: 16, color: theme.colorScheme.primary),
              child: icon,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text('$title (${birds.length})', style: theme.textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: birds.map((b) => _BirdChip(bird: b)).toList(),
        ),
      ],
    );
  }
}

class _BirdChip extends StatelessWidget {
  final Bird bird;

  const _BirdChip({required this.bird});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: switch (bird.gender) {
        BirdGender.male => const AppIcon(AppIcons.male, size: 16),
        BirdGender.female => const AppIcon(AppIcons.female, size: 16),
        BirdGender.unknown => const Icon(LucideIcons.helpCircle, size: 16),
      },
      label: Text(
        bird.ringNumber != null
            ? '${bird.name} (${bird.ringNumber})'
            : bird.name,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onPressed: () => context.push('/birds/${bird.id}'),
    );
  }
}
