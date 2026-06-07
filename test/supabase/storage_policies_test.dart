import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('private storage buckets and owner policies are migration-managed', () {
    final migrations = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.sql'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    for (final bucket in const [
      'bird-photos',
      'egg-photos',
      'chick-photos',
      'backups',
    ]) {
      expect(
        migrations,
        contains("'$bucket'"),
        reason: '$bucket bucket must be declared in migrations',
      );
      expect(
        migrations,
        contains("bucket_id = '$bucket'"),
        reason: '$bucket policies must be declared in migrations',
      );
    }

    expect(
      migrations,
      contains("'community-photos'"),
      reason: 'community-photos bucket must be declared in migrations',
    );
    final hardeningSql = File(
      'supabase/migrations/20260607120000_harden_community_edge_writes.sql',
    ).readAsStringSync();
    expect(
      hardeningSql,
      contains('community_photo_client_insert_disabled'),
      reason: 'community photo client inserts must go through Edge Function',
    );
    expect(
      hardeningSql,
      isNot(
        contains(
          "FOR INSERT\nTO authenticated\nWITH CHECK (\n  bucket_id IN "
          "('bird-photos', 'egg-photos', 'chick-photos', "
          "'community-photos', 'backups')",
        ),
      ),
      reason: 'community-photos must not be in authenticated insert policy',
    );

    expect(
      migrations,
      contains('(storage.foldername(name))[1] = auth.uid()::text'),
      reason: 'private buckets must scope object paths to the owner user id',
    );
  });
}
