import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase migration chain guards', () {
    test(
      'system settings policy uses an admin helper that exists at that point',
      () {
        final sql = File(
          'supabase/migrations/'
          '20260430130000_consolidate_system_select_policies.sql',
        ).readAsStringSync();

        expect(sql, isNot(contains('private.is_admin()')));
        expect(sql, contains('SELECT public.is_admin()'));
      },
    );

    test('admin_get_table_counts keeps the RPC return contract stable', () {
      final sql = File(
        'supabase/migrations/20260403140000_security_audit_fixes.sql',
      ).readAsStringSync();
      final functionBlock = _functionBlock(sql, 'admin_get_table_counts');

      expect(functionBlock, contains('RETURNS TABLE('));
      expect(functionBlock, contains('table_name text'));
      expect(functionBlock, contains('row_count bigint'));
      expect(functionBlock, isNot(contains('RETURNS json')));
    });

    test('pgaudit extension is moved out of public API exposure', () {
      final sql = File(
        'supabase/migrations/20260501180000_move_pgaudit_out_of_public.sql',
      ).readAsStringSync();

      expect(sql, contains('ALTER EXTENSION pgaudit SET SCHEMA extensions'));
      expect(sql, contains('REVOKE ALL ON FUNCTION'));
      expect(sql, contains('FROM PUBLIC, anon, authenticated'));
    });

    test('community_blocks table is created with API grants and RLS', () {
      final sql = _allMigrationSql();

      expect(
        sql,
        contains('CREATE TABLE IF NOT EXISTS public.community_blocks'),
      );
      expect(sql, contains('community_blocks_no_self_block'));
      expect(sql, contains('community_blocks_unique_pair'));
      expect(
        sql,
        contains(
          'ALTER TABLE public.community_blocks ENABLE ROW LEVEL SECURITY',
        ),
      );
      expect(
        sql,
        contains(
          'ALTER TABLE public.community_blocks FORCE ROW LEVEL SECURITY',
        ),
      );
      expect(
        sql,
        contains(
          'REVOKE ALL ON TABLE public.community_blocks FROM PUBLIC, anon, authenticated',
        ),
      );
      expect(
        sql,
        contains(
          'GRANT SELECT, INSERT, DELETE ON TABLE public.community_blocks TO authenticated',
        ),
      );
      expect(sql, contains('idx_community_blocks_blocked_user'));
    });

    test(
      'cleanup function drift is repaired after original audit migration',
      () {
        final repairSql = _migrationSqlAfter(
          '20260413100000',
          requiredText:
              'CREATE OR REPLACE FUNCTION public.cleanup_expired_rate_limits()',
        );

        expect(
          repairSql,
          contains(
            'CREATE OR REPLACE FUNCTION public.cleanup_expired_backups()',
          ),
        );
        expect(
          repairSql,
          contains('GET DIAGNOSTICS deleted_count = ROW_COUNT'),
        );
        expect(repairSql, isNot(contains('RETURNING count(*) INTO')));
      },
    );

    test('edge function tests run before deployment in CI', () {
      final ci = File('.github/workflows/ci.yml').readAsStringSync();

      expect(ci, contains('edge-functions-test:'));
      expect(
        ci,
        contains('deno test --allow-env --allow-net supabase/functions'),
      );
      expect(ci, contains('needs: [analyze, test, edge-functions-test]'));
    });

    test('every Edge Function is configured, deployed, and tested', () {
      final ci = File('.github/workflows/ci.yml').readAsStringSync();
      final config = File('supabase/config.toml').readAsStringSync();
      final functionDirs =
          Directory('supabase/functions')
              .listSync()
              .whereType<Directory>()
              .where((dir) => !dir.uri.pathSegments.last.startsWith('_'))
              .where((dir) => File('${dir.path}/index.ts').existsSync())
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      expect(functionDirs, isNotEmpty);

      for (final dir in functionDirs) {
        final name = dir.uri.pathSegments[dir.uri.pathSegments.length - 2];
        expect(
          config,
          contains('[functions.$name]'),
          reason: '$name must declare verify_jwt explicitly',
        );
        expect(
          ci,
          contains('supabase functions deploy $name --project-ref'),
          reason: '$name must be deployed by the main CI pipeline',
        );

        final testFiles = dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('_test.ts'))
            .toList();
        expect(
          testFiles,
          isNotEmpty,
          reason: '$name must have Deno tests next to the function',
        );
      }
    });

    test('app-owned database lint warnings are repaired after grant fixes', () {
      final lintRepairSql = _migrationSqlAfter(
        '20260604190611',
        requiredText:
            'CREATE OR REPLACE FUNCTION private.admin_reset_all_user_data()',
      );

      expect(lintRepairSql, contains('reset_tables text[] := ARRAY[]::text[]'));
      expect(
        lintRepairSql,
        contains(
          'PERFORM p_is_premium, '
          'p_subscription_status, '
          'p_premium_expires_at, '
          'p_plan, '
          'p_current_period_end',
        ),
      );
      expect(
        lintRepairSql,
        contains('premium_sync_requires_server_verification'),
      );
    });

    test('admin reset RPCs are founder-only and admin logs are append-only', () {
      final hardeningSql = _migrationSqlAfter(
        '20260604190921',
        requiredText: 'CREATE OR REPLACE FUNCTION private.admin_reset_table',
      );

      expect(hardeningSql, contains("au.role = 'founder'"));
      expect(hardeningSql, contains('p.is_active = TRUE'));
      expect(
        hardeningSql,
        contains(
          'CREATE OR REPLACE FUNCTION private.admin_reset_all_user_data()',
        ),
      );
      expect(
        hardeningSql,
        contains('DROP POLICY IF EXISTS "admin_logs_update"'),
      );
      expect(
        hardeningSql,
        contains('DROP POLICY IF EXISTS "admin_logs_delete"'),
      );
      expect(
        hardeningSql,
        contains(
          'REVOKE UPDATE, DELETE ON TABLE public.admin_logs FROM authenticated',
        ),
      );
      expect(
        hardeningSql,
        isNot(contains('CREATE POLICY "admin_logs_update"')),
      );
      expect(
        hardeningSql,
        isNot(contains('CREATE POLICY "admin_logs_delete"')),
      );
    });

    test('avatar bucket accepts client-supported small image types only', () {
      final avatarBucketSql = _migrationSqlAfter(
        '20260604205501',
        requiredText: "UPDATE storage.buckets",
      );

      expect(avatarBucketSql, contains("id = 'avatars'"));
      expect(avatarBucketSql, contains('file_size_limit = 2097152'));
      expect(avatarBucketSql, contains("'image/heic'"));
    });

    test('community direct writes are forced through Edge Functions', () {
      final hardeningSql = _migrationSqlAfter(
        '20260606171613',
        requiredText: 'community_posts_insert_requires_edge_function',
      );

      expect(
        hardeningSql,
        contains('DROP POLICY IF EXISTS "Users can insert own posts"'),
      );
      expect(
        hardeningSql,
        contains('DROP POLICY IF EXISTS "Users can insert own comments"'),
      );
      expect(
        hardeningSql,
        contains('community_comments_insert_requires_edge_function'),
      );
      expect(hardeningSql, contains('WITH CHECK (false)'));
      expect(
        hardeningSql,
        contains('fetch_community_feed'),
        reason: 'feed must be server-filtered for reciprocal blocks',
      );
      expect(
        hardeningSql,
        contains('prevent_self_community_report'),
        reason: 'direct report inserts must reject self-reporting',
      );
    });
  });
}

String _allMigrationSql() =>
    _migrationFiles().map((file) => file.readAsStringSync()).join('\n');

String _migrationSqlAfter(String version, {required String requiredText}) {
  final matches = _migrationFiles()
      .where((file) => file.uri.pathSegments.last.compareTo(version) > 0)
      .map((file) => file.readAsStringSync())
      .where((sql) => sql.contains(requiredText))
      .toList();

  expect(matches, isNotEmpty);
  return matches.join('\n');
}

List<File> _migrationFiles() {
  return Directory('supabase/migrations')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.sql'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

String _functionBlock(String sql, String name) {
  final start = sql.indexOf('CREATE OR REPLACE FUNCTION public.$name()');
  expect(start, isNonNegative);

  final nextFunction = sql.indexOf('\nCREATE OR REPLACE FUNCTION ', start + 1);
  if (nextFunction == -1) {
    return sql.substring(start);
  }
  return sql.substring(start, nextFunction);
}
