import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/logger.dart';
import 'route_names.dart';
import 'route_utils.dart';

abstract interface class PostAuthDestinationStore {
  Future<void> save(String? destination);

  Future<String?> take();

  Future<void> clear();
}

final postAuthDestinationStoreProvider = Provider<PostAuthDestinationStore>(
  (ref) => SharedPreferencesPostAuthDestinationStore(),
);

/// Persists the destination across a browser OAuth round trip or app restart.
class SharedPreferencesPostAuthDestinationStore
    implements PostAuthDestinationStore {
  SharedPreferencesPostAuthDestinationStore({
    Future<SharedPreferences> Function()? prefsFactory,
  }) : _prefsFactory = prefsFactory ?? SharedPreferences.getInstance;

  static const _key = 'auth.pending_post_auth_destination';
  final Future<SharedPreferences> Function() _prefsFactory;

  @override
  Future<void> save(String? destination) async {
    final safeDestination = validPostAuthDestination(destination);
    try {
      final prefs = await _prefsFactory();
      if (safeDestination == null || safeDestination == AppRoutes.home) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, safeDestination);
      }
    } catch (e) {
      AppLogger.warning(
        '[PostAuthDestinationStore] Could not persist destination: $e',
      );
    }
  }

  @override
  Future<String?> take() async {
    try {
      final prefs = await _prefsFactory();
      final destination = validPostAuthDestination(prefs.getString(_key));
      await prefs.remove(_key);
      return destination;
    } catch (e) {
      AppLogger.warning(
        '[PostAuthDestinationStore] Could not restore destination: $e',
      );
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await _prefsFactory();
      await prefs.remove(_key);
    } catch (e) {
      AppLogger.warning(
        '[PostAuthDestinationStore] Could not clear destination: $e',
      );
    }
  }
}
