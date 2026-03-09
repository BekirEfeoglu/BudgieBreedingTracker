import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/domain/services/ads/ad_service.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

void main() {
  group('AdBannerWidget', () {
    testWidgets('renders SizedBox.shrink when premium', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWithValue(true),
            adServiceProvider.overrideWithValue(AdService()),
          ],
          child: MaterialApp(
            home: Scaffold(body: AdBannerWidget(isPremiumProvider: isPremiumProvider)),
          ),
        ),
      );

      // Should render nothing (SizedBox.shrink)
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(AdWidget), findsNothing);
    });

    testWidgets('renders SizedBox.shrink when ad not loaded (non-premium)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWithValue(false),
            adServiceProvider.overrideWithValue(AdService()),
          ],
          child: MaterialApp(
            home: Scaffold(body: AdBannerWidget(isPremiumProvider: isPremiumProvider)),
          ),
        ),
      );

      await tester.pump();

      // Ad not loaded yet (SDK not initialized) — should be shrink
      expect(find.byType(AdWidget), findsNothing);
    });

    testWidgets('disposes without error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWithValue(false),
            adServiceProvider.overrideWithValue(AdService()),
          ],
          child: MaterialApp(
            home: Scaffold(body: AdBannerWidget(isPremiumProvider: isPremiumProvider)),
          ),
        ),
      );

      // Navigate away to trigger dispose
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWithValue(false),
            adServiceProvider.overrideWithValue(AdService()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SizedBox()),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // No error thrown during dispose
    });
  });
}
