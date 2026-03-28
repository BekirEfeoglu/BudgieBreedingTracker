import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:budgie_breeding_tracker/core/theme/app_spacing.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/rewarded_ad_button.dart';

class _FakeAdService extends AdService {
  bool _isReady = true;
  bool showAdCalled = false;

  set isReady(bool value) => _isReady = value;

  @override
  bool get isRewardedAdReady => _isReady;

  @override
  Future<void> showRewardedAd({
    required VoidCallback onRewarded,
    VoidCallback? onAdClosed,
  }) async {
    showAdCalled = true;
    if (_isReady) {
      onRewarded();
    }
    onAdClosed?.call();
  }
}

Widget _wrap(Widget child, {required AdService adService}) {
  return ProviderScope(
    overrides: [adServiceProvider.overrideWithValue(adService)],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('RewardedAdButton', () {
    late _FakeAdService fakeAdService;

    setUp(() {
      fakeAdService = _FakeAdService();
    });

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RewardedAdButton(label: 'Watch Ad', onRewarded: () {}),
          adService: fakeAdService,
        ),
      );
      await tester.pump();

      expect(find.byType(RewardedAdButton), findsOneWidget);
    });

    testWidgets('shows label text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RewardedAdButton(label: 'Watch Ad', onRewarded: () {}),
          adService: fakeAdService,
        ),
      );
      await tester.pump();

      expect(find.text('Watch Ad'), findsOneWidget);
    });

    testWidgets('shows play icon when not loading', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RewardedAdButton(label: 'Watch Ad', onRewarded: () {}),
          adService: fakeAdService,
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              widget.icon == LucideIcons.play &&
              widget.size == 18,
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RewardedAdButton(
            label: 'Watch Ad',
            subtitle: 'Earn a reward',
            onRewarded: () {},
          ),
          adService: fakeAdService,
        ),
      );
      await tester.pump();

      expect(find.text('Earn a reward'), findsOneWidget);
    });

    testWidgets('does not show subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RewardedAdButton(label: 'Watch Ad', onRewarded: () {}),
          adService: fakeAdService,
        ),
      );
      await tester.pump();

      // Only the label text should be present
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders as OutlinedButton', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RewardedAdButton(label: 'Watch Ad', onRewarded: () {}),
          adService: fakeAdService,
        ),
      );
      await tester.pump();

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows snackbar when ad is not ready', (tester) async {
      fakeAdService.isReady = false;

      await tester.pumpWidget(
        _wrap(
          RewardedAdButton(label: 'Watch Ad', onRewarded: () {}),
          adService: fakeAdService,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(find.text('ads.ad_not_available'), findsOneWidget);
    });

    testWidgets('calls onRewarded when ad completes successfully', (
      tester,
    ) async {
      var rewardCalled = false;

      await tester.pumpWidget(
        _wrap(
          RewardedAdButton(
            label: 'Watch Ad',
            onRewarded: () => rewardCalled = true,
          ),
          adService: fakeAdService,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(rewardCalled, isTrue);
      expect(fakeAdService.showAdCalled, isTrue);
    });

    testWidgets('button has full width via minimumSize', (tester) async {
      await tester.pumpWidget(
        _wrap(
          RewardedAdButton(label: 'Watch Ad', onRewarded: () {}),
          adService: fakeAdService,
        ),
      );
      await tester.pump();

      // The OutlinedButton should be full-width
      final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
      expect(
        button.style?.minimumSize?.resolve({}),
        const Size(double.infinity, AppSpacing.touchTargetMin),
      );
    });
  });
}
