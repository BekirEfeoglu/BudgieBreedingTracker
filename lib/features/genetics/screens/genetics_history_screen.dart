import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/providers/genetics_history_providers.dart';
import 'package:budgie_breeding_tracker/features/genetics/widgets/genetics_history_card.dart';
import 'package:budgie_breeding_tracker/router/route_names.dart';

/// Screen showing saved genetics calculation history.
class GeneticsHistoryScreen extends ConsumerStatefulWidget {
  const GeneticsHistoryScreen({super.key});

  @override
  ConsumerState<GeneticsHistoryScreen> createState() =>
      _GeneticsHistoryScreenState();
}

class _GeneticsHistoryScreenState extends ConsumerState<GeneticsHistoryScreen> {
  final Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final historyAsync = ref.watch(geneticsHistoryStreamProvider(userId));
    final isSelectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: AppScreenTitle(
          title: isSelectionMode
              ? '${_selectedIds.length} ${'common.selected'.tr()}'
              : 'genetics.history'.tr(),
          iconAsset: AppIcons.calculator,
        ),
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(LucideIcons.x),
                onPressed: _clearSelection,
              )
            : null,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'common.data_load_error'.tr(),
          onRetry: () => ref.invalidate(geneticsHistoryStreamProvider(userId)),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              icon: const AppIcon(AppIcons.calculator),
              title: 'genetics.no_history'.tr(),
              subtitle: 'genetics.no_history_hint'.tr(),
              actionLabel: 'genetics.start_calculation'.tr(),
              onAction: () => context.pop(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(geneticsHistoryStreamProvider(userId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xxxl * 2,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return GeneticsHistoryCard(
                  key: ValueKey(entry.id),
                  entry: entry,
                  isSelected: _selectedIds.contains(entry.id),
                  isSelectionMode: isSelectionMode,
                  onSelect: () => _toggleSelection(entry.id),
                  onLongPress: () {
                    if (!isSelectionMode) {
                      _toggleSelection(entry.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: _selectedIds.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () {
                final ids = _selectedIds.toList();
                context.push(
                  '${AppRoutes.geneticsCompare}?ids=${ids.join(',')}',
                  extra: ids,
                );
                _clearSelection();
              },
              icon: const Icon(LucideIcons.gitCompare),
              label: Text('genetics.compare_selected'.tr()),
            )
          : null,
    );
  }
}
