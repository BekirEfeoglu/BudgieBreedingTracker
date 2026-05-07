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
      'community-photos',
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
      contains('(storage.foldername(name))[1] = auth.uid()::text'),
      reason: 'private buckets must scope object paths to the owner user id',
    );
  });
}
