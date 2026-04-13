import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/enums/chick_enums.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/data/models/chick_model.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_form_providers.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_detail_header.dart';
import 'package:budgie_breeding_tracker/features/chicks/widgets/chick_detail_info.dart';

/// Returns a display name for a chick (shared utility).
String chickDisplayName(Chick chick) {
  if (chick.name != null && chick.name!.isNotEmpty) return chick.name!;
  return 'chicks.unnamed_chick'.tr(
    args: [chick.ringNumber ?? chick.id.substring(0, 6)],
  );
}

/// Detail screen for a single chick.
class ChickDetailScreen extends ConsumerWidget {
  final String chickId;

  const ChickDetailScreen({super.key, required this.chickId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chickAsync = ref.watch(chickByIdProvider(chickId));

    return chickAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('common.loading'.tr())),
        body: const LoadingState(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text('common.error'.tr())),
        body: ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(chickByIdProvider(chickId)),
        ),
      ),
      data: (chick) {
        if (chick == null) {
          return Scaffold(
            appBar: AppBar(title: Text('common.not_found'.tr())),
            body: ErrorState(message: 'chicks.not_found'.tr()),
          );
        }
        return _DetailContent(chick: chick);
      },
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final Chick chick;

  const _DetailContent({required this.chick});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(chickFormStateProvider);

    ref.listen<ChickFormState>(chickFormStateProvider, (_, state) {
      if (state.isSuccess) {
        ref.read(chickFormStateProvider.notifier).reset();
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
        title: Text(chickDisplayName(chick)),
        actions: [
          IconButton(
            icon: const AppIcon(AppIcons.edit),
            tooltip: 'common.edit'.tr(),
            onPressed: () => context.push('/chicks/form?editId=${chick.id}'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              if (!chick.isWeaned &&
                  chick.healthStatus != ChickHealthStatus.deceased)
                PopupMenuItem(value: 'wean', child: Text('chicks.wean'.tr())),
              if (chick.birdId == null &&
                  chick.healthStatus != ChickHealthStatus.deceased)
                PopupMenuItem(
                  value: 'promote',
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(AppIcons.promote, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'chicks.move_to_birds'.tr(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (chick.healthStatus != ChickHealthStatus.deceased)
                PopupMenuItem(
                  value: 'deceased',
                  child: Text('chicks.mark_dead'.tr()),
                ),
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
                      ChickDetailHeader(chick: chick),
                      const Divider(
                        height: 1,
                        indent: AppSpacing.lg,
                        endIndent: AppSpacing.lg,
                      ),
                      ChickDetailInfo(chick: chick),
                      if (chick.notes != null && chick.notes!.isNotEmpty) ...[
                        const Divider(
                          height: 1,
                          indent: AppSpacing.lg,
                          endIndent: AppSpacing.lg,
                        ),
                        ChickDetailNotes(notes: chick.notes!),
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
    final notifier = ref.read(chickFormStateProvider.notifier);

    switch (action) {
      case 'wean':
        final confirmed = await showConfirmDialog(
          context,
          title: 'chicks.wean'.tr(),
          message: 'chicks.wean_confirm'.tr(),
          confirmLabel: 'chicks.wean'.tr(),
        );
        if (confirmed == true) {
          await notifier.markAsWeaned(chick.id);
          if (context.mounted) {
            ActionFeedbackService.show('chicks.wean_success'.tr());
          }
        }
      case 'promote':
        final confirmed = await showConfirmDialog(
          context,
          title: 'chicks.move_to_birds'.tr(),
          message: 'chicks.move_to_birds_confirm'.tr(),
          confirmLabel: 'chicks.move_to_birds'.tr(),
        );
        if (confirmed == true) {
          await notifier.promoteToBird(chick);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('chicks.moved_to_birds'.tr()),
                action: SnackBarAction(
                  label: 'chicks.go_to_birds'.tr(),
                  onPressed: () => context.push('/birds'),
                ),
              ),
            );
          }
        }
      case 'deceased':
        final confirmed = await showConfirmDialog(
          context,
          title: 'chicks.mark_dead'.tr(),
          message: 'chicks.mark_dead_confirm'.tr(),
          confirmLabel: 'common.yes'.tr(),
          isDestructive: true,
        );
        if (confirmed == true) {
          await notifier.markAsDeceased(chick.id);
        }
      case 'delete':
        final confirmed = await showConfirmDialog(
          context,
          title: 'common.delete'.tr(),
          message: 'chicks.delete_confirm'.tr(),
          confirmLabel: 'common.delete'.tr(),
          isDestructive: true,
        );
        if (confirmed == true) {
          await notifier.deleteChick(chick.id);
          if (context.mounted) context.pop();
        }
    }
  }
}
