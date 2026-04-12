import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/features/settings/providers/export_providers.dart';

void main() {
  group('ExportLoadingNotifier', () {
    test('initial state is false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(exportLoadingProvider), isFalse);
    });

    test('state can be set to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(exportLoadingProvider.notifier).state = true;
      expect(container.read(exportLoadingProvider), isTrue);
    });

    test('state can be toggled back to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(exportLoadingProvider.notifier).state = true;
      container.read(exportLoadingProvider.notifier).state = false;
      expect(container.read(exportLoadingProvider), isFalse);
    });
  });

  group('LastExportDateNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(lastExportDateProvider), isNull);
    });

    test('state can be set to a DateTime', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final now = DateTime(2024, 6, 15);
      container.read(lastExportDateProvider.notifier).state = now;
      expect(container.read(lastExportDateProvider), now);
    });

    test('state can be cleared back to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(lastExportDateProvider.notifier).state = DateTime.now();
      container.read(lastExportDateProvider.notifier).state = null;
      expect(container.read(lastExportDateProvider), isNull);
    });
  });
}
