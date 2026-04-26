import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/dialogs/confirm_dialog.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/core/extensions/num_extensions.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_form_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/health_records.dart';

part 'health_record_detail_widgets.dart';

/// Detail screen for a single health record.
class HealthRecordDetailScreen extends ConsumerWidget {
  final String recordId;

  const HealthRecordDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(healthRecordByIdProvider(recordId));

    return recordAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text('common.loading'.tr())),
        body: const LoadingState(),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(healthRecordByIdProvider(recordId)),
        ),
      ),
      data: (record) {
        if (record == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(message: 'health_records.not_found'.tr()),
          );
        }
        return _DetailContent(record: record);
      },
    );
  }
}

class _DetailContent extends ConsumerWidget {
  final HealthRecord record;

  const _DetailContent({required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd MMMM yyyy', context.locale.languageCode);

    ref.listen<HealthRecordFormState>(healthRecordFormStateProvider, (
      _,
      state,
    ) {
      if (!context.mounted) return;
      if (state.isSuccess) {
        ref.read(healthRecordFormStateProvider.notifier).reset();
        context.pop();
      }
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.error!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(record.title),
        actions: [
          AppIconButton(
            icon: const AppIcon(AppIcons.edit),
            tooltip: 'common.edit'.tr(),
            semanticLabel: 'common.edit'.tr(),
            onPressed: () =>
                context.push('/health-records/form?editId=${record.id}'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _onDelete(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'common.delete'.tr(),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _HeaderSection(record: record, theme: theme),
            const SizedBox(height: AppSpacing.lg),

            // Info cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.birdId != null)
                    _AnimalInfoCard(birdId: record.birdId!),
                  if (record.birdId != null)
                    const SizedBox(height: AppSpacing.sm),
                  InfoCard(
                    icon: const AppIcon(AppIcons.calendar),
                    title: 'common.date'.tr(),
                    subtitle: dateFormat.format(record.date),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InfoCard(
                    icon: Icon(healthRecordTypeIcon(record.type)),
                    title: 'common.type'.tr(),
                    subtitle: healthRecordTypeLabel(record.type),
                  ),
                  if (record.description != null &&
                      record.description!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InfoCard(
                      icon: const Icon(LucideIcons.fileText),
                      title: 'common.description'.tr(),
                      subtitle: record.description!,
                    ),
                  ],
                  if (record.treatment != null &&
                      record.treatment!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InfoCard(
                      icon: const AppIcon(AppIcons.health),
                      title: 'health_records.treatment'.tr(),
                      subtitle: record.treatment!,
                    ),
                  ],
                  if (record.veterinarian != null &&
                      record.veterinarian!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InfoCard(
                      icon: const AppIcon(AppIcons.profile),
                      title: 'health_records.veterinarian'.tr(),
                      subtitle: record.veterinarian!,
                    ),
                  ],
                  if (record.weight != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InfoCard(
                      icon: const AppIcon(AppIcons.weight),
                      title: 'health_records.weight'.tr(),
                      subtitle: '${record.weight} g',
                    ),
                  ],
                  if (record.cost != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InfoCard(
                      icon: const Icon(LucideIcons.creditCard),
                      title: 'health_records.cost'.tr(),
                      subtitle: record.cost!.formatCurrency(context),
                    ),
                  ],
                  if (record.followUpDate != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InfoCard(
                      icon: const Icon(LucideIcons.calendarDays),
                      title: 'health_records.follow_up'.tr(),
                      subtitle: dateFormat.format(record.followUpDate!),
                    ),
                  ],
                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    InfoCard(
                      icon: const Icon(LucideIcons.stickyNote),
                      title: 'common.notes'.tr(),
                      subtitle: record.notes!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'common.delete'.tr(),
      message: 'health_records.delete_confirm'.tr(),
      confirmLabel: 'common.delete'.tr(),
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      ref.read(healthRecordFormStateProvider.notifier).deleteRecord(record.id);
    }
  }
}

