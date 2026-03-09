import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/cards/info_card.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/data/models/health_record_model.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_form_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_card.dart';

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
          message: '${'common.data_load_error'.tr()}: $error',
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

    ref.listen<HealthRecordFormState>(healthRecordFormStateProvider,
        (_, state) {
      if (state.isSuccess) {
        ref.read(healthRecordFormStateProvider.notifier).reset();
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(record.title),
        actions: [
          IconButton(
            icon: const AppIcon(AppIcons.edit),
            tooltip: 'common.edit'.tr(),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                      subtitle: '${record.cost!.toStringAsFixed(2)} ${'settings.currency_symbol'.tr()}',
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
                  if (record.notes != null &&
                      record.notes!.isNotEmpty) ...[
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

  void _onDelete(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('common.delete'.tr()),
        content: Text('health_records.delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      ref.read(healthRecordFormStateProvider.notifier).deleteRecord(record.id);
    }
  }
}

class _HeaderSection extends StatelessWidget {
  final HealthRecord record;
  final ThemeData theme;

  const _HeaderSection({required this.record, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: healthRecordTypeColor(record.type).withValues(alpha: 0.08),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor:
                healthRecordTypeColor(record.type).withValues(alpha: 0.2),
            child: Icon(
              healthRecordTypeIcon(record.type),
              size: 32,
              color: healthRecordTypeColor(record.type),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            record.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            healthRecordTypeLabel(record.type),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: healthRecordTypeColor(record.type),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimalInfoCard extends ConsumerWidget {
  final String birdId;

  const _AnimalInfoCard({required this.birdId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final cache = ref.watch(animalNameCacheProvider(userId));
    final animal = cache[birdId];

    if (animal == null) return const SizedBox.shrink();

    final displayName = animal.ringNumber != null
        ? '${animal.name} (${animal.ringNumber})'
        : animal.name;
    final typeLabel = animal.isChick
        ? 'chicks.chick_label'.tr()
        : 'health_records.bird_label'.tr();

    return InfoCard(
      icon: AppIcon(
        animal.isChick ? AppIcons.chick : AppIcons.bird,
      ),
      title: typeLabel,
      subtitle: displayName,
      onTap: () => context.push(
        animal.isChick ? '/chicks/$birdId' : '/birds/$birdId',
      ),
    );
  }
}
