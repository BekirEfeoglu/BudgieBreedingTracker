import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/profiles_dao.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/profile_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/profile_repository.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_fixtures.dart';

class MockProfilesDao extends Mock implements ProfilesDao {}

class MockProfileRemoteSource extends Mock implements ProfileRemoteSource {}

Profile _sampleProfile({String id = 'user-1', String email = 'a@b.com'}) {
  return Profile(id: id, email: email);
}

void main() {
  late MockProfilesDao localDao;
  late MockProfileRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late ProfileRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(_sampleProfile());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockProfilesDao();
    remoteSource = MockProfileRemoteSource();
    syncDao = MockSyncMetadataDao();

    repository = ProfileRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
    );

    when(() => localDao.upsert(any())).thenAnswer((_) async {});
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(() => localDao.hardDelete(any())).thenAnswer((_) async => 1);

    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});
    when(
      () => remoteSource.fetchById(any(), userId: any(named: 'userId')),
    ).thenAnswer((_) async => null);

    when(() => syncDao.insertItem(any())).thenAnswer((_) async {});
    when(() => syncDao.updateItem(any())).thenAnswer((_) async {});
    when(() => syncDao.deleteByRecord(any(), any())).thenAnswer((_) async {});
    when(() => syncDao.getByRecord(any(), any())).thenAnswer((_) async => null);
    when(() => syncDao.getPending(any())).thenAnswer((_) async => []);
  });

  group('ProfileRepository', () {
    test('save upserts local profile and marks pending metadata', () async {
      final profile = _sampleProfile(id: userId);

      await repository.save(profile);

      verify(() => localDao.upsert(profile)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
    });

    test('save ignores anonymous profile id', () async {
      final profile = _sampleProfile(id: 'anonymous');

      await repository.save(profile);

      verifyNever(() => localDao.upsert(any()));
      verifyNever(() => syncDao.insertItem(any()));
    });

    test('pushPending pushes pending profile records', () async {
      final profile = _sampleProfile(id: userId);
      final pending = TestFixtures.sampleSyncMetadata(
        table: SupabaseConstants.profilesTable,
        userId: userId,
        recordId: userId,
        status: SyncStatus.pending,
      );
      when(() => syncDao.getPending(userId)).thenAnswer((_) async => [pending]);
      when(() => localDao.getById(userId)).thenAnswer((_) async => profile);

      await repository.pushPending(userId);

      verify(() => remoteSource.upsert(profile)).called(1);
      verify(
        () => syncDao.deleteByRecord(SupabaseConstants.profilesTable, userId),
      ).called(1);
    });
  });
}
