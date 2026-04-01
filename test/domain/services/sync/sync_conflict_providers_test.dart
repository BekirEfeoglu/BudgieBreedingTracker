import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:budgie_breeding_tracker/data/local/database/dao_providers.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/conflict_history_dao.dart';
import 'package:budgie_breeding_tracker/data/models/conflict_history_model.dart';
import 'package:budgie_breeding_tracker/data/providers/auth_state_providers.dart';
import 'package:budgie_breeding_tracker/domain/services/sync/sync_conflict_providers.dart';
import 'package:budgie_breeding_tracker/core/enums/sync_enums.dart';

import '../../../helpers/test_helpers.dart';

class MockConflictHistoryDao extends Mock implements ConflictHistoryDao {}

SyncConflict _conflict({
  String table = 'birds',
  String recordId = 'r1',
  String description = 'server wins',
  DateTime? detectedAt,
}) {
  return SyncConflict(
    table: table,
    recordId: recordId,
    detectedAt: detectedAt ?? DateTime(2025, 1, 1),
    description: description,
  );
}

void main() {
  late MockConflictHistoryDao mockDao;

  setUpAll(() {
    registerFallbackValue(const Duration(hours: 1));
  });

  setUp(() {
    mockDao = MockConflictHistoryDao();
  });

  group('persistedConflictCountProvider', () {
    test('returns 0 for anonymous user', () async {
      final container = ProviderContainer(
        overrides: [conflictHistoryDaoProvider.overrideWithValue(mockDao)],
      );
      addTearDown(container.dispose);

      container.listen(persistedConflictCountProvider('anonymous'), (_, __) {});
      final value = await container.read(
        persistedConflictCountProvider('anonymous').future,
      );

      expect(value, 0);
      // DAO should never be called for anonymous
      verifyNever(() => mockDao.watchRecentCount(any(), any()));
    });

    test('delegates to DAO for real user', () async {
      when(
        () => mockDao.watchRecentCount(any(), any()),
      ).thenAnswer((_) => Stream.value(5));

      final container = ProviderContainer(
        overrides: [conflictHistoryDaoProvider.overrideWithValue(mockDao)],
      );
      addTearDown(container.dispose);

      container.listen(persistedConflictCountProvider('user-1'), (_, __) {});
      final value = await container.read(
        persistedConflictCountProvider('user-1').future,
      );

      expect(value, 5);
      verify(
        () => mockDao.watchRecentCount('user-1', const Duration(hours: 24)),
      ).called(1);
    });
  });

  group('ConflictHistoryNotifier', () {
    test('builds with empty list', () {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          conflictHistoryDaoProvider.overrideWithValue(mockDao),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(conflictHistoryProvider);

      expect(state, isEmpty);
    });

    test(
      'restores persisted conflicts from DAO for authenticated user',
      () async {
        when(() => mockDao.watchAll('user-1')).thenAnswer(
          (_) => Stream.value([
            ConflictHistory(
              id: 'c1',
              userId: 'user-1',
              tableName: 'birds',
              recordId: 'b1',
              description: 'server wins',
              conflictType: ConflictType.serverWins,
              createdAt: DateTime(2025, 1, 2),
            ),
            ConflictHistory(
              id: 'c2',
              userId: 'user-1',
              tableName: 'eggs',
              recordId: 'e1',
              description: 'client wins',
              conflictType: ConflictType.localOverwritten,
              createdAt: DateTime(2025, 1, 3),
            ),
          ]),
        );

        final container = ProviderContainer(
          overrides: [
            currentUserIdProvider.overrideWithValue('user-1'),
            conflictHistoryDaoProvider.overrideWithValue(mockDao),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(conflictHistoryProvider), isEmpty);

        await waitUntil(
          () => container.read(conflictHistoryProvider).length == 2,
          maxAttempts: 120,
          interval: const Duration(milliseconds: 5),
        );

        final state = container.read(conflictHistoryProvider);
        expect(state, hasLength(2));
        expect(state[0].table, 'birds');
        expect(state[0].recordId, 'b1');
        expect(state[0].description, 'server wins');
        expect(state[0].detectedAt, DateTime(2025, 1, 2));
        expect(state[1].table, 'eggs');
        expect(state[1].recordId, 'e1');
        verify(() => mockDao.watchAll('user-1')).called(1);
      },
    );

    test('does not restore from DAO for anonymous user', () async {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          conflictHistoryDaoProvider.overrideWithValue(mockDao),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(conflictHistoryProvider), isEmpty);
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockDao.watchAll(any()));
    });

    test('swallows DAO restore errors and keeps empty state', () async {
      when(() => mockDao.watchAll('user-1')).thenAnswer(
        (_) => Stream<List<ConflictHistory>>.error(StateError('db failed')),
      );

      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('user-1'),
          conflictHistoryDaoProvider.overrideWithValue(mockDao),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(conflictHistoryProvider), isEmpty);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(container.read(conflictHistoryProvider), isEmpty);
      verify(() => mockDao.watchAll('user-1')).called(1);
    });

    test('addConflict adds to front of list', () {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          conflictHistoryDaoProvider.overrideWithValue(mockDao),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(conflictHistoryProvider.notifier);
      final first = _conflict(recordId: 'r1');
      final second = _conflict(recordId: 'r2');

      notifier.addConflict(first);
      notifier.addConflict(second);

      final state = container.read(conflictHistoryProvider);

      expect(state.length, 2);
      expect(state[0].recordId, 'r2');
      expect(state[1].recordId, 'r1');
    });

    test('addConflict caps at 50 entries (FIFO)', () {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          conflictHistoryDaoProvider.overrideWithValue(mockDao),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(conflictHistoryProvider.notifier);

      // Add 55 conflicts
      for (var i = 0; i < 55; i++) {
        notifier.addConflict(_conflict(recordId: 'r$i'));
      }

      final state = container.read(conflictHistoryProvider);

      expect(state.length, 50);
      // The newest entry (r54) should be first
      expect(state.first.recordId, 'r54');
      // The oldest kept entry should be r5 (r0-r4 evicted)
      expect(state.last.recordId, 'r5');
    });

    test('clear empties the list', () {
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('anonymous'),
          conflictHistoryDaoProvider.overrideWithValue(mockDao),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(conflictHistoryProvider.notifier);
      notifier.addConflict(_conflict(recordId: 'r1'));
      notifier.addConflict(_conflict(recordId: 'r2'));

      expect(container.read(conflictHistoryProvider).length, 2);

      notifier.clear();

      expect(container.read(conflictHistoryProvider), isEmpty);
    });
  });
}
