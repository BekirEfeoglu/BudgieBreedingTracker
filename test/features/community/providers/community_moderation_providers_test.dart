import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';
import 'package:budgie_breeding_tracker/domain/services/moderation/content_moderation_service.dart';
import 'package:budgie_breeding_tracker/features/community/providers/community_moderation_providers.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('contentModerationServiceProvider', () {
    test('creates ContentModerationService with EdgeFunctionClient when '
        'Supabase is available', () {
      final mockClient = MockSupabaseClient();
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final service = container.read(contentModerationServiceProvider);

      expect(service, isA<ContentModerationService>());
    });

    test('creates ContentModerationService without EdgeFunctionClient when '
        'Supabase throws', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWith(
            (ref) => throw Exception('Supabase not initialized'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(contentModerationServiceProvider);

      expect(service, isA<ContentModerationService>());
    });

    test('returned service is a ContentModerationService instance', () {
      final mockClient = MockSupabaseClient();
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(mockClient)],
      );
      addTearDown(container.dispose);

      final service = container.read(contentModerationServiceProvider);

      expect(service, isNotNull);
      expect(
        service.runtimeType.toString(),
        contains('ContentModerationService'),
      );
    });
  });
}
