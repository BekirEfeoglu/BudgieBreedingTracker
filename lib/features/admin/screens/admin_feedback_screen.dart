import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/enums/admin_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import '../../notifications/providers/action_feedback_providers.dart';
import '../providers/admin_feedback_providers.dart';
import '_feedback_detail_sheet.dart';

part 'admin_feedback_screen_tiles.dart';

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
        error: (e, _) => ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(adminFeedbackProvider),
        ),
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
          Icon(
            LucideIcons.inbox,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'admin.no_feedback'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'admin.no_feedback_desc'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) {
    Future<void> onSave({
      required String status,
      String? adminResponse,
      required String priority,
    }) async {
      final notifier = ref.read(adminFeedbackActionProvider.notifier);
      final success = await notifier.updateFeedback(
        feedbackId: item['id'] as String,
        status: status,
        priority: priority,
        adminResponse: adminResponse,
      );
      if (context.mounted) {
        if (success) {
          Navigator.of(context).pop();
          ActionFeedbackService.show('admin.feedback_updated'.tr());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('admin.action_error'.tr())),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: AppSpacing.maxSheetWidth),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (_) => FeedbackDetailSheet(item: item, onSave: onSave),
    );
  }
}

