import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/sync/network_status_provider.dart';

void main() {
  test('debugOfflineModeProvider defaults to false', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(debugOfflineModeProvider), isFalse);
  });

  test('debugOfflineModeProvider state can be changed', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(debugOfflineModeProvider.notifier).state = true;
    expect(container.read(debugOfflineModeProvider), isTrue);
  });
}
