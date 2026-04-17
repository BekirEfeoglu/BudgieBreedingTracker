import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/core/widgets/error_state.dart';
import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/data/providers/chick_stream_providers.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/features/home/providers/home_providers.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/active_breedings_section.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/dashboard_stats_grid.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/incubation_summary_section.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/grace_period_banner.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/limit_approaching_banner.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/quick_actions_row.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/recent_chicks_section.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/sync_status_bar.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/unweaned_alert_banner.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/welcome_header.dart';
import 'package:budgie_breeding_tracker/data/providers/premium_shared_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_providers.dart';
import 'package:budgie_breeding_tracker/core/widgets/app_brand_title.dart';
import 'package:budgie_breeding_tracker/features/notifications/widgets/notification_bell_button.dart'; // Cross-feature import: app-shell AppBar widget shared across all main screens
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_menu_button.dart'; // Cross-feature import: app-shell AppBar widget shared across all main screens
import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/domain/services/notifications/notification_permission_handler.dart';
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

    // Show a SnackBar with settings action when notification permission is denied.
    // Throttled to once per day to avoid nagging on every app launch.
    ref.listen<bool>(notificationPermissionGrantedProvider, (prev, granted) {
      if (prev != false && !granted) {
        _showPermissionDeniedSnackBarIfNeeded(context);
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
          // Capture ScaffoldMessenger before async gap
          final messenger = ScaffoldMessenger.of(context);
          // Full sync with server (reconciles hard-deleted records)
          await ref.read(syncOrchestratorProvider).forceFullSync();
          ref.invalidate(dashboardStatsProvider(userId));
          ref.invalidate(recentChicksProvider(userId));
          ref.invalidate(chickParentsByEggProvider(userId));
          ref.invalidate(activeBreedingsForDashboardProvider(userId));
          ref.invalidate(unweanedChicksCountProvider(userId));
          ref.invalidate(incubatingEggsSummaryProvider(userId));
          if (context.mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('sync.synced'.tr()),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
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
              const GracePeriodBanner(),
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
                child: AdBannerWidget(
                  isPremiumProvider: isPremiumProvider,
                  adBannerLoader: () => defaultAdBannerLoader(ref),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl * 2),
            ],
          ),
        ),
      ),
    );
  }
}

const _permissionSnackBarLastShownKey =
    'pref_notification_snackbar_last_shown';

/// Shows the permission-denied SnackBar at most once per day.
Future<void> _showPermissionDeniedSnackBarIfNeeded(
  BuildContext context,
) async {
  final prefs = await SharedPreferences.getInstance();
  final lastShown = prefs.getInt(_permissionSnackBarLastShownKey) ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  const oneDayMs = 24 * 60 * 60 * 1000;

  if (now - lastShown < oneDayMs) return;

  await prefs.setInt(_permissionSnackBarLastShownKey, now);

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('notifications.permission_denied_hint'.tr()),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: 'notifications.open_settings'.tr(),
        onPressed: () {
          NotificationPermissionHandler.openNotificationSettings();
        },
      ),
    ),
  );
}

class _UnweanedSection extends ConsumerWidget {
  final String userId;

  const _UnweanedSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unweanedAsync = ref.watch(unweanedChicksCountProvider(userId));

    // IMPROVED: log error on failure instead of silent SizedBox.shrink
    return unweanedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, st) {
        AppLogger.error('[HomeScreen] UnweanedCount error', error, st);
        return const SizedBox.shrink();
      },
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
      loading: () => const _DashboardStatsSkeleton(),
      error: (error, st) {
        AppLogger.error('[HomeScreen] Stats error', error, st);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(dashboardStatsProvider(userId)),
          ),
        );
      },
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

    // IMPROVED: show error state with retry instead of silent empty list
    return pairsAsync.when(
      loading: () => const _SectionSkeleton(),
      error: (error, st) {
        AppLogger.error('[HomeScreen] ActiveBreedings error', error, st);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () =>
                ref.invalidate(activeBreedingsForDashboardProvider(userId)),
          ),
        );
      },
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

    // IMPROVED: show error state with retry instead of silent empty list
    return chicksAsync.when(
      loading: () => const _SectionSkeleton(),
      error: (error, st) {
        AppLogger.error('[HomeScreen] RecentChicks error', error, st);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () => ref.invalidate(recentChicksProvider(userId)),
          ),
        );
      },
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

    // IMPROVED: show skeleton on loading and error state on failure
    // instead of silent SizedBox.shrink / misleading empty list
    return summaryAsync.when(
      loading: () => const _SectionSkeleton(),
      error: (error, st) {
        AppLogger.error('[HomeScreen] IncubationSummary error', error, st);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: ErrorState(
            message: 'common.data_load_error'.tr(),
            onRetry: () =>
                ref.invalidate(incubatingEggsSummaryProvider(userId)),
          ),
        );
      },
      data: (eggs) => IncubationSummarySection(eggs: eggs),
    );
  }
}

/// Skeleton placeholder for the 2x2 + 1 dashboard stats grid.
class _DashboardStatsSkeleton extends StatelessWidget {
  const _DashboardStatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 90)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonLoader(height: 90)),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: SkeletonLoader(height: 90)),
              SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonLoader(height: 90)),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          SkeletonLoader(height: 86),
        ],
      ),
    );
  }
}

/// Skeleton placeholder for list sections (active breedings, recent chicks).
class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(width: 140, height: 18),
          SizedBox(height: AppSpacing.md),
          SkeletonLoader(height: 72),
          SizedBox(height: AppSpacing.sm),
          SkeletonLoader(height: 72),
        ],
      ),
    );
  }
}
