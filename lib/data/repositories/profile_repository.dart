import 'package:budgie_breeding_tracker/core/constants/supabase_constants.dart';
import 'package:budgie_breeding_tracker/core/utils/logger.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/profiles_dao.dart';
import 'package:budgie_breeding_tracker/data/local/database/daos/sync_metadata_dao.dart';
import 'package:budgie_breeding_tracker/data/models/profile_model.dart';
import 'package:budgie_breeding_tracker/data/models/sync_metadata_model.dart';
import 'package:budgie_breeding_tracker/data/remote/api/profile_remote_source.dart';
import 'package:uuid/uuid.dart';

/// Repository for [Profile] entities.
///
/// Profile does not use [SyncableRepository] mixin because:
/// - Profile id = authenticated user's uid
/// - There is no soft-delete or multi-record sync pattern
/// - Push/pull are simple single-record operations
/// - Uses SyncMetadataDao for retry tracking on push failure.
class ProfileRepository {
  final ProfilesDao _localDao;
  final ProfileRemoteSource _remoteSource;
  final SyncMetadataDao _syncDao;

  static const _table = SupabaseConstants.profilesTable;

  ProfileRepository({
    required ProfilesDao localDao,
    required ProfileRemoteSource remoteSource,
    required SyncMetadataDao syncDao,
  }) : _localDao = localDao,
       _remoteSource = remoteSource,
       _syncDao = syncDao;

  /// Watches the current user's profile as a live stream.
  Stream<Profile?> watchProfile(String userId) =>
      _localDao.watchProfile(userId);

  /// Gets the current user's profile.
  Future<Profile?> getById(String userId) => _localDao.getById(userId);

  /// Saves a profile locally and marks it for sync.
  /// Push is handled by SyncOrchestrator to avoid duplicate pushes.
  Future<void> save(Profile profile) async {
    if (profile.id == 'anonymous') return;
    await _localDao.upsert(profile);
    await _markPending(profile.id);
  }

  /// Permanently deletes the local profile.
  Future<void> hardRemove(String id) => _localDao.hardDelete(id);

  /// Pulls the profile from Supabase and stores locally.
  ///
  /// If there are pending local changes, pushes them first to avoid
  /// overwriting unsent data (e.g. a name change that hasn't synced yet).
  Future<void> pull(String userId) async {
    try {
      // Check for pending local changes before pulling
      final pendingMeta = await _syncDao.getByRecord(_table, userId);
      if (pendingMeta != null) {
        final localProfile = await _localDao.getById(userId);
        if (localProfile != null) {
          try {
            await _remoteSource.upsert(localProfile);
            await _syncDao.deleteByRecord(_table, localProfile.id);
          } catch (e, st) {
            AppLogger.error(
              '[ProfileRepository] Push-before-pull failed',
              e,
              st,
            );
            // Push failed — keep local data intact, skip pull to avoid data loss
            return;
          }
        }
      }

      final remote = await _remoteSource.fetchById(userId, userId: userId);
      if (remote != null) {
        await _localDao.upsert(remote);
      }
    } catch (e, st) {
      AppLogger.error('[ProfileRepository] Pull failed', e, st);
    }
  }

  /// Pushes the local profile to Supabase.
  /// On success, clears sync metadata. On failure, marks error for retry.
  Future<void> push(Profile profile) async {
    try {
      await _remoteSource.upsert(profile);
      await _syncDao.deleteByRecord(_table, profile.id);
    } catch (e, st) {
      AppLogger.error('[ProfileRepository] Push failed', e, st);
      await _markError(profile.id, e.toString());
      rethrow;
    }
  }

  /// Pushes pending profile changes (called by SyncOrchestrator).
  Future<void> pushPending(String userId) async {
    final pending = await _syncDao.getPending(userId);
    final profilePending = pending.where((m) => m.table == _table).toList();
    for (final meta in profilePending) {
      final profile = await _localDao.getById(meta.recordId ?? '');
      if (profile != null) {
        try {
          await push(profile);
        } catch (_) {
          // Error already tracked by push()
        }
      }
    }
  }

  Future<void> _markPending(String recordId) async {
    final existing = await _syncDao.getByRecord(_table, recordId);
    if (existing != null) {
      await _syncDao.updateItem(
        existing.copyWith(status: SyncStatus.pending, errorMessage: null),
      );
    } else {
      await _syncDao.insertItem(
        SyncMetadata(
          id: const Uuid().v4(),
          table: _table,
          userId: recordId, // profile.id == userId
          status: SyncStatus.pending,
          recordId: recordId,
        ),
      );
    }
  }

  Future<void> _markError(String recordId, String message) async {
    final existing = await _syncDao.getByRecord(_table, recordId);
    if (existing != null) {
      await _syncDao.updateItem(
        existing.copyWith(
          status: SyncStatus.error,
          errorMessage: message,
          retryCount: (existing.retryCount ?? 0) + 1,
        ),
      );
    }
  }
}
