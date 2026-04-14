import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/enums/admin_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import '../constants/admin_constants.dart';
import '../providers/admin_feedback_providers.dart';
import '_feedback_detail_sheet.dart';

part 'admin_feedback_screen_tiles.dart';

class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() =>
      _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AdminConstants.searchDebounceDuration, () {
      if (!mounted) return;
      final current = ref.read(feedbackQueryProvider);
      ref.read(feedbackQueryProvider.notifier).state = current.copyWith(
        searchQuery: value.trim(),
      );
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    final current = ref.read(feedbackQueryProvider);
    ref.read(feedbackQueryProvider.notifier).state = current.copyWith(
      searchQuery: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(adminFeedbackProvider);
    final query = ref.watch(feedbackQueryProvider);

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
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'admin.search_feedback'.tr(),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: AppIcon(AppIcons.search, size: 18),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: _clearSearch,
                            tooltip: 'common.cancel'.tr(),
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                ),
              ),
              _StatusFilterBar(
                selected: query.statusFilter,
                total: items.length,
                onChanged: (v) {
                  final current = ref.read(feedbackQueryProvider);
                  ref.read(feedbackQueryProvider.notifier).state =
                      current.copyWith(statusFilter: v);
                },
              ),
              Expanded(
                child: items.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        padding: const EdgeInsets.only(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.xxxl,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) => _FeedbackTile(
                          key: ValueKey(items[i]['id']),
                          item: items[i],
                          onTap: () => _showDetail(ctx, items[i]),
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

  void _showDetail(BuildContext context, Map<String, dynamic> item) {
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

