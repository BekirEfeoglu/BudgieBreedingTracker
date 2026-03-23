import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/widgets/skeleton_loader.dart';
import 'package:budgie_breeding_tracker/features/profile/widgets/profile_skeleton.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('ProfileSkeleton', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      expect(find.byType(ProfileSkeleton), findsOneWidget);
    });

    testWidgets('contains a ListView', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('ListView has NeverScrollableScrollPhysics', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('shows multiple SkeletonLoader widgets', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      // Should have many skeleton loaders for avatar, name, email, badges,
      // stats, button, and section items
      expect(find.byType(SkeletonLoader), findsAtLeastNWidgets(10));
    });

    testWidgets('has avatar circle skeleton with 112x112', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      // Find the avatar skeleton (112x112 with borderRadius 56)
      final skeletons = tester.widgetList<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      final avatarSkeleton = skeletons.firstWhere(
        (s) => s.width == 112 && s.height == 112 && s.borderRadius == 56,
        orElse: () => const SkeletonLoader(),
      );
      expect(avatarSkeleton.width, 112);
      expect(avatarSkeleton.height, 112);
      expect(avatarSkeleton.borderRadius, 56);
    });

    testWidgets('has display name skeleton with 160x24', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      final skeletons = tester.widgetList<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      final nameSkeleton = skeletons.where(
        (s) => s.width == 160 && s.height == 24,
      );
      expect(nameSkeleton, isNotEmpty);
    });

    testWidgets('has email skeleton with 200x16', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      final skeletons = tester.widgetList<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      final emailSkeleton = skeletons.where(
        (s) => s.width == 200 && s.height == 16,
      );
      expect(emailSkeleton, isNotEmpty);
    });

    testWidgets('has badges row skeleton', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      final skeletons = tester.widgetList<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      final badgeSkeleton = skeletons.where(
        (s) => s.width == 100 && s.height == 22 && s.borderRadius == 11,
      );
      expect(badgeSkeleton, isNotEmpty);
    });

    testWidgets('has edit profile button skeleton', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      final skeletons = tester.widgetList<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      final buttonSkeleton = skeletons.where(
        (s) => s.width == 140 && s.height == 36 && s.borderRadius == 18,
      );
      expect(buttonSkeleton, isNotEmpty);
    });

    testWidgets('has stats row with three stat skeletons', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      // Each _StatSkeleton has a 36x28 and a 48x12 skeleton
      final skeletons = tester.widgetList<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      final statValueSkeletons = skeletons.where(
        (s) => s.width == 36 && s.height == 28,
      );
      final statLabelSkeletons = skeletons.where(
        (s) => s.width == 48 && s.height == 12,
      );
      expect(statValueSkeletons.length, 3);
      expect(statLabelSkeletons.length, 3);
    });

    testWidgets('has section skeletons with title loaders', (tester) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      // Each _SectionSkeleton has a 120x14 title skeleton
      // Some sections may be off-screen in the ListView
      final skeletons = tester.widgetList<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      final sectionTitleSkeletons = skeletons.where(
        (s) => s.width == 120 && s.height == 14,
      );
      expect(sectionTitleSkeletons.length, greaterThanOrEqualTo(2));
    });

    testWidgets('section skeletons have item rows with icon and text', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const ProfileSkeleton()));
      await tester.pump();

      // Each _SectionSkeleton item row has a 22x22 icon skeleton
      // Some items may be off-screen in the ListView
      final skeletons = tester.widgetList<SkeletonLoader>(
        find.byType(SkeletonLoader),
      );
      final iconSkeletons = skeletons.where(
        (s) => s.width == 22 && s.height == 22 && s.borderRadius == 4,
      );
      expect(iconSkeletons.length, greaterThanOrEqualTo(8));
    });
  });
}
