import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart' as app;
import '../providers/gamification_providers.dart';
import '../widgets/leaderboard_tile.dart';
import 'package:budgie_breeding_tracker/core/widgets/loading_state.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('leaderboard.title'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(leaderboardProvider);
        },
        child: leaderboardAsync.when(
          loading: () => const LoadingState(),
          error: (error, _) => app.ErrorState(
            message: '${'leaderboard.load_error'.tr()}: $error',
            onRetry: () => ref.invalidate(leaderboardProvider),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return EmptyState(
                icon: const Icon(LucideIcons.trophy),
                title: 'leaderboard.no_data'.tr(),
                subtitle: 'leaderboard.no_data_hint'.tr(),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xxxl * 2,
              ),
              itemCount: entries.length,
              itemBuilder: (context, index) => LeaderboardTile(
                key: ValueKey(entries[index].userId),
                rank: index + 1,
                userLevel: entries[index],
              ),
            );
          },
        ),
      ),
    );
  }
}
