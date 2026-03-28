import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/core/enums/subscription_enums.dart';
import 'package:budgie_breeding_tracker/features/home/widgets/grace_period_banner.dart';
import 'package:budgie_breeding_tracker/features/premium/providers/premium_providers.dart';
import 'package:budgie_breeding_tracker/features/profile/providers/profile_providers.dart';

import '../../../helpers/test_localization.dart';

Widget _createSubject({
  GracePeriodStatus gracePeriodStatus = GracePeriodStatus.gracePeriod,
}) {
  return ProviderScope(
    overrides: [
      premiumGracePeriodProvider.overrideWithValue(gracePeriodStatus),
      userProfileProvider.overrideWith((ref) => Stream.value(null)),
    ],
    child: const MaterialApp(
      home: Scaffold(body: GracePeriodBanner()),
    ),
  );
}

void main() {
  group('GracePeriodBanner', () {
    testWidgets('renders banner when status is gracePeriod', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(gracePeriodStatus: GracePeriodStatus.gracePeriod),
      );

      expect(find.text('premium.grace_period_title'), findsOneWidget);
    });

    testWidgets('renders nothing when status is active', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(gracePeriodStatus: GracePeriodStatus.active),
      );

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('premium.grace_period_title'), findsNothing);
    });

    testWidgets('renders nothing when status is free', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(gracePeriodStatus: GracePeriodStatus.free),
      );

      expect(find.text('premium.grace_period_title'), findsNothing);
    });

    testWidgets('renders nothing when status is expired', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(gracePeriodStatus: GracePeriodStatus.expired),
      );

      expect(find.text('premium.grace_period_title'), findsNothing);
    });

    testWidgets('shows renew button', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(gracePeriodStatus: GracePeriodStatus.gracePeriod),
      );

      expect(find.text('premium.grace_period_renew'), findsOneWidget);
    });

    testWidgets('shows grace period message', (tester) async {
      await pumpLocalizedApp(
        tester,
        _createSubject(gracePeriodStatus: GracePeriodStatus.gracePeriod),
      );

      // Message uses .tr(args:) — with TestAssetLoader it renders the raw key
      expect(find.text('premium.grace_period_message'), findsOneWidget);
    });
  });
}
