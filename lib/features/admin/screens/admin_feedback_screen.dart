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
import '../../../core/widgets/buttons/app_icon_button.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/data/providers/action_feedback_providers.dart';
import '../constants/admin_constants.dart';
import '../providers/admin_feedback_providers.dart';
import '../providers/admin_models.dart';
import '_feedback_detail_sheet.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

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
        limit: AdminConstants.feedbackPageSize,
      );
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    final current = ref.read(feedbackQueryProvider);
    ref.read(feedbackQueryProvider.notifier).state = current.copyWith(
      searchQuery: '',
      limit: AdminConstants.feedbackPageSize,
    );
  }

  Future<void> _refreshFeedback() async {
    ref.invalidate(adminFeedbackProvider);
    await ref.read(adminFeedbackProvider.future);
  }

  void _setStatusFilter(FeedbackStatus? status) {
    final current = ref.read(feedbackQueryProvider);
    ref.read(feedbackQueryProvider.notifier).state = current.copyWith(
      statusFilter: status,
      limit: AdminConstants.feedbackPageSize,
    );
  }

  void _clearFilters() {
    _debounce?.cancel();
    _searchController.clear();
    ref.read(feedbackQueryProvider.notifier).state = const FeedbackQuery(
      limit: AdminConstants.feedbackPageSize,
    );
  }

  void _loadMore() {
    final current = ref.read(feedbackQueryProvider);
    ref.read(feedbackQueryProvider.notifier).state = current.copyWith(
      limit: current.limit + AdminConstants.feedbackPageSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(adminFeedbackProvider);
    final query = ref.watch(feedbackQueryProvider);

    final hasFilter =
        query.searchQuery.isNotEmpty || query.statusFilter != null;

    return Scaffold(
      body: Column(
        children: [
          _FeedbackHeader(
            onRefresh: () => ref.invalidate(adminFeedbackProvider),
          ),
          Expanded(
            child: feedbackAsync.when(
              loading: () => const LoadingState(),
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
                              ? AppIconButton(
                                  icon: const Icon(LucideIcons.x, size: 18),
                                  onPressed: _clearSearch,
                                  tooltip: 'common.clear'.tr(),
                                  semanticLabel: 'common.clear'.tr(),
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _StatusFilterBar(
                      selected: query.statusFilter,
                      total: items.length,
                      hasFilter: hasFilter,
                      onChanged: _setStatusFilter,
                      onClear: _clearFilters,
                    ),
                    Expanded(
                      child: _FeedbackList(
                        items: items,
                        hasMore: items.length >= query.limit,
                        hasFilter: hasFilter,
                        onRefresh: _refreshFeedback,
                        onClearFilters: _clearFilters,
                        onLoadMore: _loadMore,
                        onTapItem: _showDetail,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> item) {
    Future<void> onSaveExtended({
      required String status,
      String? adminResponse,
      required String priority,
      String? category,
      String? assignedAdminId,
      String? internalNote,
    }) async {
      final notifier = ref.read(adminFeedbackActionProvider.notifier);
      final success = await notifier.updateFeedback(
        feedbackId: item['id'] as String,
        status: status,
        priority: priority,
        adminResponse: adminResponse,
        category: category,
        assignedAdminId: assignedAdminId,
        internalNote: internalNote,
      );
      if (context.mounted) {
        if (success) {
          Navigator.of(context).pop();
          ActionFeedbackService.show('admin.feedback_updated'.tr());
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('admin.action_error'.tr())));
        }
      }
    }

    Future<void> onSave({
      required String status,
      String? adminResponse,
      required String priority,
    }) {
      return onSaveExtended(
        status: status,
        priority: priority,
        adminResponse: adminResponse,
      );
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
      builder: (_) => FeedbackDetailSheet(
        item: item,
        onSave: onSave,
        onSaveExtended: onSaveExtended,
      ),
    );
  }
}
