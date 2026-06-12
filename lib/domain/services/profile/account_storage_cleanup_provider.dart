import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/storage_service_provider.dart';

final accountStorageCleanupProvider = Provider<AccountStorageCleanup>((ref) {
  return AccountStorageCleanup(ref);
});

class AccountStorageCleanup {
  const AccountStorageCleanup(this._ref);

  final Ref _ref;

  Future<void> deleteAllUserFiles(String userId) {
    return _ref.read(storageServiceProvider).deleteAllUserFiles(userId);
  }
}
