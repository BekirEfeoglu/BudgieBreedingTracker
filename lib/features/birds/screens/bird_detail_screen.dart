import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/utils/app_haptics.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/data/models/bird_model.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_detail_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/birds/providers/bird_form_providers.dart';
import 'package:budgie_breeding_tracker/features/genealogy/providers/genealogy_providers.dart'; // Cross-feature import: birds↔genealogy parent-child relationship
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_header.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_info.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_parents.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_photos.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_health.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_detail_notes.dart';
import 'package:budgie_breeding_tracker/features/birds/widgets/bird_family_info.dart';

/// Detail screen for a single bird.
class BirdDetailScreen extends ConsumerWidget {
  final String birdId;

  const BirdDetailScreen({super.key, required this.birdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final birdAsync = ref.watch(birdByIdProvider(birdId));

    return birdAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('common.loading'.tr())),
        body: const LoadingState(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text('common.error'.tr())),
        body: ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(birdByIdProvider(birdId)),
        ),
      ),
      data: (bird) {
        if (bird == null) {
          return Scaffold(
            appBar: AppBar(title: Text('common.not_found'.tr())),
            body: ErrorState(message: 'birds.not_found'.tr()),
          );
        }
        return _DetailContent(bird: bird);
      },
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final Bird bird;

  const _DetailContent({required this.bird});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(birdFormStateProvider);

    ref.listen<BirdFormState>(birdFormStateProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(birdFormStateProvider.notifier).reset();
        ActionFeedbackService.show('common.saved_successfully'.tr());
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(bird.name),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.sparkles, size: 20),
            tooltip: 'more.ai_predictions'.tr(),
            onPressed: () => context.push(
              '${AppRoutes.aiPredictions}?tab=mutation&birdId=${bird.id}',
            ),
          ),
          IconButton(
            icon: const AppIcon(AppIcons.edit),
            tooltip: 'common.edit'.tr(),
            onPressed: () => context.push('/birds/form?editId=${bird.id}'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pedigree',
                child: Text('genealogy.view_pedigree'.tr()),
              ),
              if (bird.status == BirdStatus.alive) ...[
                PopupMenuItem(
                  value: 'dead',
                  child: Text('birds.mark_dead'.tr()),
                ),
                PopupMenuItem(value: 'sold', child: Text('birds.sold'.tr())),
              ],
              PopupMenuItem(value: 'delete', child: Text('common.delete'.tr())),
            ],
          ),
        ],
      ),
      body: formState.isLoading
          ? const LoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BirdDetailHeader(bird: bird),
                      BirdDetailPhotos(bird: bird),
                      const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                      BirdDetailInfo(bird: bird),
                      const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                      BirdDetailParents(bird: bird),
                      BirdFamilyInfo(bird: bird),
                      const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                      BirdDetailHealth(birdId: bird.id),
                      if (bird.notes != null && bird.notes!.isNotEmpty) ...[
                        const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
                        BirdDetailNotes(notes: bird.notes!),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final notifier = ref.read(birdFormStateProvider.notifier);

    switch (action) {
      case 'pedigree':
        ref.read(selectedEntityForTreeProvider.notifier).state = (
          id: bird.id,
          isChick: false,
        );
        if (context.mounted) context.push('/genealogy');
      case 'dead':
        final confirmed = await showConfirmDialog(
          context,
          title: 'common.death'.tr(),
          message: 'birds.mark_dead_confirm'.tr(namedArgs: {'name': bird.name}),
          confirmLabel: 'common.yes'.tr(),
          isDestructive: true,
        );
        if (confirmed == true) {
          AppHaptics.heavyImpact();
          await notifier.markAsDead(bird.id);
          if (!context.mounted) return;
        }
      case 'sold':
        final confirmed = await showConfirmDialog(
          context,
          title: 'common.sale'.tr(),
          message: 'birds.mark_sold_confirm'.tr(namedArgs: {'name': bird.name}),
          confirmLabel: 'common.yes'.tr(),
        );
        if (confirmed == true) {
          AppHaptics.mediumImpact();
          await notifier.markAsSold(bird.id);
          if (!context.mounted) return;
        }
      case 'delete':
        final confirmed = await showConfirmDialog(
          context,
          title: 'common.delete'.tr(),
          message: 'birds.delete_confirm'.tr(namedArgs: {'name': bird.name}),
          confirmLabel: 'common.delete'.tr(),
          isDestructive: true,
        );
        if (confirmed == true) {
          AppHaptics.heavyImpact();
          await notifier.deleteBird(bird.id);
          if (context.mounted) {
            ActionFeedbackService.show('birds.bird_deleted'.tr());
            context.pop();
          }
        }
    }
  }
}
