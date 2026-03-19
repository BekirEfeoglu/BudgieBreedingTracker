import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/nests_dao.dart';
import 'package:budgie_breeding_tracker/data/models/nest_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/nest_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/nest_repository.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_fixtures.dart';

class MockNestsDao extends Mock implements NestsDao {}

class MockNestRemoteSource extends Mock implements NestRemoteSource {}

Nest _sampleNest({String id = 'nest-1', String userId = 'user-1'}) {
  return Nest(id: id, userId: userId);
}

void main() {
  late MockNestsDao localDao;
  late MockNestRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late NestRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(_sampleNest());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockNestsDao();
    remoteSource = MockNestRemoteSource();
    syncDao = MockSyncMetadataDao();

    repository = NestRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
    );

    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.insertAll(any())).thenAnswer((_) async {});
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(() => localDao.getAll(any())).thenAnswer((_) async => []);
    when(() => localDao.softDelete(any())).thenAnswer((_) async {});
    when(() => localDao.hardDelete(any())).thenAnswer((_) async {});

    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});
    when(() => remoteSource.fetchAll(any())).thenAnswer((_) async => []);
    when(
      () => remoteSource.fetchUpdatedSince(any(), any()),
    ).thenAnswer((_) async => []);

    when(() => syncDao.insertItem(any())).thenAnswer((_) async {});
    when(() => syncDao.insertAll(any())).thenAnswer((_) async {});
    when(() => syncDao.deleteByRecord(any(), any())).thenAnswer((_) async {});
    when(
      () => syncDao.getPendingByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => syncDao.getPendingRecordIds(any())).thenAnswer((_) async => {});
    when(() => syncDao.getByRecord(any(), any())).thenAnswer((_) async => null);
    when(() => syncDao.updateItem(any())).thenAnswer((_) async {});
  });

  group('NestRepository', () {
    test('save writes local creates pending metadata and pushes', () async {
      final nest = _sampleNest(id: 'nest-1', userId: userId);

      await repository.save(nest);

      verify(() => localDao.insertItem(nest)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.upsert(nest)).called(1);
    });

    test('pull full sync fetches all and inserts local', () async {
      final remote = [_sampleNest(id: 'nest-remote')];
      when(() => remoteSource.fetchAll(userId)).thenAnswer((_) async => remote);

      await repository.pull(userId);

      verify(() => remoteSource.fetchAll(userId)).called(1);
      verify(() => localDao.insertAll(remote)).called(1);
    });

    test(
      'pushAll pushes all pending records with existing local items',
      () async {
        final nest = _sampleNest(id: 'nest-1', userId: userId);
        final pending = TestFixtures.sampleSyncMetadata(
          table: SupabaseConstants.nestsTable,
          userId: userId,
          recordId: nest.id,
        );
        when(
          () => syncDao.getPendingByTable(userId, SupabaseConstants.nestsTable),
        ).thenAnswer((_) async => [pending]);
        when(() => localDao.getById(nest.id)).thenAnswer((_) async => nest);

        await repository.pushAll(userId);

        verify(() => remoteSource.upsert(nest)).called(1);
      },
    );
  });
}
