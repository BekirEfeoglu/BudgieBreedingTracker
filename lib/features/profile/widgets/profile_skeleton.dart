import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/skeleton_loader.dart';

/// Shimmer skeleton layout that mirrors the profile screen structure.
///
/// Displayed during initial profile data loading instead of a bare spinner.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      children: const [
        // Avatar circle
        Center(
          child: SkeletonLoader(width: 112, height: 112, borderRadius: 56),
        ),
        SizedBox(height: AppSpacing.md),

        // Display name
        Center(child: SkeletonLoader(width: 160, height: 24)),
        SizedBox(height: AppSpacing.sm),

        // Email
        Center(child: SkeletonLoader(width: 200, height: 16)),
        SizedBox(height: AppSpacing.md),

        // Badges row
        Center(child: SkeletonLoader(width: 100, height: 22, borderRadius: 11)),
        SizedBox(height: AppSpacing.lg),

        // Stats row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [_StatSkeleton(), _StatSkeleton(), _StatSkeleton()],
          ),
        ),
        SizedBox(height: AppSpacing.lg),

        // Edit profile button
        Center(child: SkeletonLoader(width: 140, height: 36, borderRadius: 18)),
        SizedBox(height: AppSpacing.xxl),

        // Section title + card skeleton (Account Info)
        _SectionSkeleton(itemCount: 4),
        SizedBox(height: AppSpacing.xl),

        // Section title + card skeleton (App Preferences)
        _SectionSkeleton(itemCount: 4),
        SizedBox(height: AppSpacing.xl),

        // Section title + card skeleton (Security)
        _SectionSkeleton(itemCount: 2),
      ],
    );
  }
}

class _StatSkeleton extends StatelessWidget {
  const _StatSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SkeletonLoader(width: 36, height: 28),
        SizedBox(height: 2),
        SkeletonLoader(width: 48, height: 12),
      ],
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 120, height: 14),
          const SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: List.generate(itemCount, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index < itemCount - 1 ? AppSpacing.lg : 0,
                  ),
                  child: const Row(
                    children: [
                      SkeletonLoader(width: 22, height: 22, borderRadius: 4),
                      SizedBox(width: AppSpacing.md),
                      Expanded(child: SkeletonLoader(height: 16)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
