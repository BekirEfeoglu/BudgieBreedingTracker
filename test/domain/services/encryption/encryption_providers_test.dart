import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/encryption/encryption_service.dart';

void main() {
  test('encryptionServiceProvider returns cached service per container', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = container.read(encryptionServiceProvider);
    final second = container.read(encryptionServiceProvider);

    expect(first, isA<EncryptionService>());
    expect(identical(first, second), isTrue);
  });
}
