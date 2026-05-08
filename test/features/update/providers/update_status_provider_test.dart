import 'package:budgie_breeding_tracker/core/enums/update_status.dart';
import 'package:budgie_breeding_tracker/data/models/app_version_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/app_version_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/remote_source_providers.dart';
import 'package:budgie_breeding_tracker/features/update/providers/update_status_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSource extends Mock implements AppVersionRemoteSource {}

void main() {
  late _MockSource source;

  setUp(() {
    source = _MockSource();
  });

  ProviderContainer makeContainer({required int currentBuild}) {
    final container = ProviderContainer(
      overrides: [
        appVersionRemoteSourceProvider.overrideWithValue(source),
        currentBuildNumberProvider.overrideWith((_) async => currentBuild),
        currentPlatformProvider.overrideWithValue('ios'),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  const remoteVersion = AppVersion(
    platform: 'ios',
    latestVersion: '1.0.4',
    latestBuild: 18,
    minSupportedBuild: 10,
    storeUrl: 'https://example.com',
  );

  test('returns none when current >= latest', () async {
    when(
      () => source.fetchForPlatform('ios'),
    ).thenAnswer((_) async => remoteVersion);

    final c = makeContainer(currentBuild: 18);
    final result = await c.read(updateStatusProvider.future);
    expect(result, UpdateStatus.none);
  });

  test('returns optional when below latest', () async {
    when(
      () => source.fetchForPlatform('ios'),
    ).thenAnswer((_) async => remoteVersion);

    final c = makeContainer(currentBuild: 15);
    expect(
      await c.read(updateStatusProvider.future),
      UpdateStatus.optional,
    );
  });

  test('returns forced when below min_supported', () async {
    when(
      () => source.fetchForPlatform('ios'),
    ).thenAnswer((_) async => remoteVersion);

    final c = makeContainer(currentBuild: 5);
    expect(
      await c.read(updateStatusProvider.future),
      UpdateStatus.forced,
    );
  });

  test('returns none when remote returns null (fail-open)', () async {
    when(() => source.fetchForPlatform('ios')).thenAnswer((_) async => null);

    final c = makeContainer(currentBuild: 1);
    expect(await c.read(updateStatusProvider.future), UpdateStatus.none);
  });
}
