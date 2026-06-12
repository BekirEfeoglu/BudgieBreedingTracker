import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/content_moderation_service.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/image_safety_service.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/moderation_providers.dart';

void main() {
  setUpAll(() {
    // Prevent the supabaseClientProvider fallback recheck timer from firing
    // during tests (would leak across tests + interfere with provider
    // overrides).
    skipFallbackRecheck = true;
  });

  group('contentModerationServiceProvider', () {
    test('returns ContentModerationService when Supabase is unavailable', () {
      final container = ProviderContainer(
        overrides: [
          // Simulate guest/offline mode where Supabase isn't initialized.
          supabaseClientProvider.overrideWith(
            (ref) => throw StateError('Supabase not initialized'),
          ),
        ],
      );
      addTearDown(container.dispose);

      // The provider must swallow the Supabase init failure and still
      // return a usable client-side-only moderation service.
      final service = container.read(contentModerationServiceProvider);
      expect(service, isA<ContentModerationService>());
    });

    test('caches the service instance (same Provider semantics)', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWith(
            (ref) => throw StateError('Supabase not initialized'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final first = container.read(contentModerationServiceProvider);
      final second = container.read(contentModerationServiceProvider);
      expect(identical(first, second), isTrue);
    });
  });

  group('imageSafetyServiceProvider', () {
    test('returns ImageSafetyService when Supabase is unavailable', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWith(
            (ref) => throw StateError('Supabase not initialized'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(imageSafetyServiceProvider);
      expect(service, isA<ImageSafetyService>());
    });

    test('caches the service instance (same Provider semantics)', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWith(
            (ref) => throw StateError('Supabase not initialized'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final first = container.read(imageSafetyServiceProvider);
      final second = container.read(imageSafetyServiceProvider);
      expect(identical(first, second), isTrue);
    });
  });
}
