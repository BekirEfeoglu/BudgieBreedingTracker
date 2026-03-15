import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/features/chicks/providers/chick_providers.dart';
import 'package:budgie_breeding_tracker/features/breeding/providers/breeding_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/active_breedings_section.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/dashboard_stats_grid.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/incubation_summary_section.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/limit_approaching_banner.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/quick_actions_row.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/recent_chicks_section.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/sync_status_bar.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/unweaned_alert_banner.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/welcome_header.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_brand_title.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_bell_button.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_button.dart';
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_providers.dart';

/// Main home dashboard screen.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    // Request notification permission after the user sees the home screen.
    // Deferred by 3 seconds so the dialog doesn't appear immediately.
    ref.watch(deferredNotificationPermissionProvider);

    // Show a one-time SnackBar when notification permission is denied
    ref.listen<bool>(notificationPermissionGrantedProvider, (prev, granted) {
      if (prev != false && !granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('notifications.permission_denied_hint'.tr()),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const AppBrandTitle(size: AppBrandSize.small),
        centerTitle: true,
        actions: const [NotificationBellButton(), ProfileMenuButton()],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Full sync with server (reconciles hard-deleted records)
          await ref.read(syncOrchestratorProvider).forceFullSync();
          ref.invalidate(dashboardStatsProvider(userId));
          ref.invalidate(recentChicksProvider(userId));
          ref.invalidate(chickParentsByEggProvider(userId));
          ref.invalidate(activeBreedingsForDashboardProvider(userId));
          ref.invalidate(unweanedChicksCountProvider(userId));
          ref.invalidate(incubatingEggsSummaryProvider(userId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SyncStatusBar(),
              const SizedBox(height: AppSpacing.lg),
              const WelcomeHeader(),
              const SizedBox(height: AppSpacing.md),
              _UnweanedSection(userId: userId),
              LimitApproachingBanner(userId: userId),
              const SizedBox(height: AppSpacing.sm),
              _StatsSection(userId: userId),
              const SizedBox(height: AppSpacing.lg),
              const QuickActionsRow(),
              const SizedBox(height: AppSpacing.lg),
              _IncubationSummarySection(userId: userId),
              const SizedBox(height: AppSpacing.lg),
              _ActiveBreedingsSection(userId: userId),
              const SizedBox(height: AppSpacing.lg),
              _RecentChicksSection(userId: userId),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: AdBannerWidget(isPremiumProvider: isPremiumProvider),
              ),
              const SizedBox(height: AppSpacing.xxxl * 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnweanedSection extends ConsumerWidget {
  final String userId;

  const _UnweanedSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unweanedAsync = ref.watch(unweanedChicksCountProvider(userId));

    return unweanedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (count) => UnweanedAlertBanner(count: count),
    );
  }
}

class _StatsSection extends ConsumerWidget {
  final String userId;

  const _StatsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider(userId));

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.xxxl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text('common.data_load_error'.tr()),
      ),
      data: (stats) => DashboardStatsGrid(stats: stats),
    );
  }
}

class _ActiveBreedingsSection extends ConsumerWidget {
  final String userId;

  const _ActiveBreedingsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairsAsync = ref.watch(activeBreedingsForDashboardProvider(userId));

    return pairsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          'common.data_load_error'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
      data: (pairs) => ActiveBreedingsSection(pairs: pairs),
    );
  }
}

class _RecentChicksSection extends ConsumerWidget {
  final String userId;

  const _RecentChicksSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chicksAsync = ref.watch(recentChicksProvider(userId));

    return chicksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          'common.data_load_error'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
      data: (chicks) => RecentChicksSection(chicks: chicks, userId: userId),
    );
  }
}

class _IncubationSummarySection extends ConsumerWidget {
  final String userId;

  const _IncubationSummarySection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(incubatingEggsSummaryProvider(userId));

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          'common.data_load_error'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      ),
      data: (eggs) => IncubationSummarySection(eggs: eggs),
    );
  }
}
