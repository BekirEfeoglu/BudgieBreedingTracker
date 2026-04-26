import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/date_picker_field.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/data/providers/date_format_providers.dart';
import 'package:budgie_breeding_tracker/data/models/egg_model.dart';
import 'package:budgie_breeding_tracker/domain/services/incubation/incubation_calculator.dart';
import 'package:budgie_breeding_tracker/data/providers/breeding_detail_stream_providers.dart';
import 'package:budgie_breeding_tracker/features/eggs/providers/egg_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/eggs.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

part 'egg_management_add_sheet.dart';

/// Screen for managing eggs within an incubation.
class EggManagementScreen extends ConsumerWidget {
  final String pairId;

  const EggManagementScreen({super.key, required this.pairId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incubationsAsync = ref.watch(incubationsByPairProvider(pairId));

    return incubationsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: AppScreenTitle(
            title: 'eggs.management'.tr(),
            iconAsset: AppIcons.egg,
          ),
        ),
        body: const LoadingState(),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: AppScreenTitle(
            title: 'eggs.management'.tr(),
            iconAsset: AppIcons.egg,
          ),
        ),
        body: ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(incubationsByPairProvider(pairId)),
        ),
      ),
      data: (incubations) {
        final incubation = selectPrimaryIncubation(incubations);
        if (incubation == null) {
          return Scaffold(
            appBar: AppBar(
              title: AppScreenTitle(
                title: 'eggs.management'.tr(),
                iconAsset: AppIcons.egg,
              ),
            ),
            body: ErrorState(message: 'eggs.incubation_not_found'.tr()),
          );
        }
        return _EggManagementContent(incubationId: incubation.id);
      },
    );
  }
}

class _EggManagementContent extends ConsumerWidget {
  final String incubationId;

  const _EggManagementContent({required this.incubationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eggsAsync = ref.watch(eggsForIncubationProvider(incubationId));

    // Show SnackBar when chick is auto-created from hatched egg
    ref.listen<EggActionsState>(eggActionsProvider, (_, state) {
      if (!context.mounted) return;
      if (state.warning != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.warning!)));
      }
      if (state.error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.error!)));
      }
      if (state.chickCreated) {
        ActionFeedbackService.show(
          'eggs.chick_created_from_egg'.tr(),
          actionRoute: '/chicks',
          actionLabel: 'eggs.go_to_chicks'.tr(),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: 'eggs.management'.tr(),
          iconAsset: AppIcons.egg,
        ),
      ),
      body: eggsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () =>
              ref.invalidate(eggsForIncubationProvider(incubationId)),
        ),
        data: (eggs) {
          if (eggs.isEmpty) {
            return EmptyState(
              icon: const AppIcon(AppIcons.egg),
              title: 'eggs.no_eggs'.tr(),
              subtitle: 'eggs.no_eggs_hint'.tr(),
              actionLabel: 'eggs.add_egg'.tr(),
              onAction: () =>
                  _showAddEggSheet(context, ref, incubationId, eggs),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: AppSpacing.screenPadding,
                child: EggSummaryRow(eggs: eggs),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(eggsForIncubationProvider(incubationId));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxxl * 2),
                    itemCount: eggs.length,
                    itemBuilder: (context, index) {
                      final egg = eggs[index];
                      return EggListItem(
                        egg: egg,
                        onStatusUpdate: () async {
                          final newStatus = await showEggStatusUpdateSheet(
                            context,
                            egg,
                          );
                          if (newStatus != null) {
                            ref
                                .read(eggActionsProvider.notifier)
                                .updateEggStatus(egg, newStatus);
                          }
                        },
                        onDelete: () => _confirmDeleteEgg(context, ref, egg),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: eggsAsync.maybeWhen(
        data: (eggs) => eggs.isEmpty
            ? null
            : FabButton(
                icon: const AppIcon(AppIcons.add),
                tooltip: 'eggs.add_egg'.tr(),
                onPressed: () {
                  final eggs =
                      ref.read(eggsForIncubationProvider(incubationId)).value ??
                      [];
                  _showAddEggSheet(context, ref, incubationId, eggs);
                },
              ),
        orElse: () => null,
      ),
    );
  }
}
