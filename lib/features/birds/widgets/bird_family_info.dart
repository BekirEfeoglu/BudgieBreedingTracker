import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';

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
      error: (error, stack) {
        // Family info is a non-essential section — failing to render
        // shouldn't crash the bird detail screen. But silently hiding the
        // whole subtree was masking real stream failures (the audit-flagged
        // pattern). Log so a recurring failure surfaces in observability;
        // still render `SizedBox.shrink` because we don't have anything
        // useful to put in its place.
        AppLogger.warning('[BirdFamilyInfo] birds stream failed: $error');
        return const SizedBox.shrink();
      },
      data: (allBirds) {
        final familyLinks = _collectFamilyLinks(allBirds);
        final offspring = familyLinks.offspring;
        final siblings = familyLinks.siblings;

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

  _FamilyLinks _collectFamilyLinks(List<Bird> allBirds) {
    final offspring = <Bird>[];
    final siblings = <Bird>[];
    final hasKnownParent = bird.fatherId != null || bird.motherId != null;

    for (final candidate in allBirds) {
      if (candidate.id == bird.id) continue;

      if (candidate.fatherId == bird.id || candidate.motherId == bird.id) {
        offspring.add(candidate);
      }

      if (hasKnownParent) {
        final sameFather =
            bird.fatherId != null && candidate.fatherId == bird.fatherId;
        final sameMother =
            bird.motherId != null && candidate.motherId == bird.motherId;
        if (sameFather || sameMother) {
          siblings.add(candidate);
        }
      }
    }

    return _FamilyLinks(offspring: offspring, siblings: siblings);
  }
}

class _FamilyLinks {
  final List<Bird> offspring;
  final List<Bird> siblings;

  const _FamilyLinks({required this.offspring, required this.siblings});
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
