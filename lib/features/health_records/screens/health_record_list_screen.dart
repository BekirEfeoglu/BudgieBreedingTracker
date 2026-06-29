import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:budgie_breeding_tracker/core/constants/app_icons.dart';
import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_icon.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/app_icon_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_screen_title.dart';
import 'package:budgie_breeding_tracker/core/widgets/empty_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/buttons/fab_button.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/health_records/providers/health_record_providers.dart';
import 'package:budgie_breeding_tracker/shared/widgets/health_records.dart';
import 'package:budgie_breeding_tracker/features/health_records/widgets/health_record_filter_bar.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

/// Screen showing all health records for the current user.
class HealthRecordListScreen extends ConsumerStatefulWidget {
  const HealthRecordListScreen({super.key});

  @override
  ConsumerState<HealthRecordListScreen> createState() =>
      _HealthRecordListScreenState();
}

class _HealthRecordListScreenState
    extends ConsumerState<HealthRecordListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final recordsAsync = ref.watch(healthRecordsStreamProvider(userId));
    final query = ref.watch(healthRecordSearchQueryProvider);

    // Sync controller when query is cleared externally. Defer mutation
    // to post-frame to avoid touching controller state during build.
    if (query.isEmpty && _searchController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _searchController.clear();
      });
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(healthRecordsStreamProvider(userId));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: AppScreenTitle(
                title: 'health_records.title'.tr(),
                iconAsset: AppIcons.health,
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'health_records.search_hint'.tr(),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: AppIcon(AppIcons.search, size: 20),
                        ),
                        suffixIcon: query.isNotEmpty
                            ? AppIconButton(
                                icon: const Icon(LucideIcons.x),
                                semanticLabel: 'common.clear'.tr(),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(healthRecordSearchQueryProvider.notifier)
                                      .state = '';
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        ref.read(healthRecordSearchQueryProvider.notifier).state = value;
                      },
                    ),
                  ),
                  // Filter bar
                  const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const HealthRecordFilterBar(),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            // List
            recordsAsync.when(
              skipLoadingOnRefresh: true,
              loading: () => const SliverFillRemaining(
                child: LoadingState(),
              ),
              error: (error, _) => SliverFillRemaining(
                child: ErrorState(
                  message: 'common.data_load_error'.tr(),
                  onRetry: () => ref.invalidate(healthRecordsStreamProvider(userId)),
                ),
              ),
              data: (allRecords) {
                final records = ref.watch(
                  searchedAndFilteredHealthRecordsProvider(allRecords),
                );

                if (allRecords.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: const AppIcon(AppIcons.health),
                      title: 'health_records.no_records'.tr(),
                      subtitle: 'health_records.no_records_hint'.tr(),
                      actionLabel: 'health_records.add_record'.tr(),
                      onAction: () => context.push('/health-records/form'),
                    ),
                  );
                }

                if (records.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: const Icon(LucideIcons.searchX),
                      title: 'common.no_results'.tr(),
                      subtitle: 'common.no_results_hint'.tr(),
                    ),
                  );
                }

                final animalCache = ref.watch(animalNameCacheProvider(userId));

                return SliverPadding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: AppSpacing.xxxl * 2,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = records[index];
                        final animal = r.birdId != null ? animalCache[r.birdId!] : null;
                        final displayName = animal != null
                            ? (animal.ringNumber != null
                                ? '${animal.name} (${animal.ringNumber})'
                                : animal.name)
                            : null;
                        return HealthRecordCard(
                          key: ValueKey(r.id),
                          record: r,
                          animalName: displayName,
                        );
                      },
                      childCount: records.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FabButton(
        icon: const AppIcon(AppIcons.add),
        tooltip: 'health_records.add_record'.tr(),
        onPressed: () => context.push('/health-records/form'),
      ),
    );
  }
}
