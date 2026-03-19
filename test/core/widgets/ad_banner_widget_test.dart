import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:budgie_breeding_tracker/core/widgets/ad_banner_widget.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';

/// A stub loader that returns a test ad unit ID without initializing the SDK.
Future<String> _testAdBannerLoader() async => 'ca-app-pub-test/test-banner';

void main() {
  group('AdBannerWidget', () {
    testWidgets('renders SizedBox.shrink when premium', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWithValue(true),
          ],
          child: MaterialApp(
            home: Scaffold(body: AdBannerWidget(
              isPremiumProvider: isPremiumProvider,
              adBannerLoader: _testAdBannerLoader,
            )),
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
          ],
          child: MaterialApp(
            home: Scaffold(body: AdBannerWidget(
              isPremiumProvider: isPremiumProvider,
              adBannerLoader: _testAdBannerLoader,
            )),
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
          ],
          child: MaterialApp(
            home: Scaffold(body: AdBannerWidget(
              isPremiumProvider: isPremiumProvider,
              adBannerLoader: _testAdBannerLoader,
            )),
          ),
        ),
      );

      // Navigate away to trigger dispose
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isPremiumProvider.overrideWithValue(false),
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
