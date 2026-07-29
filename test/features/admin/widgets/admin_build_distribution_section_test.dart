import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/admin/providers/admin_build_distribution_provider.dart';
import 'package:budgie_breeding_tracker/features/admin/widgets/admin_build_distribution_section.dart';

import '../../../helpers/test_localization.dart';

const _distribution = BuildDistribution(
  windowDays: 30,
  platforms: [
    PlatformBuildDistribution(
      platform: 'ios',
      totalUsers: 6,
      versionedUsers: 5,
      coveragePercent: 83.3,
      builds: [
        BuildAdoptionEntry(
          appVersion: '1.1.9+61',
          userCount: 4,
          adoptionPercent: 66.7,
        ),
      ],
    ),
    PlatformBuildDistribution(
      platform: 'android',
      totalUsers: 3,
      versionedUsers: 0,
      coveragePercent: 0,
    ),
  ],
);

Widget _subject(Future<BuildDistribution> Function() loader) {
  return ProviderScope(
    overrides: [adminBuildDistributionProvider.overrideWith((_) => loader())],
    child: const AdminBuildDistributionSection(),
  );
}

void main() {
  group('AdminBuildDistributionSection', () {
    testWidgets('renders platform coverage and build adoption', (tester) async {
      await pumpTranslatedWidget(tester, _subject(() async => _distribution));

      expect(find.text('Build Benimsenme Dağılımı'), findsOneWidget);
      expect(find.text('iOS'), findsOneWidget);
      expect(find.text('Android'), findsOneWidget);
      expect(find.text('83.3%'), findsOneWidget);
      expect(find.text('1.1.9+61'), findsOneWidget);
      expect(find.text('4 kullanıcı · %66.7'), findsOneWidget);
      expect(
        find.text('Bu platform için henüz sürümlü oturum yok.'),
        findsOneWidget,
      );
    });

    testWidgets('shows an actionable error state', (tester) async {
      await pumpTranslatedWidget(
        tester,
        _subject(() async => throw StateError('rpc unavailable')),
      );

      expect(find.text('Build dağılımı yüklenemedi.'), findsOneWidget);
      expect(find.byTooltip('Tekrar Dene'), findsOneWidget);
    });

    for (final locale in const ['tr', 'en', 'de']) {
      testWidgets('does not overflow on narrow $locale layout', (tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await pumpTranslatedWidget(
          tester,
          _subject(() async => _distribution),
          locale: Locale(locale),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(AdminBuildDistributionSection), findsOneWidget);
      });
    }
  });
}
