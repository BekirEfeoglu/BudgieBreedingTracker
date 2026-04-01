import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_comment_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_post_remote_source.dart';
import 'package:budgie_breeding_tracker/data/remote/api/community_profile_cache.dart';
import 'package:budgie_breeding_tracker/data/remote/api/remote_source_providers.dart';
import 'package:budgie_breeding_tracker/data/remote/supabase/supabase_client.dart';

import '../../../helpers/fake_supabase.dart';
import '../../../helpers/mocks.dart';

class _MockCommunityProfileCache extends Mock
    implements CommunityProfileCache {}

void main() {
  setUpAll(() {
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  group('remote source providers', () {
    test('base remote source providers use the overridden Supabase client', () {
      final client = MockSupabaseClient();
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      final birdSource = container.read(birdRemoteSourceProvider);
      final eggSource = container.read(eggRemoteSourceProvider);
      final profileSource = container.read(profileRemoteSourceProvider);

      expect(birdSource.client, same(client));
      expect(birdSource.tableName, SupabaseConstants.birdsTable);
      expect(eggSource.client, same(client));
      expect(eggSource.tableName, SupabaseConstants.eggsTable);
      expect(profileSource.client, same(client));
      expect(profileSource.tableName, SupabaseConstants.profilesTable);
    });

    test('communityProfileCacheProvider is memoized within a container', () {
      final client = MockSupabaseClient();
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      final first = container.read(communityProfileCacheProvider);
      final second = container.read(communityProfileCacheProvider);

      expect(first, same(second));
    });

    test(
      'communityPostRemoteSourceProvider uses overridden profile cache',
      () async {
        final client = RoutingFakeClient();
        final posts = client.addTable(SupabaseConstants.communityPostsTable);
        posts.selectBuilder.singleResult = {
          'id': 'post-1',
          'user_id': 'user-1',
          'content': 'hello',
          'title': 't',
          'post_type': 'text',
          'image_urls': <String>[],
          'tags': <String>[],
          'like_count': 0,
          'comment_count': 0,
          'view_count': 0,
          'is_pinned': false,
          'visibility': 'public',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
          'is_deleted': false,
        };
        final cache = _MockCommunityProfileCache();
        when(() => cache.mergeIntoRows(any())).thenAnswer((invocation) async {
          final rows =
              invocation.positionalArguments.single
                  as List<Map<String, dynamic>>;
          return rows
              .map((row) => {...row, 'username': 'cached-user'})
              .toList();
        });

        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(client),
            communityProfileCacheProvider.overrideWithValue(cache),
          ],
        );
        addTearDown(container.dispose);

        final source = container.read(communityPostRemoteSourceProvider);
        final result = await source.fetchById('post-1');

        expect(source, isA<CommunityPostRemoteSource>());
        expect(result?['username'], 'cached-user');
        verify(() => cache.mergeIntoRows(any())).called(1);
      },
    );

    test(
      'communityCommentRemoteSourceProvider uses overridden profile cache',
      () async {
        final client = RoutingFakeClient();
        final comments = client.addTable(
          SupabaseConstants.communityCommentsTable,
        );
        comments.selectBuilder.result = [
          {
            'id': 'comment-1',
            'post_id': 'post-1',
            'user_id': 'user-2',
            'content': 'hi',
            'created_at': '2026-01-01T00:00:00Z',
            'is_deleted': false,
          },
        ];
        final cache = _MockCommunityProfileCache();
        when(() => cache.mergeIntoRows(any())).thenAnswer((invocation) async {
          final rows =
              invocation.positionalArguments.single
                  as List<Map<String, dynamic>>;
          return rows
              .map((row) => {...row, 'username': 'comment-user'})
              .toList();
        });

        final container = ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(client),
            communityProfileCacheProvider.overrideWithValue(cache),
          ],
        );
        addTearDown(container.dispose);

        final source = container.read(communityCommentRemoteSourceProvider);
        final result = await source.fetchByPost('post-1');

        expect(source, isA<CommunityCommentRemoteSource>());
        expect(result.single['username'], 'comment-user');
        verify(() => cache.mergeIntoRows(any())).called(1);
      },
    );
  });
}
