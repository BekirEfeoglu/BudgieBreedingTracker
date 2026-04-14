import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/enums/bird_enums.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/bird_display_utils.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../../data/models/bird_model.dart';
import '../../birds/providers/bird_providers.dart';

class MarketplaceBirdPickerSheet extends ConsumerWidget {
  final String userId;

  const MarketplaceBirdPickerSheet({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birdsAsync = ref.watch(birdsStreamProvider(userId));
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.bird,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'marketplace.select_bird'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            birdsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: LoadingState(),
              ),
              error: (_, __) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: EmptyState(
                  icon: const Icon(LucideIcons.alertCircle),
                  title: 'errors.unknown_error'.tr(),
                ),
              ),
              data: (birds) {
                final alivebirds =
                    birds.where((b) => b.isAlive).toList();
                if (alivebirds.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: EmptyState(
                      icon: const Icon(LucideIcons.bird),
                      title: 'marketplace.no_birds_to_link'.tr(),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: alivebirds.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final bird = alivebirds[index];
                      return _BirdPickerTile(
                        bird: bird,
                        onTap: () => Navigator.of(context).pop(bird),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BirdPickerTile extends StatelessWidget {
  final Bird bird;
  final VoidCallback onTap;

  const _BirdPickerTile({required this.bird, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: bird.photoUrl != null && bird.photoUrl!.isNotEmpty
            ? NetworkImage(bird.photoUrl!)
            : null,
        child: bird.photoUrl == null || bird.photoUrl!.isEmpty
            ? Icon(
                LucideIcons.bird,
                size: 20,
                color: theme.colorScheme.primary,
              )
            : null,
      ),
      title: Text(bird.name, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        speciesLabel(bird.species),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: bird.gender == BirdGender.unknown
          ? null
          : AppIcon(
              bird.isMale ? AppIcons.male : AppIcons.female,
              size: 16,
              color: bird.isMale
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondary,
            ),
      onTap: onTap,
    );
  }
}
