import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart'
    as sync_model;
import 'package:budgie_breeding_tracker/data/repositories/bird_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/profile_repository.dart';
import 'package:budgie_breeding_tracker/data/repositories/repository_providers.dart';
import 'package:budgie_breeding_tracker/data/repositories/sync_metadata_repository.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/retry_scheduler.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_error_handler.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_push_handler.dart';
import 'package:budgie_breeding_tracker/data/repositories/base_repository.dart';

class MockSyncMetadataDao extends Mock implements SyncMetadataDao {}

// Local providers to obtain handlers with a proper Ref inside ProviderContainer
final _syncErrorHandlerProvider = Provider<SyncErrorHandler>((ref) {
  final pushHandler = SyncPushHandler(ref);
  return SyncErrorHandler(ref, pushHandler);
});

class MockSyncMetadataRepository extends Mock
    implements SyncMetadataRepository {}

class MockBirdRepository extends Mock implements BirdRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

const _userId = 'user-1';

sync_model.SyncMetadata _buildErrorRecord({
  required String id,
  required String table,
  required int retryCount,
  DateTime? updatedAt,
}) {
  return sync_model.SyncMetadata(
    id: id,
    table: table,
    userId: _userId,
    status: sync_model.SyncStatus.error,
    retryCount: retryCount,
    updatedAt: updatedAt ?? DateTime(2000),
    recordId: 'record-$id',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // deleteStaleErrors uses Duration parameter — fallback required for any()
    registerFallbackValue(Duration.zero);
  });

  late MockSyncMetadataDao mockSyncMetadataDao;
  late MockSyncMetadataRepository mockSyncMetadataRepository;
  late MockBirdRepository mockBirdRepository;
  late MockProfileRepository mockProfileRepository;

  late SyncErrorHandler handler;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockSyncMetadataDao = MockSyncMetadataDao();
    mockSyncMetadataRepository = MockSyncMetadataRepository();
    mockBirdRepository = MockBirdRepository();
    mockProfileRepository = MockProfileRepository();
  });

  SyncErrorHandler buildHandler() {
    final container = ProviderContainer(
      overrides: [
        syncMetadataDaoProvider.overrideWithValue(mockSyncMetadataDao),
        syncMetadataRepositoryProvider.overrideWithValue(
          mockSyncMetadataRepository,
        ),
        birdRepositoryProvider.overrideWithValue(mockBirdRepository),
        profileRepositoryProvider.overrideWithValue(mockProfileRepository),
      ],
    );
    // Read via provider so the handler receives a proper Riverpod Ref (not ProviderContainer)
    return container.read(_syncErrorHandlerProvider);
  }

  group('SyncErrorHandler.cleanupUnrecoverableErrors', () {
    test('calls deleteStaleErrors with correct parameters', () async {
      when(
        () => mockSyncMetadataDao.deleteStaleErrors(any(), any(), any()),
      ).thenAnswer((_) async => 0);

      handler = buildHandler();
      final count = await handler.cleanupUnrecoverableErrors(_userId);

      expect(count, 0);
      verify(
        () => mockSyncMetadataDao.deleteStaleErrors(
          _userId,
          const Duration(hours: 24),
          RetryScheduler.maxRetries,
        ),
      ).called(1);
    });

    test('returns number of cleaned up records', () async {
      when(
        () => mockSyncMetadataDao.deleteStaleErrors(any(), any(), any()),
      ).thenAnswer((_) async => 5);

      handler = buildHandler();
      final count = await handler.cleanupUnrecoverableErrors(_userId);

      expect(count, 5);
    });

    test('returns 0 when no records to cleanup', () async {
      when(
        () => mockSyncMetadataDao.deleteStaleErrors(any(), any(), any()),
      ).thenAnswer((_) async => 0);

      handler = buildHandler();
      final count = await handler.cleanupUnrecoverableErrors(_userId);

      expect(count, 0);
    });
  });

  group('SyncErrorHandler.retryFailedRecords', () {
    test('returns early when no error records', () async {
      when(
        () => mockSyncMetadataRepository.getErrors(_userId),
      ).thenAnswer((_) async => []);

      handler = buildHandler();
      await handler.retryFailedRecords(_userId);

      verifyNever(() => mockBirdRepository.pushAll(any()));
    });

    test('returns early when no retryable records', () async {
      // Records with maxRetries exceeded - not retryable
      final records = [
        _buildErrorRecord(
          id: '1',
          table: 'birds',
          retryCount: RetryScheduler.maxRetries + 1,
          updatedAt: DateTime(2000),
        ),
      ];
      when(
        () => mockSyncMetadataRepository.getErrors(_userId),
      ).thenAnswer((_) async => records);

      handler = buildHandler();
      await handler.retryFailedRecords(_userId);

      verifyNever(() => mockBirdRepository.pushAll(any()));
    });

    test('returns early when records exist but none ready for retry', () async {
      // Record not ready (updatedAt in the future = not elapsed)
      final records = [
        _buildErrorRecord(
          id: '1',
          table: 'birds',
          retryCount: 1,
          updatedAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      ];
      when(
        () => mockSyncMetadataRepository.getErrors(_userId),
      ).thenAnswer((_) async => records);

      handler = buildHandler();
      await handler.retryFailedRecords(_userId);

      verifyNever(() => mockBirdRepository.pushAll(any()));
    });

    test('calls pushTable for ready records', () async {
      final records = [
        _buildErrorRecord(
          id: '1',
          table: 'birds',
          retryCount: 1,
          updatedAt: DateTime(2000), // Old timestamp = elapsed
        ),
      ];
      when(
        () => mockSyncMetadataRepository.getErrors(_userId),
      ).thenAnswer((_) async => records);
      when(
        () => mockSyncMetadataDao.getPendingTableNames(any()),
      ).thenAnswer((_) async => {'birds'});
      when(
        () => mockBirdRepository.pushAll(any()),
      ).thenAnswer((_) async => emptyPushStats);

      handler = buildHandler();
      await handler.retryFailedRecords(_userId);

      verify(() => mockBirdRepository.pushAll(_userId)).called(1);
    });

    test('deduplicates tables - calls pushAll once per table', () async {
      final records = [
        _buildErrorRecord(
          id: '1',
          table: 'birds',
          retryCount: 0,
          updatedAt: DateTime(2000),
        ),
        _buildErrorRecord(
          id: '2',
          table: 'birds',
          retryCount: 1,
          updatedAt: DateTime(2000),
        ),
        _buildErrorRecord(
          id: '3',
          table: 'birds',
          retryCount: 2,
          updatedAt: DateTime(2000),
        ),
      ];
      when(
        () => mockSyncMetadataRepository.getErrors(_userId),
      ).thenAnswer((_) async => records);
      when(
        () => mockSyncMetadataDao.getPendingTableNames(any()),
      ).thenAnswer((_) async => {'birds'});
      when(
        () => mockBirdRepository.pushAll(any()),
      ).thenAnswer((_) async => emptyPushStats);

      handler = buildHandler();
      await handler.retryFailedRecords(_userId);

      // Birds pushed only once despite 3 error records for same table
      verify(() => mockBirdRepository.pushAll(_userId)).called(1);
    });
  });
}
