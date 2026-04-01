import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/remote/storage/storage_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/storage/storage_service.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';

import '../../../helpers/mocks.dart';

void main() {
  test(
    'storageServiceProvider returns a StorageService for overridden client',
    () {
      final client = MockSupabaseClient();
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      final service = container.read(storageServiceProvider);

      expect(service, isA<StorageService>());
    },
  );
}
