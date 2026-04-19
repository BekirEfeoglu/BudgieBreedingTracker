import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/progress_bar.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/data/models/breeding_pair_model.dart';
import 'package:budgie_breeding_tracker/data/models/incubation_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_detail_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_form_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_pair_info_section.dart';
import 'package:budgie_breeding_tracker/features/breeding/widgets/breeding_eggs_section.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';

part 'breeding_detail_sections.dart';

/// Detail screen for a breeding pair showing incubation, eggs, milestones.
class BreedingDetailScreen extends ConsumerWidget {
  final String pairId;

  const BreedingDetailScreen({super.key, required this.pairId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairAsync = ref.watch(breedingPairByIdProvider(pairId));

    return pairAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('common.loading'.tr())),
        body: const LoadingState(),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: Text('common.error'.tr())),
        body: ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(breedingPairByIdProvider(pairId)),
        ),
      ),
      data: (pair) {
        if (pair == null) {
          return Scaffold(
            appBar: AppBar(title: Text('common.not_found'.tr())),
            body: ErrorState(message: 'breeding.not_found'.tr()),
          );
        }
        return _DetailContent(pair: pair);
      },
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final BreedingPair pair;

  const _DetailContent({required this.pair});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incubationsAsync = ref.watch(incubationsByPairProvider(pair.id));

    // Side effects: success after complete/cancel/delete → pop + snackbar
    ref.listen<BreedingFormState>(breedingFormStateProvider, (prev, state) {
      if (!context.mounted) return;
      if (state.isSuccess && !(prev?.isSuccess ?? false)) {
        ref.read(breedingFormStateProvider.notifier).reset();
        ActionFeedbackService.show('common.saved_successfully'.tr());
        if (context.mounted) context.pop();
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('breeding.detail'.tr()),
        actions: [
          AppIconButton(
            icon: const AppIcon(AppIcons.edit),
            tooltip: 'common.edit'.tr(),
            semanticLabel: 'common.edit'.tr(),
            onPressed: () => context.push('/breeding/form?editId=${pair.id}'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'complete',
                child: Text('breeding.complete'.tr()),
              ),
              PopupMenuItem(
                value: 'cancel',
                child: Text('breeding.cancel_breeding'.tr()),
              ),
              PopupMenuItem(value: 'delete', child: Text('common.delete'.tr())),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSpacing.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BreedingPairInfoSection(pair: pair),
                const Divider(
                  height: 1,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                ),
                incubationsAsync.when(
                  loading: () => const Padding(
                    padding: AppSpacing.screenPadding,
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (incubations) {
                    final incubation = selectPrimaryIncubation(incubations);
                    if (incubation == null) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IncubationSection(incubation: incubation),
                        const Divider(
                          height: 1,
                          indent: AppSpacing.lg,
                          endIndent: AppSpacing.lg,
                        ),
                        BreedingEggsSection(
                          incubationId: incubation.id,
                          pairId: pair.id,
                        ),
                        if (incubation.startDate != null) ...[
                          const Divider(
                            height: 1,
                            indent: AppSpacing.lg,
                            endIndent: AppSpacing.lg,
                          ),
                          BreedingMilestoneSection(
                            startDate: incubation.startDate!,
                            totalDays: incubation.totalIncubationDays(),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                if (pair.notes != null && pair.notes!.isNotEmpty) ...[
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  BreedingNotesSection(notes: pair.notes!),
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
    final formNotifier = ref.read(breedingFormStateProvider.notifier);

    switch (action) {
      case 'complete':
        final confirmed = await showConfirmDialog(
          context,
          title: 'breeding.complete'.tr(),
          message: 'breeding.complete_confirm'.tr(),
          confirmLabel: 'breeding.complete'.tr(),
        );
        if (!context.mounted) return;
        if (confirmed == true) {
          await formNotifier.completeBreeding(pair.id);
        }
      case 'cancel':
        final confirmed = await showConfirmDialog(
          context,
          title: 'breeding.cancel_breeding'.tr(),
          message: 'breeding.cancel_confirm'.tr(),
          confirmLabel: 'breeding.cancel_breeding'.tr(),
          isDestructive: true,
        );
        if (!context.mounted) return;
        if (confirmed == true) {
          await formNotifier.cancelBreeding(pair.id);
        }
      case 'delete':
        final confirmed = await showConfirmDialog(
          context,
          title: 'common.delete'.tr(),
          message: 'breeding.delete_confirm'.tr(),
          confirmLabel: 'common.delete'.tr(),
          isDestructive: true,
        );
        if (!context.mounted) return;
        if (confirmed == true) {
          await formNotifier.deleteBreeding(pair.id);
        }
    }
  }
}
