import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/enums/photo_enums.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/photos_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/photo_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/photo_remote_source.dart';
import 'package:budgie_breeding_tracker/data/repositories/photo_repository.dart';

import '../../helpers/test_fixtures.dart';

class MockPhotosDao extends Mock implements PhotosDao {}

class MockPhotoRemoteSource extends Mock implements PhotoRemoteSource {}

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

Photo _samplePhoto({String id = 'photo-1', String userId = 'user-1'}) {
  return Photo(
    id: id,
    userId: userId,
    entityType: PhotoEntityType.bird,
    entityId: 'bird-1',
    fileName: 'photo.jpg',
  );
}

void main() {
  late MockPhotosDao localDao;
  late MockPhotoRemoteSource remoteSource;
  late MockSyncMetadataDao syncDao;
  late PhotoRepository repository;

  const userId = 'user-1';

  setUpAll(() {
    registerFallbackValue(DateTime(2024, 1, 1));
    registerFallbackValue(_samplePhoto());
    registerFallbackValue(TestFixtures.sampleSyncMetadata());
  });

  setUp(() {
    localDao = MockPhotosDao();
    remoteSource = MockPhotoRemoteSource();
    syncDao = MockSyncMetadataDao();

    repository = PhotoRepository(
      localDao: localDao,
      remoteSource: remoteSource,
      syncDao: syncDao,
    );

    when(() => localDao.insertItem(any())).thenAnswer((_) async {});
    when(() => localDao.insertAll(any())).thenAnswer((_) async {});
    when(() => localDao.getById(any())).thenAnswer((_) async => null);
    when(() => localDao.getAll(any())).thenAnswer((_) async => []);
    when(() => localDao.hardDelete(any())).thenAnswer((_) async {});
    when(() => localDao.deleteByEntity(any())).thenAnswer((_) async {});

    when(() => remoteSource.upsert(any())).thenAnswer((_) async {});
    when(() => remoteSource.deleteById(any(), userId: any(named: 'userId'))).thenAnswer((_) async {});
    when(() => remoteSource.fetchAll(any())).thenAnswer((_) async => []);
    when(
      () => remoteSource.fetchUpdatedSince(any(), any()),
    ).thenAnswer((_) async => []);

    when(() => syncDao.insertItem(any())).thenAnswer((_) async {});
    when(() => syncDao.insertAll(any())).thenAnswer((_) async {});
    when(() => syncDao.deleteByRecord(any(), any())).thenAnswer((_) async {});
    when(() => syncDao.updateItem(any())).thenAnswer((_) async {});
    when(() => syncDao.getByRecord(any(), any())).thenAnswer((_) async => null);
    when(
      () => syncDao.getPendingByTable(any(), any()),
    ).thenAnswer((_) async => []);
    when(() => syncDao.getPendingRecordIds(any())).thenAnswer((_) async => {});
  });

  group('PhotoRepository', () {
    test('save writes local creates pending metadata and pushes', () async {
      final photo = _samplePhoto(id: 'photo-1', userId: userId);

      await repository.save(photo);

      verify(() => localDao.insertItem(photo)).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.upsert(photo)).called(1);
    });

    test('remove hard deletes local and triggers remote delete', () async {
      final photo = _samplePhoto(id: 'photo-1', userId: userId);
      when(() => localDao.getById('photo-1')).thenAnswer((_) async => photo);

      await repository.remove('photo-1');

      verify(() => localDao.hardDelete('photo-1')).called(1);
      verify(() => syncDao.insertItem(any())).called(1);
      verify(() => remoteSource.deleteById('photo-1', userId: userId)).called(1);
    });

    test('pushAll cleans orphan metadata and pushes existing items', () async {
      final existing = _samplePhoto(id: 'photo-1', userId: userId);
      final pending = [
        TestFixtures.sampleSyncMetadata(
          id: 'meta-1',
          table: SupabaseConstants.photosTable,
          userId: userId,
          recordId: 'photo-1',
        ),
        TestFixtures.sampleSyncMetadata(
          id: 'meta-2',
          table: SupabaseConstants.photosTable,
          userId: userId,
          recordId: 'missing-photo',
        ),
      ];
      when(
        () => syncDao.getPendingByTable(userId, SupabaseConstants.photosTable),
      ).thenAnswer((_) async => pending);
      when(() => localDao.getById('photo-1')).thenAnswer((_) async => existing);
      when(
        () => localDao.getById('missing-photo'),
      ).thenAnswer((_) async => null);

      await repository.pushAll(userId);

      verify(() => remoteSource.upsert(existing)).called(1);
      verify(
        () => syncDao.deleteByRecord(
          SupabaseConstants.photosTable,
          'missing-photo',
        ),
      ).called(1);
    });
  });
}
