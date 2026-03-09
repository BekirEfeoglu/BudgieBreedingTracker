import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/supabase_constants.dart';
import '../../../core/enums/admin_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/admin_feedback_providers.dart';
import '_feedback_detail_sheet.dart';

class AdminFeedbackScreen extends ConsumerWidget {
  const AdminFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(adminFeedbackProvider);
    final statusFilter = ref.watch(feedbackStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('admin.feedback_admin'.tr()),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            tooltip: 'common.retry'.tr(),
            onPressed: () => ref.invalidate(adminFeedbackProvider),
          ),
        ],
      ),
      body: feedbackAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('common.data_load_error'.tr())),
        data: (items) {
          final statusName = statusFilter?.toJson();
          final filtered = statusName == null
              ? items
              : items.where((f) => f['status'] == statusName).toList();

          return Column(
            children: [
              _StatusFilterBar(
                selected: statusFilter,
                total: items.length,
                onChanged: (v) =>
                    ref.read(feedbackStatusFilterProvider.notifier).state = v,
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.xxxl,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _FeedbackTile(
                          key: ValueKey(filtered[i]['id']),
                          item: filtered[i],
                          onTap: () => _showDetail(ctx, ref, filtered[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.inbox,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3)),
          const SizedBox(height: AppSpacing.md),
          Text('admin.no_feedback'.tr(),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('admin.no_feedback_desc'.tr(),
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _showDetail(
      BuildContext context, WidgetRef ref, Map<String, dynamic> item) {
    final client = ref.read(supabaseClientProvider);

    Future<void> onSave({
      required String status,
      String? adminResponse,
      required String priority,
    }) async {
      try {
        final updates = <String, dynamic>{
          'status': status,
          'priority': priority,
          if (adminResponse != null && adminResponse.isNotEmpty)
            'admin_response': adminResponse,
        };
        await client
            .from(SupabaseConstants.feedbackTable)
            .update(updates)
            .eq('id', item['id'] as String);
        if (context.mounted) {
          ref.invalidate(adminFeedbackProvider);
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('admin.feedback_updated'.tr())),
          );
        }
      } catch (e, st) {
        AppLogger.error('AdminFeedback.save', e, st);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('admin.action_error'.tr())),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (_) => FeedbackDetailSheet(item: item, onSave: onSave),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final FeedbackStatus? selected;
  final int total;
  final ValueChanged<FeedbackStatus?> onChanged;

  const _StatusFilterBar({
    required this.selected,
    required this.total,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = <(FeedbackStatus?, String)>[
      (null, 'admin.feedback_status_all'.tr()),
      (FeedbackStatus.open, 'admin.feedback_status_open'.tr()),
      (FeedbackStatus.resolved, 'admin.feedback_status_resolved'.tr()),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: theme.colorScheme.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((opt) {
                  final isSelected = selected == opt.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(opt.$2),
                      selected: isSelected,
                      onSelected: (_) => onChanged(opt.$1),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Text(
            'admin.feedback_count'.tr(args: [total.toString()]),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _FeedbackTile({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = item['type'] as String? ?? 'general';
    final status = item['status'] as String? ?? 'open';
    final priority = item['priority'] as String? ?? 'normal';
    final subject = item['subject'] as String? ?? '';
    final email = item['email'] as String?;
    final createdAt = item['created_at'] as String?;
    final date = createdAt != null
        ? DateFormat('dd.MM.yyyy HH:mm')
            .format(DateTime.parse(createdAt).toLocal())
        : '';

    final typeColor = switch (type) {
      'bug' => AppColors.error,
      'feature' => AppColors.warning,
      _ => AppColors.budgieBlue,
    };
    final typeLabel = switch (type) {
      'bug' => 'admin.feedback_type_bug'.tr(),
      'feature' => 'admin.feedback_type_feature'.tr(),
      _ => 'admin.feedback_type_general'.tr(),
    };
    final priorityColor = switch (priority) {
      'high' => AppColors.error,
      'low' => theme.colorScheme.onSurfaceVariant,
      _ => AppColors.warning,
    };
    final isResolved = status == 'resolved';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: typeColor.withValues(alpha: 0.12),
        child: Icon(LucideIcons.messageSquare, size: 18, color: typeColor),
      ),
      title: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(typeLabel,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: typeColor, fontWeight: FontWeight.w600)),
          ),
          if (priority == 'high') ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(LucideIcons.alertCircle, size: 14, color: priorityColor),
          ],
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(subject,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
      subtitle: Text(
        email ?? date,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isResolved
          ? const Icon(LucideIcons.checkCircle2,
              size: 18, color: AppColors.success)
          : const Icon(LucideIcons.circle, size: 18, color: AppColors.warning),
    );
  }
}
