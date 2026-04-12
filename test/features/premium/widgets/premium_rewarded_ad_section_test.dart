import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budgie_breeding_tracker/test_support/l10n_lookup.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/domain/services/ads/ad_reward_providers.dart';
import 'package:budgie_breeding_tracker/features/premium/widgets/premium_rewarded_ad_section.dart';

import '../../../helpers/test_localization.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildSubject({
    bool statsActive = false,
    bool geneticsActive = false,
    bool exportActive = false,
  }) {
    return ProviderScope(
      overrides: [
        isStatisticsRewardActiveProvider.overrideWith(
          () => _FakeBoolNotifier(statsActive),
        ),
        isGeneticsRewardActiveProvider.overrideWith(
          () => _FakeGeneticsNotifier(geneticsActive),
        ),
        isExportRewardActiveProvider.overrideWith(
          () => _FakeExportNotifier(exportActive),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(
          child: PremiumRewardedAdSection(),
        )),
      ),
    );
  }

  group('PremiumRewardedAdSection', () {
    testWidgets('renders section title and subtitle', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.text(l10n('ads.free_access_title')), findsOneWidget);
      expect(find.text(l10n('ads.free_access_subtitle')), findsOneWidget);
    });

    testWidgets('renders gift icon', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.byIcon(LucideIcons.gift), findsOneWidget);
    });

    testWidgets('shows ad buttons when all rewards inactive', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.text(l10n('ads.watch_for_statistics')), findsOneWidget);
      expect(find.text(l10n('ads.watch_for_genetics')), findsOneWidget);
      expect(find.text(l10n('ads.watch_for_export')), findsOneWidget);
    });

    testWidgets('shows status chip when statistics reward is active', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(statsActive: true),
      );

      expect(find.text(l10n('ads.reward_statistics_active')), findsOneWidget);
      expect(find.text(l10n('ads.watch_for_statistics')), findsNothing);
    });

    testWidgets('shows status chip when genetics reward is active', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(geneticsActive: true),
      );

      expect(find.text(l10n('ads.reward_genetics_remaining')), findsOneWidget);
      expect(find.text(l10n('ads.watch_for_genetics')), findsNothing);
    });

    testWidgets('shows status chip when export reward is active', (
      tester,
    ) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(exportActive: true),
      );

      expect(find.text(l10n('ads.reward_export_remaining')), findsOneWidget);
      expect(find.text(l10n('ads.watch_for_export')), findsNothing);
    });

    testWidgets('shows all chips when all rewards active', (tester) async {
      await pumpLocalizedApp(
        tester,
        buildSubject(
          statsActive: true,
          geneticsActive: true,
          exportActive: true,
        ),
      );

      expect(find.byType(RewardStatusChip), findsNWidgets(3));
    });

    testWidgets('shows subtitles for ad buttons', (tester) async {
      await pumpLocalizedApp(tester, buildSubject());

      expect(find.text(l10n('ads.reward_duration_24h')), findsOneWidget);
      // genetics and export share session duration
      expect(find.text(l10n('ads.reward_duration_session')), findsNWidgets(2));
    });
  });

  group('RewardStatusChip', () {
    testWidgets('renders label and check icon', (tester) async {
      await pumpLocalizedApp(
        tester,
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RewardStatusChip(label: 'Active!'),
            ),
          ),
        ),
      );

      expect(find.text('Active!'), findsOneWidget);
      expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    });

    testWidgets('chip renders inside a Row with text', (tester) async {
      await pumpLocalizedApp(
        tester,
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RewardStatusChip(label: 'Active'),
            ),
          ),
        ),
      );

      // Verify the chip renders within a Row containing the label
      expect(
        find.descendant(
          of: find.byType(RewardStatusChip),
          matching: find.byType(Row),
        ),
        findsOneWidget,
      );
    });
  });
}

class _FakeBoolNotifier extends StatisticsRewardNotifier {
  final bool _value;
  _FakeBoolNotifier(this._value);

  @override
  bool build() => _value;
}

class _FakeGeneticsNotifier extends GeneticsRewardNotifier {
  final bool _value;
  _FakeGeneticsNotifier(this._value);

  @override
  bool build() => _value;
}

class _FakeExportNotifier extends ExportRewardNotifier {
  final bool _value;
  _FakeExportNotifier(this._value);

  @override
  bool build() => _value;
}
