import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_metadata_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_fixtures.dart';

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

void main() {
  late MockSyncMetadataDao localDao;
  late SyncMetadataRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
    registerFallbackValue(SyncStatus.pending);
  });

  setUp(() {
    localDao = MockSyncMetadataDao();
    repository = SyncMetadataRepository(localDao: localDao);

    when(
      () => localDao.watchAll(any()),
    ).thenAnswer((_) => const Stream.empty());
    when(() => localDao.getAll(any())).thenAnswer((_) async => []);
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(
      () => localDao.getByRecord(any(), any()),
    ).thenAnswer((_) async => null);
    when(() => localDao.getPending(any())).thenAnswer((_) async => []);
    when(() => localDao.getErrors(any())).thenAnswer((_) async => []);
    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.updateStatus(any(), any())).thenAnswer((_) async {});
    when(() => localDao.deleteByRecord(any(), any())).thenAnswer((_) async {});
    when(() => localDao.hardDelete(any())).thenAnswer((_) async {});
  });

  group('SyncMetadataRepository', () {
    test('delegates watch/get operations to local DAO', () async {
      final stream = Stream.value([TestFixtures.sampleSyncMetadata()]);
      final expected = [TestFixtures.sampleSyncMetadata(id: 'sync-1')];
      when(() => localDao.watchAll(userId)).thenAnswer((_) => stream);
      when(() => localDao.getAll(userId)).thenAnswer((_) async => expected);

      final watched = await repository.watchAll(userId).first;
      final listed = await repository.getAll(userId);

      expect(watched, hasLength(1));
      expect(listed, expected);
      verify(() => localDao.watchAll(userId)).called(1);
      verify(() => localDao.getAll(userId)).called(1);
    });

    test('save writes metadata via insertItem', () async {
      final metadata = TestFixtures.sampleSyncMetadata(id: 'sync-1');

      await repository.save(metadata);

      verify(() => localDao.insertItem(metadata)).called(1);
    });

    test('updateStatus forwards id and status', () async {
      await repository.updateStatus('sync-1', SyncStatus.error);

      verify(() => localDao.updateStatus('sync-1', SyncStatus.error)).called(1);
    });

    test('deleteByRecord and hardRemove delegate to DAO', () async {
      await repository.deleteByRecord('birds', 'bird-1');
      await repository.hardRemove('sync-1');

      verify(() => localDao.deleteByRecord('birds', 'bird-1')).called(1);
      verify(() => localDao.hardDelete('sync-1')).called(1);
    });

    test('getByRecord/getPending/getErrors return DAO results', () async {
      final metadata = TestFixtures.sampleSyncMetadata(
        table: 'birds',
        recordId: 'bird-1',
        userId: userId,
      );
      when(
        () => localDao.getByRecord('birds', 'bird-1'),
      ).thenAnswer((_) async => metadata);
      when(
        () => localDao.getPending(userId),
      ).thenAnswer((_) async => [metadata]);
      when(
        () => localDao.getErrors(userId),
      ).thenAnswer((_) async => [metadata]);

      expect(await repository.getByRecord('birds', 'bird-1'), metadata);
      expect(await repository.getPending(userId), [metadata]);
      expect(await repository.getErrors(userId), [metadata]);
    });
  });
}
